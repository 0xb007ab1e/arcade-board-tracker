/**
 * Health endpoint integration tests
 */
const request = require('supertest');
const { app, startServer } = require('../../server/index');

describe('Health Endpoints', () => {
  // Keep track of the server instance
  let server;

  beforeAll(async () => {
    // Mock console.log to prevent logging during tests
    jest.spyOn(console, 'log').mockImplementation(() => {});
    jest.spyOn(console, 'error').mockImplementation(() => {});
    
    // Start the server for testing on a random available port (0)
    server = await startServer(0);
  });

  afterAll(async () => {
    jest.clearAllMocks();
    
    // Close the server to prevent open handles
    if (server && server.close) {
      await new Promise(resolve => {
        server.close(resolve);
      });
    }
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
