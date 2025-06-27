#!/bin/bash

# MongoDB Atlas Production Setup Script
# This script will help you configure your application for production deployment

echo "🚀 Setting up MongoDB Atlas for production deployment"
echo "=================================================="

# Check if vercel CLI is installed and user is logged in
if ! command -v vercel &> /dev/null; then
    echo "❌ Vercel CLI not found. Please install it first."
    exit 1
fi

# Check if user is logged in to Vercel
if ! vercel whoami &> /dev/null; then
    echo "❌ You are not logged in to Vercel. Please run 'vercel login' first."
    exit 1
fi

echo "✅ Vercel CLI is installed and you are logged in"

# Prompt for MongoDB Atlas connection string
echo ""
echo "📋 Please provide your MongoDB Atlas connection string:"
echo "It should look like: mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/database?retryWrites=true&w=majority"
echo ""
read -p "MongoDB Atlas URI: " MONGO_URI

if [ -z "$MONGO_URI" ]; then
    echo "❌ MongoDB URI cannot be empty."
    exit 1
fi

# Validate the MongoDB URI format
if [[ ! "$MONGO_URI" =~ ^mongodb\+srv:// ]]; then
    echo "⚠️  Warning: The URI doesn't appear to be a MongoDB Atlas URI (should start with mongodb+srv://)"
    read -p "Continue anyway? (y/N): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "🔐 Setting up Vercel environment variables..."

# Add MONGO_URI to Vercel
echo "Adding MONGO_URI..."
echo "$MONGO_URI" | vercel env add MONGO_URI production

# Add JWT_SECRET to Vercel
echo "Adding JWT_SECRET..."
JWT_SECRET=$(openssl rand -hex 32)
echo "$JWT_SECRET" | vercel env add JWT_SECRET production

echo ""
echo "✅ Environment variables have been set up successfully!"
echo ""
echo "🚀 Ready to deploy to production!"
echo "Run: vercel --prod"
echo ""
echo "📝 Your production environment variables:"
echo "- MONGO_URI: ✅ Set"
echo "- JWT_SECRET: ✅ Generated and set"
echo "- NODE_ENV: ✅ Set to 'production' in vercel.json"
echo "- JWT_EXPIRE: ✅ Set to '30d' in vercel.json"
