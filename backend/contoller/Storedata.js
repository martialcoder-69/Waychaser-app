
const LocationData = require("../models/UserInfo");

async function storedata(req, res) {
  const input = req.body;

 
  const records = Array.isArray(input) ? input : [input];


  for (const record of records) {
    const { userID, latitude, longitude, timestamp, accuracy } = record;
    if (!userID || !latitude || !longitude || !timestamp || !accuracy) {
      return res.status(400).json({
        error: "Missing required fields in one or more records.",
      });
    }
  }

  try {
    
    const inserted = await LocationData.bulkCreate(records, {
      ignoreDuplicates: true,
      validate: true,
    });

    return res.status(200).json({
      message: `Stored ${inserted.length} record(s) successfully.`,
    });
  } catch (error) {
    console.error("Error storing location(s):", error);
    return res.status(500).json({
      error: "Failed to store location data.",
      details: error.message,
    });
  }
}

module.exports = { storedata };
