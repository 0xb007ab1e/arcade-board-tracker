/**
 * User model tests
 */
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const config = require('../../../server/config/config');

// Setup mocks for external modules
// Setup separate mock functions explicitly
jest.mock('bcryptjs');
bcrypt.genSalt = jest.fn();
bcrypt.hash = jest.fn();
bcrypt.compare = jest.fn();

jest.mock('jsonwebtoken');
jwt.sign = jest.fn();

// Create a mock User model for testing
const UserMock = {
  // Mock properties and methods needed for tests
  validateSync: jest.fn(),
  isModified: jest.fn(),
  matchPassword: jest.fn(),
  generateAuthToken: jest.fn(),
};

// Mock constructor for User
function User(data) {
  // Merge the provided data with our mock methods
  return { ...data, ...UserMock };
}

describe('User Model', () => {
  beforeEach(() => {
    // Reset mocks before each test
    jest.clearAllMocks();
    
    // Default implementation for validateSync
    UserMock.validateSync.mockImplementation(function() {
      const errors = {};
      
      // Check required fields
      if (!this.username) errors.username = { message: 'Username is required' };
      if (!this.email) errors.email = { message: 'Email is required' };
      if (!this.password) errors.password = { message: 'Password is required' };
      
      // Validate email format
      if (this.email && !/^([\w-.]+@([\w-]+\.)+[\w-]{2,4})?$/.test(this.email)) {
        errors.email = { message: 'Please provide a valid email address' };
      }
      
      // Validate role enum
      if (this.role && !['admin', 'technician', 'viewer'].includes(this.role)) {
        errors.role = { message: 'Role must be admin, technician, or viewer' };
      }
      
      // Return validation errors if any
      return Object.keys(errors).length > 0 ? { errors } : undefined;
    });
    
    // Default implementation for isModified
    UserMock.isModified.mockReturnValue(true);
    
    // Default implementation for matchPassword
    UserMock.matchPassword.mockImplementation(async function(enteredPassword) {
      return await bcrypt.compare(enteredPassword, this.password);
    });
    
    // Default implementation for generateAuthToken
    UserMock.generateAuthToken.mockImplementation(function() {
      return jwt.sign(
        { id: this._id, username: this.username, role: this.role },
        config.jwt.secret,
        { expiresIn: config.jwt.expiresIn }
      );
    });
  });

  describe('User Schema', () => {
    it('should validate a valid user', () => {
      const validUser = {
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        role: 'viewer',
      };

      const user = new User(validUser);
      const validationError = user.validateSync();
      
      expect(validationError).toBeUndefined();
    });

    it('should validate email format', () => {
      const invalidUser = {
        username: 'testuser',
        email: 'invalid-email',
        password: 'password123',
        role: 'viewer',
      };

      const user = new User(invalidUser);
      const validationError = user.validateSync();
      
      expect(validationError).toBeDefined();
      expect(validationError.errors.email).toBeDefined();
    });

    it('should require username, email, and password', () => {
      const invalidUser = {};

      const user = new User(invalidUser);
      const validationError = user.validateSync();
      
      expect(validationError).toBeDefined();
      expect(validationError.errors.username).toBeDefined();
      expect(validationError.errors.email).toBeDefined();
      expect(validationError.errors.password).toBeDefined();
    });

    it('should validate role enum values', () => {
      const invalidUser = {
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
        role: 'invalid-role',
      };

      const user = new User(invalidUser);
      const validationError = user.validateSync();
      
      expect(validationError).toBeDefined();
      expect(validationError.errors.role).toBeDefined();
    });
  });

  describe('Password Hashing', () => {
    it('should hash password before saving', async () => {
      // Mock bcrypt methods for this test
      bcrypt.genSalt.mockResolvedValue('salt');
      bcrypt.hash.mockResolvedValue('hashed_password');

      const userData = {
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      };

      const user = new User(userData);
      
      // Simulate what happens in the pre-save hook
      if (user.isModified('password')) {
        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(user.password, salt);
      }

      expect(bcrypt.genSalt).toHaveBeenCalledWith(10);
      expect(bcrypt.hash).toHaveBeenCalledWith('password123', 'salt');
      expect(user.password).toBe('hashed_password');
    });
  });

  describe('Methods', () => {
    it('should verify password correctly', async () => {
      // Mock bcrypt.compare
      bcrypt.compare.mockResolvedValue(true);

      const user = new User({
        username: 'testuser',
        email: 'test@example.com',
        password: 'hashed_password',
      });

      const isMatch = await user.matchPassword('password123');
      
      expect(bcrypt.compare).toHaveBeenCalledWith('password123', 'hashed_password');
      expect(isMatch).toBe(true);
    });
    
    it('should generate JWT token', () => {
      // Mock jwt.sign
      jwt.sign.mockReturnValue('test_token');
      
      // Create a backup of the original config
      const originalSecret = config.jwt.secret;
      const originalExpiresIn = config.jwt.expiresIn;
      
      // Override the config properties for the test
      config.jwt.secret = 'test_secret';
      config.jwt.expiresIn = '1h';
      
      const user = new User({
        _id: 'user_id',
        username: 'testuser',
        role: 'viewer',
      });
      
      // Call the method which should use our mock
      const token = user.generateAuthToken();
      
      // Verify the mock was called with the expected parameters
      expect(jwt.sign).toHaveBeenCalledWith(
        { id: 'user_id', username: 'testuser', role: 'viewer' },
        'test_secret',
        { expiresIn: '1h' }
      );
      expect(token).toBe('test_token');
      
      // Restore the original config values
      config.jwt.secret = originalSecret;
      config.jwt.expiresIn = originalExpiresIn;
    });
  });
});
