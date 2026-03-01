const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const User = require('./User');

const Asset = sequelize.define('Asset', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    type: {
        type: DataTypes.STRING(20),
        allowNull: false
    },
    name: {
        type: DataTypes.STRING(100),
        allowNull: false
    },
    symbol: {
        type: DataTypes.STRING(20)
    },
    quantity: {
        type: DataTypes.DECIMAL(20, 8),
        allowNull: false
    },
    purchase_price: {
        type: DataTypes.DECIMAL(20, 2),
        allowNull: false
    },
    purchase_date: {
        type: DataTypes.DATE,
        allowNull: false
    },
    notes: {
        type: DataTypes.TEXT
    }
});

const Transaction = sequelize.define('Transaction', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true
    },
    type: {
        type: DataTypes.ENUM('BUY', 'SELL'),
        allowNull: false
    },
    quantity: {
        type: DataTypes.DECIMAL(20, 8),
        allowNull: false
    },
    price: {
        type: DataTypes.DECIMAL(20, 2),
        allowNull: false
    },
    date: {
        type: DataTypes.DATE,
        allowNull: false
    }
});

User.hasMany(Asset, { foreignKey: 'userId', as: 'assets' });
Asset.belongsTo(User, { foreignKey: 'userId' });

Asset.hasMany(Transaction, { foreignKey: 'assetId', as: 'transactions' });
Transaction.belongsTo(Asset, { foreignKey: 'assetId' });

module.exports = { Asset, Transaction };
