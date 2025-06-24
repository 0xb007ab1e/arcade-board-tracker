# API Documentation

This document provides detailed information about the Arcade Board Tracker API endpoints.

## Base URL

- Development: `http://localhost:5000/api`
- Production: `https://your-deployed-api.com/api`

## Authentication

Most endpoints require authentication using JWT tokens.

Include the token in the Authorization header:
```
Authorization: Bearer your_jwt_token
```

## Health Endpoints

### Get API Health Status

Checks if the API is running.

- **URL**: `/health`
- **Method**: `GET`
- **Auth required**: No
- **Permissions**: None

#### Success Response

- **Code**: 200 OK
- **Content**:
```json
{
  "status": "success",
  "message": "API is running",
  "environment": "development",
  "timestamp": "2023-07-01T12:00:00.000Z"
}
```

### Get System Health Information

Returns detailed system information about the server.

- **URL**: `/health/system`
- **Method**: `GET`
- **Auth required**: No
- **Permissions**: None

#### Success Response

- **Code**: 200 OK
- **Content**:
```json
{
  "status": "success",
  "message": "System health check",
  "environment": "development",
  "timestamp": "2023-07-01T12:00:00.000Z",
  "system": {
    "platform": "linux",
    "nodeVersion": "v16.15.1",
    "uptime": 3600,
    "memoryUsage": {
      "rss": 51609600,
      "heapTotal": 29503488,
      "heapUsed": 17070544,
      "external": 1865540,
      "arrayBuffers": 106489
    },
    "cpuUsage": {
      "user": 117000,
      "system": 26000
    }
  }
}
```

## Authentication Endpoints

### Register User

Creates a new user account.

- **URL**: `/auth/register`
- **Method**: `POST`
- **Auth required**: No
- **Permissions**: None
- **Request Body**:
```json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "password123"
}
```

#### Success Response

- **Code**: 201 Created
- **Content**:
```json
{
  "status": "success",
  "token": "jwt_token_here",
  "data": {
    "user": {
      "_id": "user_id",
      "username": "testuser",
      "email": "test@example.com",
      "role": "viewer",
      "createdAt": "2023-07-01T12:00:00.000Z",
      "updatedAt": "2023-07-01T12:00:00.000Z"
    }
  }
}
```

### Login User

Authenticates a user and returns a JWT token.

- **URL**: `/auth/login`
- **Method**: `POST`
- **Auth required**: No
- **Permissions**: None
- **Request Body**:
```json
{
  "email": "test@example.com",
  "password": "password123"
}
```

#### Success Response

- **Code**: 200 OK
- **Content**:
```json
{
  "status": "success",
  "token": "jwt_token_here",
  "data": {
    "user": {
      "_id": "user_id",
      "username": "testuser",
      "email": "test@example.com",
      "role": "viewer",
      "createdAt": "2023-07-01T12:00:00.000Z",
      "updatedAt": "2023-07-01T12:00:00.000Z"
    }
  }
}
```

### Get Current User

Returns the currently authenticated user's information.

- **URL**: `/auth/me`
- **Method**: `GET`
- **Auth required**: Yes
- **Permissions**: Authenticated user

#### Success Response

- **Code**: 200 OK
- **Content**:
```json
{
  "status": "success",
  "data": {
    "user": {
      "_id": "user_id",
      "username": "testuser",
      "email": "test@example.com",
      "role": "viewer",
      "createdAt": "2023-07-01T12:00:00.000Z",
      "updatedAt": "2023-07-01T12:00:00.000Z"
    }
  }
}
```

## Error Responses

### Validation Error

- **Code**: 400 Bad Request
- **Content**:
```json
{
  "status": "fail",
  "message": "Validation error message"
}
```

### Authentication Error

- **Code**: 401 Unauthorized
- **Content**:
```json
{
  "status": "fail",
  "message": "Invalid credentials"
}
```

### Authorization Error

- **Code**: 403 Forbidden
- **Content**:
```json
{
  "status": "fail",
  "message": "You do not have permission to perform this action"
}
```

### Not Found Error

- **Code**: 404 Not Found
- **Content**:
```json
{
  "status": "fail",
  "message": "Can't find /api/unknown on this server"
}
```

### Server Error

- **Code**: 500 Internal Server Error
- **Content**:
```json
{
  "status": "error",
  "message": "Something went wrong"
}
```
