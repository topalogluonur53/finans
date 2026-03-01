const axios = require('axios');
const { redisContainer } = require('../config/redis');
const MarketData = require('../models/MarketData');

let yahooFinance;

class PriceService {
    constructor() {
        // We will initialize yahooFinance inside the methods
    }

    /**
     * Fetches prices for different asset types
     */
    async updateAllPrices() {
        console.log('--- Starting Price Update Cycle ---');
        try {
            const allMarketItems = await MarketData.findAll();

            // Separate symbols by type/source
            const yahooSymbols = [];
            const cryptoSymbols = [];

            allMarketItems.forEach(item => {
                if (item.symbol.includes('BTC') || item.symbol.includes('ETH') || item.symbol.includes('USDT')) {
                    cryptoSymbols.push(item.symbol);
                } else if (!item.symbol.startsWith('GRAM-') && !item.symbol.startsWith('CEYREK-')) {
                    // Regular symbols for Yahoo (excluding our calculated derivatives)
                    yahooSymbols.push(item.symbol);
                }
            });

            // 1. Fetch from Yahoo Finance (Stocks, FX, Commodities)
            if (yahooSymbols.length > 0) {
                await this.fetchYahooData(yahooSymbols);
            }

            // 2. Fetch from Binance (Crypto) - High Frequency
            if (cryptoSymbols.length > 0) {
                await this.fetchCryptoData(cryptoSymbols);
            }

            // 3. Calculate Gold/Silver Derivatives (Gram, Ceyrek etc.)
            await this.calculateDerivatives();

            console.log('--- Price Update Cycle Completed ---');
        } catch (error) {
            console.error('Price Update Cycle Error:', error.message);
        }
    }

    async fetchYahooData(symbols) {
        try {
            if (!yahooFinance) {
                const yfModule = await import('yahoo-finance2');
                yahooFinance = yfModule.default || yfModule;
                // Some environments put the real export inside another default
                if (!yahooFinance.quote && yahooFinance.default) {
                    yahooFinance = yahooFinance.default;
                }
            }
            // Yahoo handles batching well
            const results = await yahooFinance.quote(symbols);

            for (const quote of results) {
                const data = {
                    symbol: quote.symbol,
                    price: quote.regularMarketPrice,
                    change: quote.regularMarketChange,
                    percent: quote.regularMarketChangePercent,
                    open: quote.regularMarketOpen,
                    high: quote.regularMarketDayHigh,
                    low: quote.regularMarketDayLow,
                    volume: quote.regularMarketVolume
                };

                await this.processUpdate(data);
            }
        } catch (error) {
            console.error('Yahoo Finance Fetch Error:', error.message);
        }
    }

    async fetchCryptoData(symbols) {
        try {
            // Binance public ticker API
            const response = await axios.get('https://api.binance.com/api/v3/ticker/24hr');
            const tickers = response.data;

            for (const symbol of symbols) {
                // Binance symbols are usually like BTCUSDT
                const normalized = symbol.replace('-', '').replace('/', '');
                const ticker = tickers.find(t => t.symbol === normalized);

                if (ticker) {
                    const data = {
                        symbol: symbol,
                        price: parseFloat(ticker.lastPrice),
                        change: parseFloat(ticker.priceChange),
                        percent: parseFloat(ticker.priceChangePercent),
                        open: parseFloat(ticker.openPrice),
                        high: parseFloat(ticker.highPrice),
                        low: parseFloat(ticker.lowPrice),
                        volume: parseInt(ticker.volume)
                    };
                    await this.processUpdate(data);
                }
            }
        } catch (error) {
            console.error('Crypto Fetch Error:', error.message);
        }
    }

    async calculateDerivatives() {
        try {
            const usdTry = await this.getPriceFromCacheOrDB('USDTRY=X');
            const goldOns = await this.getPriceFromCacheOrDB('GC=F');

            if (!usdTry || !goldOns) return;

            const ONS_TO_GRAM = 31.1035;
            const goldGramPrice = (goldOns.price / ONS_TO_GRAM) * usdTry.price;

            const derivatives = [
                { symbol: 'GRAM-ALTIN', name: 'Gram Altın', price: goldGramPrice },
                { symbol: 'CEYREK-ALTIN', name: 'Çeyrek Altın', price: goldGramPrice * 1.75 * 0.916 },
                { symbol: 'YARIM-ALTIN', name: 'Yarım Altın', price: goldGramPrice * 3.50 * 0.916 },
                { symbol: 'TAM-ALTIN', name: 'Tam Altın', price: goldGramPrice * 7.02 * 0.916 }
            ];

            for (const d of derivatives) {
                await this.processUpdate({
                    symbol: d.symbol,
                    price: d.price,
                    change: 0, // Simplified
                    percent: goldOns.percent
                });
            }
        } catch (error) {
            console.error('Derivatives Calculation Error:', error.message);
        }
    }

    async processUpdate(data) {
        // 1. Update Redis (Instant Access)
        await redisContainer.client.set(`price:${data.symbol}`, JSON.stringify(data));

        // 2. Update DB (Persistence)
        await MarketData.update(
            {
                price: data.price,
                price_change_24h: data.change,
                change_percent_24h: data.percent,
                open_price: data.open,
                day_high: data.high,
                day_low: data.low,
                volume: data.volume
            },
            { where: { symbol: data.symbol } }
        );

        // 3. Socket.io Emit (Real-time Push)
        if (global.io) {
            global.io.to(`price_${data.symbol}`).emit('price_update', data);
        }

        // 4. Check Alarms
        this.checkAlarms(data.symbol, data.price);
    }

    async checkAlarms(symbol, currentPrice) {
        const Alarm = require('../models/Alarm');
        const alarms = await Alarm.findAll({
            where: { symbol, is_active: true }
        });

        for (const alarm of alarms) {
            let triggered = false;
            const target = parseFloat(alarm.target_price);
            const current = parseFloat(currentPrice);

            if (alarm.condition === '>' && current >= target) triggered = true;
            if (alarm.condition === '<' && current <= target) triggered = true;

            if (triggered) {
                alarm.is_active = false;
                alarm.triggered_at = new Date();
                await alarm.save();

                if (global.io) {
                    global.io.emit(`alarm_triggered_${alarm.userId}`, {
                        symbol, price: current, target, condition: alarm.condition
                    });
                }
            }
        }
    }

    async getPriceFromCacheOrDB(symbol) {
        const cached = await redisContainer.client.get(`price:${symbol}`);
        if (cached) return JSON.parse(cached);
        return await MarketData.findOne({ where: { symbol } });
    }

    async getPrice(symbol) {
        return await this.getPriceFromCacheOrDB(symbol);
    }
}

module.exports = new PriceService();
