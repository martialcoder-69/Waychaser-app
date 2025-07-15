const sequelize = require("../config/Database");
const User = require("../models/User");

async function getusers(req, res) {
  try {
    const tree = {};

    const results = await User.findAll({
      attributes: ['userID', 'ManagedBy'],
      raw: true
    });

    for (const user of results) {
      const manager = user.ManagedBy;
      const emp = user.userID;

      if (!manager || manager === 'None') continue;

      if (!tree[manager]) {
        tree[manager] = new Set();
      }

      tree[manager].add(emp);
    }

    const treeAsObject = {};
    for (const [key, value] of Object.entries(tree)) {
      treeAsObject[key] = Array.from(value);
    }

    const [data] = await sequelize.query(`
      SELECT w.userID, w.timestamp, w.latitude, w.longitude 
      FROM waychaser w
      JOIN (
          SELECT userID, MAX(timestamp) AS maxt 
          FROM waychaser 
          GROUP BY userID
      ) a 
      ON a.userID = w.userID AND a.maxt = w.timestamp
    `);

    const locationMap = {};
    for (const row of data) {
      locationMap[row.userID] = {
        lat: row.latitude,
        lon: row.longitude,
        time: row.timestamp
      };
    }

    for (const manager in treeAsObject) {
      treeAsObject[manager] = treeAsObject[manager].map(empID => {
        const loc = locationMap[empID];
        return loc ? { userID: empID, ...loc } : { userID: empID };
      });
    }

    return res.status(200).json(treeAsObject);
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: e.message });
  }
}

module.exports = { getusers };
