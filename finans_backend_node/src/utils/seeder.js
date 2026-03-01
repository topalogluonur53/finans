const MarketData = require('../models/MarketData');

const seedMarketData = async () => {
    const symbols = [
        // Currencies
        { symbol: 'USDTRY=X', name: 'Dolar/TL', market_type: 'currency' },
        { symbol: 'EURTRY=X', name: 'Euro/TL', market_type: 'currency' },
        { symbol: 'GBPTRY=X', name: 'Sterlin/TL', market_type: 'currency' },

        // Commodities
        { symbol: 'GC=F', name: 'Altın (Ons)', market_type: 'commodity' },
        { symbol: 'SI=F', name: 'Gümüş (Ons)', market_type: 'commodity' },

        // Indices
        { symbol: 'XU100.IS', name: 'BIST 100', market_type: 'stock', is_index: true },
        { symbol: '^GSPC', name: 'S&P 500', market_type: 'stock', is_index: true },

        // Crypto
        { symbol: 'BTC-USDT', name: 'Bitcoin', market_type: 'commodity' }, // mapped to Binance
        { symbol: 'ETH-USDT', name: 'Ethereum', market_type: 'commodity' },

        // Derivatives (Calculated)
        { symbol: 'GRAM-ALTIN', name: 'Gram Altın', market_type: 'commodity' },
        { symbol: 'CEYREK-ALTIN', name: 'Çeyrek Altın', market_type: 'commodity' }
    ];

    for (const item of symbols) {
        await MarketData.findOrCreate({
            where: { symbol: item.symbol },
            defaults: { ...item, price: 0 }
        });
    }
    console.log('Market data seeded successfully.');
};

module.exports = seedMarketData;
