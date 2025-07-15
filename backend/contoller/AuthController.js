const db = require("../config/Database")

//const admin = require("./Firebase")

const User = require("../models/User");

async function login(req,res) {
    const{userID,password} = req.body

    try{
        const user = await User.findOne({
            where:{userID:userID,
                password:password,
            },
        });

        if(!user){
            return res.status(401).json({message:'Invalid Credentials'});
        }

        //const customToken = await admin.auth().createCustomToken(userID);

        res.json({message:"logged in"});
    }catch(error){
         console.error('Login error:', error);
        res.status(500).json({ message: 'Server error' });
    }
}

module.exports = {login};