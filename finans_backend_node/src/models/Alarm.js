import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';
import User from './User.js';

const Alarm = sequelize.define('Alarm', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  symbol: {
    type: DataTypes.STRING(50),
    allowNull: false
  },
  target_price: {
    type: DataTypes.DECIMAL(20, 4),
    allowNull: false
  },
  condition: {
    type: DataTypes.ENUM('>', '<'),
    allowNull: false
  },
  is_active: {
    type: DataTypes.BOOLEAN,
    defaultValue: true
  },
  triggered_at: {
    type: DataTypes.DATE
  },
  userId: {
    type: DataTypes.UUID
  }
});

User.hasMany(Alarm, { foreignKey: 'userId', as: 'alarms' });
Alarm.belongsTo(User, { foreignKey: 'userId' });

export default Alarm;
