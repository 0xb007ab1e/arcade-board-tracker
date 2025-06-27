# Upcoming Features and Tasks

This document provides detailed breakdowns for the next set of features to be implemented in the Arcade Board Tracker. It expands on the user stories in our main tracking documents with more specific tasks and acceptance criteria.

## Priority 1: Fix Existing Testing Infrastructure

### User Story Q.1: Fix Test Mocking

**As a** developer,  
**I want** to fix failing tests with proper mocking,  
**So that** the test suite is reliable.

#### Tasks:

1. Replace direct mocking of Mongoose methods with a proper testing library like `mongodb-memory-server`
2. Refactor User model tests to use the in-memory database
3. Update authentication tests to use proper test fixtures
4. Implement proper teardown procedures for test database
5. Create helper utilities for test data generation

#### Acceptance Criteria:

- All existing tests pass consistently
- Tests do not rely on external MongoDB instance
- Mocking approach follows best practices
- Tests are isolated and don't affect each other
- CI pipeline runs tests successfully

#### Estimated effort: 2 points (2-3 days)

---

## Priority 2: Core Data Models

### User Story 1.9: Board Model Implementation

**As a** developer,  
**I want** to implement the Board model,  
**So that** arcade board data can be stored and retrieved.

#### Tasks:

1. Create MongoDB schema for Board with the following fields:
   - name (required, string)
   - manufacturer (required, string)
   - model (string)
   - serialNumber (string)
   - year (number)
   - condition (enum: "excellent", "good", "fair", "poor", "non-functional")
   - purchaseDate (date)
   - purchasePrice (number)
   - description (string)
   - notes (string)
   - location (string)
   - status (enum: "active", "in-repair", "retired", "sold")
   - images (array of strings - file paths)
   - documents (array of strings - file paths)
   - components (array of references to Component model)
   - repairs (array of references to Repair model)
   - createdBy (reference to User model)
   - timestamps (automatic)

2. Implement validation for required fields
3. Add pre-save hooks for any data processing
4. Create methods for common operations
5. Write comprehensive unit tests for the model

#### Acceptance Criteria:

- Board model is properly defined with all necessary fields
- Validation works correctly for all fields
- References to other models are set up correctly
- Timestamps are automatically generated
- Unit tests pass for all model functionality

#### Estimated effort: 3 points (3-4 days)

---

### User Story 1.10: Board CRUD Operations

**As a** user,  
**I want** to create, read, update, and delete arcade boards,  
**So that** I can manage my board inventory.

#### Tasks:

1. Create Board controller with the following functions:
   - createBoard
   - getAllBoards (with pagination)
   - getBoardById
   - updateBoard
   - deleteBoard

2. Implement route handlers in a new boards.js routes file
3. Add proper authentication middleware to all routes
4. Implement filtering options for board listing
5. Add role-based permissions checks
6. Create comprehensive tests for all endpoints

#### Acceptance Criteria:

- All CRUD operations function correctly
- Authentication is required for all operations
- Proper validation is performed on inputs
- Pagination works for listing boards
- Filtering by name, manufacturer, condition, and status works
- Only authorized users can perform operations
- All operations are properly tested

#### Estimated effort: 5 points (1 week)

---

### User Story 1.11: File Upload for Boards

**As a** user,  
**I want** to upload images and documents for boards,  
**So that** I can maintain visual and technical documentation.

#### Tasks:

1. Configure Multer middleware for file uploads
2. Create separate endpoints for image and document uploads
3. Implement file type validation (images: jpg, png, gif; documents: pdf, txt, doc, etc.)
4. Add file size limits (5MB for images, 10MB for documents)
5. Create directory structure for organized file storage
6. Implement file deletion when board is deleted
7. Update Board model to store file paths
8. Add comprehensive tests for file operations

#### Acceptance Criteria:

- Users can upload images and documents for boards
- Only allowed file types are accepted
- File size limits are enforced
- Files are stored in an organized directory structure
- File paths are correctly stored in the Board model
- Files are deleted when the associated board is deleted
- All operations are properly tested

#### Estimated effort: 4 points (4-5 days)

---

## Priority 3: Security Enhancements

### User Story S.1: Secure Token Management

**As an** administrator,  
**I want** secure token management for deployment,  
**So that** production credentials remain protected.

#### Tasks:

1. Document secure token storage procedures
2. Implement least privilege scope for service account tokens
3. Set up monitoring for token usage
4. Create audit logging for token access
5. Implement secure token injection in CI/CD pipelines

#### Acceptance Criteria:

- Tokens are stored securely, never in code
- Tokens use the minimum required permissions
- Token usage is monitored and logged
- Procedures are documented for team reference
- CI/CD pipeline securely handles tokens

#### Estimated effort: 3 points (3 days)

---

### User Story S.2: Token Rotation Procedure

**As a** DevOps engineer,  
**I want** a token rotation procedure,  
**So that** security credentials are regularly refreshed.

#### Tasks:

1. Document token rotation schedule (every 90 days)
2. Create scripts to automate token rotation
3. Implement notification system for upcoming rotation
4. Set up monitoring to verify successful rotation
5. Document emergency token revocation procedure

#### Acceptance Criteria:

- Clear documentation for token rotation
- Scripts automate the rotation process where possible
- Team is notified before rotation occurs
- Monitoring confirms successful rotation
- Emergency procedures are documented and tested

#### Estimated effort: 2 points (2 days)

---

## Next Steps Planning

After completing these high-priority items, the team should focus on:

1. **Component Model & CRUD Operations** - This will build on the Board model work and allow tracking individual components
2. **Repair Tracking** - Critical for the core use case of tracking repair history
3. **Frontend Authentication** - Begin building the user interface starting with authentication

## Implementation Recommendations

1. **Testing Approach**: Fix the existing tests first to build on a solid foundation
2. **Incremental Delivery**: Complete one model at a time with full CRUD before moving to the next
3. **Security First**: Incorporate security reviews into each feature implementation
4. **Documentation**: Update API documentation as endpoints are created

## Additional Considerations

- Consider setting up database indexes early for performance
- Plan for data validation at both model and API levels
- Consider implementing soft delete functionality for boards to prevent data loss

