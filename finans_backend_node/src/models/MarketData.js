import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const MarketData = sequelize.define('MarketData', {
  symbol: {
    type: DataTypes.STRING(50),
    allowNull: false,
    unique: true
  },
  name: {
    type: DataTypes.STRING(100)
  },
  price: {
    type: DataTypes.DECIMAL(20, 4),
    allowNull: false
  },
  price_change_24h: {
    type: DataTypes.DECIMAL(20, 4)
  },
  change_percent_24h: {
    type: DataTypes.DECIMAL(10, 2)
  },
  market_type: {
    type: DataTypes.ENUM('commodity', 'stock', 'currency'),
    allowNull: false
  },
  open_price: {
    type: DataTypes.DECIMAL(20, 4)
  },
  day_high: {
    type: DataTypes.DECIMAL(20, 4)
  },
  day_low: {
    type: DataTypes.DECIMAL(20, 4)
  },
  volume: {
    type: DataTypes.BIGINT
  },
  is_index: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  },
  parent_symbol: {
    type: DataTypes.STRING(50)
  }
});

export default MarketData;
