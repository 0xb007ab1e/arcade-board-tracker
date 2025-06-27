/**
 * Utility script to generate a bypass token for Vercel Authentication
 */
require('dotenv').config();
const jwt = require('jsonwebtoken');

// Get JWT secret from environment
const jwtSecret = process.env.JWT_SECRET;

if (!jwtSecret) {
  console.error('Error: JWT_SECRET not found in environment variables');
  process.exit(1);
}

// Generate token with long expiration (1 year)
const payload = {
  id: 'bypass-user',
  role: 'admin',
  purpose: 'vercel-auth-bypass'
};

const token = jwt.sign(payload, jwtSecret, { expiresIn: '1y' });

console.log('\n=== Vercel Authentication Bypass Token ===');
console.log('\nUse this token in the URL as a query parameter:');
console.log(`\nhttps://your-app-url.vercel.app/api/health?bypassToken=${token}`);
console.log('\nOr use as a header in API requests:');
console.log(`X-Vercel-Bypass: ${token}`);
console.log('\n======================================\n');

// For copying
console.log('Token:');
console.log(token);
