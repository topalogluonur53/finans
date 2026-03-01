const MarketData = require('../models/MarketData');
const PriceService = require('../services/PriceService');

class MarketController {
    async getAll(req, res) {
        try {
            const data = await MarketData.findAll();
            res.json(data);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    }

    async getBySymbol(req, res) {
        try {
            const { symbol } = req.params;
            const data = await PriceService.getPrice(symbol);
            if (!data) return res.status(404).json({ error: 'Veri bulunamadı.' });
            res.json(data);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    }
}

module.exports = new MarketController();
