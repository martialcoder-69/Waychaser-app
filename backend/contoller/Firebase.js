const path = require('path');
const admin = require('firebase-admin');

const serviceAccount = require("../config/osmtracker-4835d-firebase-adminsdk-fbsvc-386252e237.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

module.exports = admin;
