const admin = require("firebase-admin")

async function verifytoken(req,res,next){
    const authHeader = req.headers.authorization;
    console.log(authHeader)
    if(!authHeader || !authHeader.startsWith("Bearer ")){
        return res.status(401).json({error:"Unauthorized access"});
    }


const token = authHeader.split(" ")[1];

try{
    const decoded = await admin.auth().verifyIdToken(token)
    req.firebaseUid = decoded.userID;
    req.email = null;
    next()
}catch(err){
     console.error("Token verification failed", err);
    return res.status(403).json({ error: "Invalid or expired token" });
}
}

module.exports = verifytoken;