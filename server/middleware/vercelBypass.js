/**
 * Middleware to bypass Vercel Authentication
 * This allows authenticated API access even when Vercel Protection is enabled
 */
const jwt = require('jsonwebtoken');
const config = require('../config/config');

const vercelBypassMiddleware = (req, res, next) => {
  // Check for bypass token in headers, query or cookies
  const bypassToken = 
    req.headers['x-vercel-bypass'] || 
    req.query.bypassToken || 
    req.cookies?.vercelBypass;
  
  if (bypassToken) {
    try {
      // Verify using our JWT secret
      const decoded = jwt.verify(bypassToken, config.jwt.secret);
      
      // If valid, allow access
      if (decoded) {
        req.bypassUser = decoded;
        return next();
      }
    } catch (error) {
      console.log('Invalid bypass token:', error.message);
    }
  }
  
  // Continue normal flow if no valid token
  next();
};

module.exports = vercelBypassMiddleware;
