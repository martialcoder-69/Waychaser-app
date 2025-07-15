const {DataTypes} = require('sequelize');

const sequelize = require("../config/Database")

const User = sequelize.define('Login',{
    userID:{
        type:DataTypes.STRING,
        primaryKey:true,
        allowNull:false
    },
    password:{
        type:DataTypes.STRING,
        allowNull:false
    },
    ManagedBy:{
        type:DataTypes.STRING,
        allowNull:true,
    }
},{
    tableName:'login',
    timestamps:false
}
);

module.exports = User;