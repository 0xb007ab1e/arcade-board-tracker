const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const path = require('path');
const colors = require('colors');

// Load environment variables based on NODE_ENV
const envFile = process.env.NODE_ENV === 'production' 
  ? '.env.production'
  : process.env.NODE_ENV === 'preview'
    ? '.env.preview'
    : '.env';

dotenv.config({ path: envFile });
console.log(`Loading environment from: ${envFile}`.cyan.bold);

// Import configuration
const config = require('./config/config');
const connectDB = require('./config/db');

// Create Express app
const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: false }));

// Vercel Authentication Bypass
const vercelBypass = require('./middleware/vercelBypass');
app.use(vercelBypass);

// CORS configuration
const corsOptions = {
  origin: process.env.NODE_ENV === 'production'
    ? ['https://your-frontend-domain.com', 'https://www.your-frontend-domain.com']
    : 'http://localhost:3000',
  optionsSuccessStatus: 200,
  credentials: true,
};
app.use(cors(corsOptions));

// Set static folder for uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check route
app.get('/api/health', (req, res) => {
  // Check if request has bypass user (from middleware)
  const bypassActive = req.bypassUser ? true : false;
  
  res.status(200).json({
    status: 'success',
    message: 'API is running',
    environment: config.env,
    timestamp: new Date().toISOString(),
    auth: {
      bypass: bypassActive,
      user: bypassActive ? req.bypassUser.id : null,
    },
  });
});

// Enhanced health check with system info
// Simple rate limiting - Max 10 requests per minute per IP
const systemHealthRateLimit = {
  windowMs: 60 * 1000, // 1 minute
  max: 10, // 10 requests per windowMs
  standardHeaders: true,
  message: { status: 'fail', message: 'Too many requests, please try again later.' },
};

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
    system: systemInfo,
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

// Create server object but don't start it yet
let server = null;

// Only start the server if this file is run directly (not for testing)
if (require.main === module) {
  // Connect to database and start server
  connectDB().then(() => {
    server = app.listen(PORT, () => {
      console.log(`Server running in ${config.env} mode on port ${PORT}`.yellow.bold);
    });
  });

  // Handle unhandled promise rejections
  process.on('unhandledRejection', (err) => {
    console.error('UNHANDLED REJECTION! Shutting down...'.red.bold);
    console.error(err.name, err.message);
    if (server) {
      server.close(() => {
        process.exit(1);
      });
    } else {
      process.exit(1);
    }
  });

  // Handle uncaught exceptions
  process.on('uncaughtException', (err) => {
    console.error('UNCAUGHT EXCEPTION! Shutting down...'.red.bold);
    console.error(err.name, err.message);
    if (server) {
      server.close(() => {
        process.exit(1);
      });
    } else {
      process.exit(1);
    }
  });
}

// Export for testing purposes
module.exports = {
  app,
  startServer: async (port = 0) => {
    // For tests, use port 0 to get a random available port
    // For normal operation, use the configured PORT
    const serverPort = port || PORT;
    await connectDB();
    return app.listen(serverPort);
  }
};
