const UserInfo = require("../models/UserInfo");
const { Op } = require("sequelize");

async function getMap(req, res) {
  const { userID, startDate, endDate } = req.body;

  if (!userID || !startDate || !endDate) {
    console.log(userID);
    console.log(startDate);
    console.log(endDate);
    return res.status(400).json({ message: "Missing parameters" });
    
  }

  try {
    const start = new Date(startDate);
    const end = new Date(endDate);
    console.log(startDate);
    console.log(endDate);
    const results = await UserInfo.findAll({
      where: {
        userID,
        timestamp: {
          [Op.between]: [start, end],
        },
      },
      order: [["timestamp", "ASC"]],
    });

    if (!results || results.length === 0) {
      return res.status(404).json({ message: "No data found for given range" });
    }

    const locationData = results.map(entry => ({
      latitude: entry.latitude,
      longitude: entry.longitude,
      timestamp:entry.timestamp,
      accuracy: entry.accuracy,
    }));

    res.status(200).json(locationData);
  } catch (error) {
    console.error("getMap error:", error);
    res.status(500).json({ message: "Server error" });
  }
}

module.exports = { getMap };
