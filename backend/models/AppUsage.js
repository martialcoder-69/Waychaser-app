const sequelize = require("../config/Database");
const DataTypes = require("sequelize");

const AppUsage = sequelize.define("AppUsage",{
    userID:{
        type:DataTypes.STRING,
        primaryKey:true,
        allowNull:false,
        field:"userID"
    },
    model:{
        type:DataTypes.STRING,
        allowNull:true,
        field:"model"
    },
    serial:{
        type:DataTypes.STRING,
        primaryKey:true,
        allowNull:false,
        field:"serial",
    },
    timestamp:{
        type:DataTypes.DATE,
        primaryKey:true,
        allowNull:false,
        field:'timestamp'
    },
    apps:{
        type:DataTypes.JSON,
        allowNull:false,
        field:'apps'
    }

},{
    tableName:"AppUsage",
    timestamps:false
});

module.exports = AppUsage;
