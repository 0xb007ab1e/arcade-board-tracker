# Local MongoDB Setup

This project is configured to use a local MongoDB instance for all environments (development, preview, and production).

## Prerequisites

1. **Install MongoDB Community Server**
   ```bash
   # Ubuntu/Debian
   wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
   echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
   sudo apt-get update
   sudo apt-get install -y mongodb-org
   
   # Start MongoDB service
   sudo systemctl start mongod
   sudo systemctl enable mongod
   ```

2. **Verify MongoDB Installation**
   ```bash
   # Check if MongoDB is running
   sudo systemctl status mongod
   
   # Connect to MongoDB shell
   mongosh
   ```

## Database Configuration

The application uses separate databases for different environments:

- **Development**: `arcade-board-tracker-dev`
- **Production**: `arcade-board-tracker-prod`
- **Preview/Staging**: `arcade-board-tracker-preview`

## Environment Files

Three environment files have been created:

- `.env` - Development environment
- `.env.production` - Production environment  
- `.env.preview` - Preview/staging environment

Each file contains:
- Unique 256-bit JWT secrets (64 character hex strings)
- Separate MongoDB database names
- Appropriate environment configurations

## Security Notes

- JWT secrets are industry-standard 256-bit (32 byte) tokens
- Each environment uses a unique JWT secret for security isolation
- Environment files are gitignored to prevent secret exposure
- MongoDB connections use localhost for local hosting

## Running the Application

```bash
# Development
npm run dev

# Production (using .env.production)
NODE_ENV=production npm start

# Preview (using .env.preview)  
NODE_ENV=preview npm start
```

## MongoDB Management

```bash
# Connect to specific database
mongosh arcade-board-tracker-dev
mongosh arcade-board-tracker-prod
mongosh arcade-board-tracker-preview

# View databases
mongosh --eval "show dbs"

# Drop a database (if needed for reset)
mongosh arcade-board-tracker-dev --eval "db.dropDatabase()"
```
