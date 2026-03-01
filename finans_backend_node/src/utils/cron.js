const cron = require('node-cron');
const PriceService = require('../services/PriceService');

const initCrons = () => {
    // Run price update every 1 minute
    // This covers US stocks, FX, and Gold with minimal delay
    // Crypto is also updated in the same cycle for consistency
    cron.schedule('* * * * *', async () => {
        console.log(`[${new Date().toISOString()}] Price update job started...`);
        await PriceService.updateAllPrices();
    });

    // Run first update immediately on start
    PriceService.updateAllPrices();
};

module.exports = initCrons;
