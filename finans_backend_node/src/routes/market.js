const express = require('express');
const router = express.Router();
const MarketController = require('../controllers/MarketController');

router.get('/', MarketController.getAll);
router.get('/:symbol', MarketController.getBySymbol);

module.exports = router;
