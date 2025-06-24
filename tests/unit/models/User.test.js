/**
 * User model tests
 */
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('../../../server/models/User');

// Mock bcrypt and jwt
jest.mock('bcryptjs');
jest.mock('jsonwebtoken');

describe('User Model', () => {
  beforeAll(async () => {
    // Mock mongoose functions
    jest.spyOn(mongoose.Model, 'create').mockImplementation((data) => Promise.resolve(data));
  });

  afterAll(() => {
    jest.clearAllMocks();
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
      // Mock bcrypt.genSalt
      bcrypt.genSalt.mockResolvedValue('salt');
      
      // Mock bcrypt.hash
      bcrypt.hash.mockResolvedValue('hashed_password');

      const userData = {
        username: 'testuser',
        email: 'test@example.com',
        password: 'password123',
      };

      const user = new User(userData);
      
      // Trigger the pre-save middleware
      await user.schema.pre('save').mock.calls[0][0].call(user);

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
  });
});
