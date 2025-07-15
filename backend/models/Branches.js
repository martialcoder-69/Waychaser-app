const sequelize = require("../config/Database");
const DataTypes = require('sequelize');

const branch = sequelize.define('branch',{
    Ou_Type: {
      type: DataTypes.STRING(10),
      allowNull: true,
    },
    Branch_Code: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      allowNull: false,
    },
    Bo_Type: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },
    Branch_Name: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    Branch_Open_Date: {
      type: DataTypes.DATEONLY,
      allowNull: true,
    },
    Address: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    City: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    Pincode: {
      type: DataTypes.STRING(10),
      allowNull: true,
    },
    Underbank: {
      type: DataTypes.TINYINT,
      allowNull: true,
    },
    Location: {
      type: DataTypes.STRING(50),
      allowNull: true,
    },
    Inactive: {
      type: DataTypes.CHAR(1),
      allowNull: true,
    },
    Ifsc_Code: {
      type: DataTypes.STRING(20),
      allowNull: true,
    },
    District_Name: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    Sub_District: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    State_Name: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    Zone_Name: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    Country: {
      type: DataTypes.STRING(10),
      allowNull: true,
    },
    Linked_Branch: {
      type: DataTypes.STRING(20),
      allowNull: true,
    },
    Linked_Branch_Code: {
      type: DataTypes.STRING(20),
      allowNull: true,
    },
    Linked_Branch_Name: {
      type: DataTypes.STRING(100),
      allowNull: true,
    },
    Tier: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    Latitude: {
      type: DataTypes.DOUBLE,
      allowNull: true,
    },
    Longitude: {
      type: DataTypes.DOUBLE,
      allowNull: true,
    },
    Open_5KM: {
      type: DataTypes.TINYINT,
      allowNull: true,
    },
  }, {
    tableName: 'branches',
    timestamps: false,
});

module.exports = branch;