# Deployment Guide for Arcade Board Tracker

This guide provides detailed instructions for deploying the Arcade Board Tracker application to various platforms for preview during development.

## Prerequisites

Before deploying, ensure you have:

1. A MongoDB database accessible from the internet (e.g., MongoDB Atlas)
2. A GitHub repository for your project (optional but recommended)
3. Necessary environment variables:
   - `MONGO_URI`: MongoDB connection string
   - `JWT_SECRET`: Secret key for JWT token generation
   - `NODE_ENV`: Set to "production" for deployment

## Deployment Options

### Option 1: Vercel (Recommended for Backend)

Vercel offers a simple deployment process and works well for Node.js applications.

#### Step 1: Prepare Your Project

Ensure you have the `vercel.json` file in your project root:

```json
{
  "version": 2,
  "builds": [
    {
      "src": "server/index.js",
      "use": "@vercel/node"
    }
  ],
  "routes": [
    {
      "src": "/(.*)",
      "dest": "server/index.js"
    }
  ],
  "env": {
    "NODE_ENV": "production",
    "MONGO_URI": "@mongo_uri",
    "JWT_SECRET": "@jwt_secret",
    "JWT_EXPIRE": "30d"
  }
}
```

#### Step 2: Install Vercel CLI

```bash
npm install -g vercel
```

#### Step 3: Deploy

```bash
# Login to Vercel
vercel login

# Deploy
vercel

# For production deployment
vercel --prod
```

#### Step 4: Set Environment Variables

1. Go to the Vercel dashboard
2. Navigate to your project settings
3. Add environment variables:
   - `MONGO_URI`
   - `JWT_SECRET`

#### Step 5: Access Your Deployed API

Your API will be available at the URL provided by Vercel (e.g., `https://arcade-board-tracker.vercel.app`).

### Option 2: Render

Render provides a generous free tier and is easy to use for full-stack applications.

#### Step 1: Prepare Your Project

Ensure you have the `render.yaml` file in your project root:

```yaml
services:
  - type: web
    name: arcade-board-tracker-api
    env: node
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: MONGO_URI
        sync: false
      - key: JWT_SECRET
        sync: false
      - key: JWT_EXPIRE
        value: 30d
      - key: PORT
        value: 10000
```

#### Step 2: Deploy to Render

1. Create an account on [Render](https://render.com/)
2. Connect your GitHub repository
3. Click "New Web Service"
4. Select your repository
5. Render will automatically detect the `render.yaml` file
6. Configure environment variables:
   - `MONGO_URI`
   - `JWT_SECRET`
7. Click "Create Web Service"

#### Step 3: Access Your Deployed API

Your API will be available at the URL provided by Render (e.g., `https://arcade-board-tracker-api.onrender.com`).

### Option 3: Heroku

Heroku is a popular platform with a straightforward deployment process.

#### Step 1: Prepare Your Project

Ensure you have the `Procfile` in your project root:

```
web: node server/index.js
```

#### Step 2: Install Heroku CLI

```bash
npm install -g heroku
```

#### Step 3: Deploy to Heroku

```bash
# Login to Heroku
heroku login

# Create a Heroku app
heroku create arcade-board-tracker

# Set environment variables
heroku config:set MONGO_URI=your_mongodb_uri
heroku config:set JWT_SECRET=your_jwt_secret
heroku config:set NODE_ENV=production

# Deploy to Heroku
git push heroku main
```

#### Step 4: Access Your Deployed API

Your API will be available at the URL provided by Heroku (e.g., `https://arcade-board-tracker.herokuapp.com`).

### Option 4: Railway

Railway is becoming increasingly popular for full-stack applications.

#### Step 1: Prepare Your Project

Ensure you have the `railway.json` file in your project root:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm install"
  },
  "deploy": {
    "startCommand": "npm start",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

#### Step 2: Deploy to Railway

1. Create an account on [Railway](https://railway.app/)
2. Install Railway CLI: `npm i -g @railway/cli`
3. Login: `railway login`
4. Create a new project: `railway init`
5. Deploy: `railway up`
6. Set environment variables:
   - `MONGO_URI`
   - `JWT_SECRET`
   - `NODE_ENV=production`

#### Step 3: Access Your Deployed API

Your API will be available at the URL provided by Railway.

## MongoDB Atlas Setup

For all deployment options, you'll need a MongoDB database accessible from the internet:

1. Create an account on [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Create a new cluster (the free tier is sufficient for development)
3. Create a database user with appropriate permissions
4. Whitelist all IP addresses (0.0.0.0/0) for development purposes
5. Get your connection string (replace `<password>` with your actual password)

## File Storage Considerations

For file uploads, consider using cloud storage:

1. For local development, files can be stored in the `server/uploads` directory
2. For production, use a cloud storage service:
   - AWS S3
   - Google Cloud Storage
   - Cloudinary (especially good for images)

See the [Cloud Storage Guide](CLOUD_STORAGE.md) for implementation details.

## Frontend Deployment (When Ready)

Once your frontend is implemented, you can deploy it to:

1. **Vercel**: Excellent for React applications
2. **Netlify**: Great for static sites and React apps
3. **GitHub Pages**: Good for static sites
4. **Firebase Hosting**: Good for React applications

Remember to update the API base URL in your frontend code to point to your deployed backend.

## Testing Your Deployment

After deploying, test your API using a tool like Postman or cURL:

```bash
# Test health endpoint
curl https://your-deployed-api.com/api/health

# Test registration endpoint
curl -X POST https://your-deployed-api.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"password123"}'
```

## Troubleshooting

### Common Issues

1. **Connection Issues**:
   - Verify your MongoDB connection string
   - Check if IP whitelist includes your deployment platform

2. **Environment Variables**:
   - Ensure all required environment variables are set
   - Check for typos in variable names

3. **Build Failures**:
   - Check build logs for errors
   - Verify your Node.js version compatibility

4. **CORS Errors**:
   - Update your CORS configuration to allow your frontend domain

### Getting Help

1. Check the platform-specific documentation
2. Review deployment logs
3. Check MongoDB Atlas logs for connection issues

## Continuous Deployment

For a smoother workflow, consider setting up continuous deployment:

1. Connect your GitHub repository to your deployment platform
2. Configure automatic deployments on push to main branch
3. Set up preview deployments for pull requests

This will allow you to automatically deploy changes as you develop and provide preview links for code reviews.
