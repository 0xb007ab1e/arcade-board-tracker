/**
 * Mocked User model for testing
 */
const selectMock = jest.fn();

const UserModel = {
  findOne: jest.fn(),
  create: jest.fn(),
  findById: jest.fn(),
  __selectMock: selectMock
};

// Reset the mock functions before each test
beforeEach(() => {
  UserModel.findOne.mockReset();
  UserModel.create.mockReset();
  UserModel.findById.mockReset();
  selectMock.mockReset();
});

module.exports = UserModel;
