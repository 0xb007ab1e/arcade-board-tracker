/**
 * Health endpoint integration tests
 */
const request = require('supertest');
const app = require('../../server/index');

// Mock database connection
jest.mock('../../server/config/db', () => jest.fn().mockResolvedValue());

describe('Health Endpoints', () => {
  beforeAll(() => {
    // Mock console.log to prevent logging during tests
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterAll(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/health', () => {
    it('should return health status', async () => {
      const response = await request(app).get('/api/health');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.message).toBe('API is running');
      expect(response.body.environment).toBeDefined();
      expect(response.body.timestamp).toBeDefined();
    });
  });

  describe('GET /api/health/system', () => {
    it('should return system health information', async () => {
      const response = await request(app).get('/api/health/system');

      expect(response.status).toBe(200);
      expect(response.body.status).toBe('success');
      expect(response.body.message).toBe('System health check');
      expect(response.body.environment).toBeDefined();
      expect(response.body.timestamp).toBeDefined();
      
      // Verify system info object
      expect(response.body.system).toBeDefined();
      expect(response.body.system.platform).toBeDefined();
      expect(response.body.system.nodeVersion).toBeDefined();
      expect(response.body.system.uptime).toBeDefined();
      expect(response.body.system.memoryUsage).toBeDefined();
      expect(response.body.system.cpuUsage).toBeDefined();
    });
  });
});
