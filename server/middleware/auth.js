/**
 * Authentication middleware
 */
const jwt = require('jsonwebtoken');
const { AppError } = require('./error');
const config = require('../config/config');

// Protect routes - require authentication
const protect = async (req, res, next) => {
  try {
    // 1) Check if token exists
    let token;
    
    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith('Bearer')
    ) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return next(new AppError('You are not logged in. Please log in to get access.', 401));
    }

    // 2) Verify token
    try {
      const decoded = jwt.verify(token, config.jwt.secret);
      
      // 3) Set user in req (normally we would check if user still exists in DB)
      // This will be implemented when we have the User model
      // const user = await User.findById(decoded.id);
      // if (!user) {
      //   return next(new AppError('The user belonging to this token no longer exists.', 401));
      // }
      
      // 4) Grant access to protected route
      req.user = decoded;
      next();
    } catch (error) {
      return next(new AppError('Invalid token. Please log in again.', 401));
    }
  } catch (error) {
    next(error);
  }
};

// Restrict to certain roles
const restrictTo = (...roles) => {
  return (req, res, next) => {
    // roles is an array like ['admin', 'technician']
    if (!roles.includes(req.user.role)) {
      return next(new AppError('You do not have permission to perform this action.', 403));
    }
    next();
  };
};

module.exports = {
  protect,
  restrictTo,
};
