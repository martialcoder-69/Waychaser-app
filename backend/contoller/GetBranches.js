const branch = require("../models/Branches");

async function getBranch(req,res){
    try{
        const results = branch.findAll({
            attributes:['Latitude','Longitude','Branch_Name']
        })

        const locationdata = (await results).map((entry)=>({
            lat:entry.Latitude,
            lon:entry.Longitude,
            name:entry.Branch_Name
        }));

        return res.status(200).json(locationdata);
    }catch(e){
        return res.status(500).json({message:e});
    }

}

module.exports = {getBranch};