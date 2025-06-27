# MongoDB Atlas Setup Guide

## Step 1: Create MongoDB Atlas Account
1. Go to https://cloud.mongodb.com/
2. Sign up for a free account or log in if you already have one
3. Create a new organization and project

## Step 2: Create a Cluster
1. Click "Build a Database"
2. Choose "M0 Sandbox" (Free tier)
3. Select a cloud provider and region (preferably close to your users)
4. Name your cluster (e.g., "arcade-board-tracker")
5. Click "Create"

## Step 3: Set up Database Access
1. Go to "Database Access" in the left sidebar
2. Click "Add New Database User"
3. Choose "Password" authentication
4. Create a username and strong password
5. For Database User Privileges, select "Read and write to any database"
6. Click "Add User"

## Step 4: Set up Network Access
1. Go to "Network Access" in the left sidebar
2. Click "Add IP Address"
3. Click "Allow Access from Anywhere" (for production, you'd want to be more specific)
4. Click "Confirm"

## Step 5: Get Connection String
1. Go to "Database" in the left sidebar
2. Click "Connect" on your cluster
3. Choose "Connect your application"
4. Select "Node.js" and version "4.1 or later"
5. Copy the connection string
6. Replace `<password>` with your database user password
7. Replace `<dbname>` with your database name (e.g., "arcade-board-tracker-prod")

Your connection string will look like:
```
mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/arcade-board-tracker-prod?retryWrites=true&w=majority
```

## Next Steps
After you have your MongoDB Atlas connection string, we'll:
1. Add it as a Vercel environment variable
2. Deploy your application to production
