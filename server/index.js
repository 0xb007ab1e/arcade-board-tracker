const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');
const colors = require('colors');

// Load environment variables
dotenv.config();

// Import configuration
const config = require('./config/config');
const connectDB = require('./config/db');

// Create Express app
const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// CORS configuration
const corsOptions = {
  origin: process.env.NODE_ENV === 'production'
    ? ['https://your-frontend-domain.com', 'https://www.your-frontend-domain.com']
    : 'http://localhost:3000',
  optionsSuccessStatus: 200,
  credentials: true
};
app.use(cors(corsOptions));

// Set static folder for uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check route
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'API is running',
    environment: config.env,
    timestamp: new Date().toISOString(),
  });
});

// Enhanced health check with system info
app.get('/api/health/system', (req, res) => {
  const systemInfo = {
    platform: process.platform,
    nodeVersion: process.version,
    uptime: process.uptime(),
    memoryUsage: process.memoryUsage(),
    cpuUsage: process.cpuUsage(),
  };
  
  res.status(200).json({
    status: 'success',
    message: 'System health check',
    environment: config.env,
    timestamp: new Date().toISOString(),
    system: systemInfo
  });
});

// API Routes
app.use('/api/auth', require('./routes/auth'));

// Import error handling middleware
const { errorHandler } = require('./middleware/error');

// Error handling middleware
app.use(errorHandler);

// Handle 404 routes
app.use('*', (req, res) => {
  res.status(404).json({
    status: 'fail',
    message: `Can't find ${req.originalUrl} on this server`,
  });
});

// Start server
const PORT = config.port;

// Connect to database and start server
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`Server running in ${config.env} mode on port ${PORT}`.yellow.bold);
  });
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('UNHANDLED REJECTION! Shutting down...'.red.bold);
  console.error(err.name, err.message);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('UNCAUGHT EXCEPTION! Shutting down...'.red.bold);
  console.error(err.name, err.message);
  process.exit(1);
});

module.exports = app; // For testing purposes
