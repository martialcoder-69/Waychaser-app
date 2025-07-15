const appusage = require("../models/AppUsage");

async function storeappusage(req,res){
    const {userID,model,serial,timestamp,apps} = req.body;

    if(!userID || !serial){
        return res.status(401).json({message:"Missing fileds"});
    }

    try{
        const insert = await appusage.create({
            userID,
            model,
            serial,
            timestamp,
            apps,
        });

        return res.status(200).json({message:"Success"});
    }
    catch(e){
        console.log(e);
        return res.status(500).json({message:e});
    }
}

module.exports = {storeappusage}