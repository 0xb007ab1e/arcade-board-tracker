/**
 * Mock database setup
 */

// Mock mongoose to prevent real database connections
jest.mock('mongoose', () => {
  // Create mock functions for Mongoose methods
  const connect = jest.fn().mockResolvedValue({
    connection: {
      host: 'mocked-db-host'
    }
  });

  // Return a mock implementation of mongoose
  return {
    connect,
    connection: {
      on: jest.fn(),
      once: jest.fn()
    },
    Schema: jest.fn().mockImplementation(() => ({
      pre: jest.fn().mockReturnThis(),
      methods: {},
      virtual: jest.fn(),
      set: jest.fn()
    })),
    model: jest.fn().mockImplementation(() => ({
      find: jest.fn(),
      findOne: jest.fn(),
      findById: jest.fn(),
      create: jest.fn(),
    }))
  };
});

// Mock database connection
jest.mock('../../server/config/db', () => 
  jest.fn().mockImplementation(() => 
    Promise.resolve({ connection: { host: 'mocked-db-host' } })
  )
);

// Prevent process.exit from actually exiting in tests
const realExit = process.exit;
process.exit = jest.fn();

// After all tests, restore the original process.exit
afterAll(() => {
  process.exit = realExit;
});
