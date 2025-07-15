const express = require('express');
const app = express();
const authRoutes = require('./routes/AuthRoute');
const sequelize = require('./config/Database'); // your Sequelize instance

app.use(express.json());
app.use('/api/v2', authRoutes);
app.get('/health', (req, res) => res.send('OK'));
require('dotenv').config();

async function startServer() {
  try {
    await sequelize.authenticate(); // Test DB connection
    console.log('Database connected.');
const port = process.env.PORT || 3000;
    app.listen(port,'0.0.0.0', () => {
      console.log('Server running on port 3000');
    });
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
}

startServer();
