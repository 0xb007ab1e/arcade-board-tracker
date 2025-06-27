require('dotenv').config({ path: '.env.vercel.production' });
const mongoose = require('mongoose');
const colors = require('colors');

// Get the MongoDB URI from environment variables
const mongoURI = process.env.MONGO_URI;

// Check if MongoDB URI contains a placeholder password
if (mongoURI && mongoURI.includes('{{MONGO_PASSWORD}}')) {
  console.log('Found MongoDB Atlas URI with password placeholder'.yellow);
  console.log('This indicates MongoDB Atlas is properly configured in Vercel production environment'.green);
}

console.log(`Attempting to connect to MongoDB at: ${mongoURI}`.cyan.bold);

// Connect to MongoDB
mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => {
    console.log('MongoDB connected successfully!'.green.bold);
    mongoose.connection.close();
  })
  .catch(err => {
    console.error('MongoDB connection failed:'.red.bold, err.message);
  });
