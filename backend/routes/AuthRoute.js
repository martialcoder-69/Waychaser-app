const express = require("express");

const router = express.Router();

const {login} = require("../contoller/AuthController");
const {storedata} = require("../contoller/Storedata");
const { getMap } = require("../contoller/MapController");
const {getusers} = require("../contoller/AuthMap");
const {getBranch} = require("../contoller/GetBranches");
const {storeappusage} = require("../contoller/AppUsageCont");


router.post("/store",storedata)
router.post("/login",login);
router.post('/getmap',getMap);
router.get('/authmap',getusers)
router.get('/getBranch',getBranch);
router.post('/appusage',storeappusage);

module.exports = router;