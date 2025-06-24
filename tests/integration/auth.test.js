/**
 * Auth integration tests
 */
const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../server/index');
const User = require('../../server/models/User');

// Mock mongoose and user model
jest.mock('../../server/models/User');
jest.mock('../../server/config/db', () => jest.fn().mockResolvedValue());

describe('Auth Endpoints', () => {
  beforeAll(() => {
    // Mock console.log to prevent logging during tests
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterAll(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new user', async () => {
      // Mock User.findOne to return null (no existing user)
      User.findOne.mockResolvedValue(null);
      
      // Mock User.create to return a new user
      const mockUser = {
        _id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        role: 'viewer',
        generateAuthToken: jest.fn().mockReturnValue('test-token'),
      };
      User.create.mockResolvedValue(mockUser);

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'test@example.com',
          password: 'password123',
        });

      expect(response.status).toBe(201);
      expect(response.body.status).toBe('success');
      expect(response.body.token).toBe('test-token');
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.password).toBeUndefined();
    });

    it('should return 400 if user already exists', async () => {
      // Mock User.findOne to return an existing user
      const existingUser = {
        _id: 'user123',
        username: 'testuser',
        email: 'existing@example.com',
      };
      User.findOne.mockResolvedValue(existingUser);

      const response = await request(app)
        .post('/api/auth/register')
        .send({
          username: 'testuser',
          email: 'existing@example.com',
          password: 'password123',
        });

      expect(response.status).toBe(400);
      expect(response.body.status).toBe('fail');
      expect(response.body.message).toContain('already exists');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login a user with correct credentials', async () => {
      // Mock user with password and matchPassword method
      const mockUser = {
        _id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        role: 'viewer',
        password: 'hashed_password',
        matchPassword: jest.fn().mockResolvedValue(true),
        generateAuthToken: jest.fn().mockReturnValue('test-token'),
      };
      
      // Mock User.findOne to return the user
      User.findOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(mockUser),
      });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'password123',
        });

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.token).toBe('test-token');
      expect(response.body.data.user).toBeDefined();
      expect(response.body.data.user.password).toBeUndefined();
    });

    it('should return 401 for incorrect credentials', async () => {
      // Mock user with password and matchPassword method that returns false
      const mockUser = {
        _id: 'user123',
        username: 'testuser',
        email: 'test@example.com',
        password: 'hashed_password',
        matchPassword: jest.fn().mockResolvedValue(false),
      };
      
      // Mock User.findOne to return the user
      User.findOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(mockUser),
      });

      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          password: 'wrong_password',
        });

      expect(response.status).toBe(401);
      expect(response.body.status).toBe('fail');
      expect(response.body.message).toContain('Invalid credentials');
    });

    it('should return 400 if email or password is missing', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .send({
          email: 'test@example.com',
          // Missing password
        });

      expect(response.status).toBe(400);
      expect(response.body.status).toBe('fail');
      expect(response.body.message).toContain('provide email and password');
    });
  });
});
