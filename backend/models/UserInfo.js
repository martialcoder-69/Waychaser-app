const { DataTypes } = require('sequelize');
const sequelize = require('../config/Database');

const Info = sequelize.define('waychaser', {
  userID: {
    type: DataTypes.STRING(100),
    allowNull: false,
    primaryKey: true,
    field: "userID"
  },
  latitude: {
    type: DataTypes.DOUBLE,
    allowNull: true,
    field: "latitude"
  },
  longitude: {
    type: DataTypes.DOUBLE,
    allowNull: true,
    field: "longitude"
  },
  altitude: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: "altitude"
  },
  accuracy: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: "accuracy"
  },
  altitudeAccuracy: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: "altitudeAccuracy"
  },
  speed: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: "speed"
  },
  speedaccuracy: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: "speedaccuracy"
  },
  heading: {
    type: DataTypes.FLOAT,
    allowNull: true,
    field: "heading"
  },
  ismocked: {
    type: DataTypes.BOOLEAN,
    allowNull: true,
    field: "ismocked"
  },
  timestamp: {
    type: DataTypes.DATE(3),
    allowNull: false,
    primaryKey: true,
    field: "timestamp"
  },
  model: {
    type: DataTypes.STRING(100),
    allowNull: true,
    field: "model"
  },
  os: {
    type: DataTypes.STRING(50),
    allowNull: true,
    field: "os"
  },
  osVersion: {
    type: DataTypes.STRING(20),
    allowNull: true,
    field: "osVersion"
  },
  serial: {
    type: DataTypes.STRING(100),
    allowNull: false,
    primaryKey: true,
    field: "serial"
  },
  ipAddress: {
    type: DataTypes.STRING(45),
    allowNull: true,
    field: "ipAddress"
  },
  batteryLevel: {
    type: DataTypes.TINYINT,
    allowNull: true,
    field: "batteryLevel"
  },
  batteryState: {
    type: DataTypes.STRING(50),
    allowNull: true,
    field: "batteryState"
  },
  batterySaver: {
    type: DataTypes.BOOLEAN,
    allowNull: true,
    field: "batterySaver"
  },
  network: {
    type: DataTypes.STRING(100),
    allowNull: true,
    field: "network"
  },
  simCountryIso: {
    type: DataTypes.STRING(10),
    allowNull: true,
    field: "simCountryIso"
  },
  simCountryPhonePrefix: {
    type: DataTypes.STRING(10),
    allowNull: true,
    field: "simCountryPhonePrefix"
  },
  simDisplayName: {
    type: DataTypes.STRING(100),
    allowNull: true,
    field: "simDisplayName"
  },
  simNumber: {
    type: DataTypes.STRING(30),
    allowNull: true,
    field: "simNumber"
  },
  simSlotIndex: {
    type: DataTypes.INTEGER,
    allowNull: true,
    field: "simSlotIndex"
  },
  wifiIP: {
    type: DataTypes.STRING(45),
    allowNull: true,
    field: "wifiIP"
  },
  wifiName: {
    type: DataTypes.STRING(100),
    allowNull: true,
    field: "wifiName"
  },
  wifiBSSID: {
    type: DataTypes.STRING(50),
    allowNull: true,
    field: "wifiBSSID"
  },
  wifiSubmask: {
    type: DataTypes.STRING(45),
    allowNull: true,
    field: "wifiSubmask"
  },
  wifiGatewayIP: {
    type: DataTypes.STRING(45),
    allowNull: true,
    field: "wifiGatewayIP"
  },
  wifiBroadcast: {
    type: DataTypes.STRING(45),
    allowNull: true,
    field: "wifiBroadcast"
  },
  wifiIPv6: {
    type: DataTypes.STRING(100),
    allowNull: true,
    field: "wifiIPv6"
  }
}, {
  tableName: 'waychaser',
  timestamps: false,
  underscored: true
});


module.exports = Info;
