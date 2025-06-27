/**
 * Authentication controller
 */
const User = require('../models/User');
const { AppError } = require('../middleware/error');

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
const register = async (req, res, next) => {
  try {
    const { username, email, password } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ $or: [{ email }, { username }] });
    if (existingUser) {
      return next(
        new AppError(
          `User with that ${existingUser.email === email ? 'email' : 'username'} already exists`,
          400,
        ),
      );
    }

    // Create user
    const user = await User.create({
      username,
      email,
      password,
    });

    // Generate token
    const token = user.generateAuthToken();

    // Remove password from response
    user.password = undefined;

    res.status(201).json({
      status: 'success',
      token,
      data: {
        user,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Check if email and password exist
    if (!email || !password) {
      return next(new AppError('Please provide email and password', 400));
    }

    // Check if user exists and password is correct
    const user = await User.findOne({ email }).select('+password');
    if (!user || !(await user.matchPassword(password))) {
      return next(new AppError('Invalid credentials', 401));
    }

    // Generate token
    const token = user.generateAuthToken();

    // Remove password from response
    user.password = undefined;

    res.status(200).json({
      status: 'success',
      token,
      data: {
        user,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current user
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);

    res.status(200).json({
      status: 'success',
      data: {
        user,
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  getMe,
};
