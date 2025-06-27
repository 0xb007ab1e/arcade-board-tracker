#!/bin/bash
# Setup script for Vercel account with OIDC authentication
# This script helps set up the Vercel CLI with a team account

set -e

echo "===== Vercel Team Account Setup with Secure Authentication ====="
echo "This script will help you set up a Vercel team account for arcade-board-tracker"
echo "It will use OIDC federation for secure authentication instead of password-based auth"
echo

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "Vercel CLI not found. Installing..."
    npm install -g vercel
fi

# Check Vercel CLI version
VERCEL_VERSION=$(vercel --version)
echo "Using Vercel CLI version: $VERCEL_VERSION"

# Get AWS CLI configuration
if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found. Please install it to continue with OIDC setup."
    exit 1
fi

# Prompt for account details
read -p "Enter your Vercel account email (devops@0xb007ab1e.net): " EMAIL
EMAIL=${EMAIL:-devops@0xb007ab1e.net}

echo
echo "=== Creating Team Workspace ==="
echo "We'll now set up the 'arcade-board-tracker' team workspace"
echo

# Check if already logged in
CURRENT_USER=$(vercel whoami 2>/dev/null || echo "")
if [ -n "$CURRENT_USER" ]; then
    echo "Currently logged in as: $CURRENT_USER"
    read -p "Do you want to continue with this account? (y/n): " CONTINUE
    if [ "$CONTINUE" != "y" ]; then
        vercel logout
        vercel login $EMAIL
    fi
else
    echo "Please log in to Vercel"
    vercel login $EMAIL
fi

# Create or select team
TEAM_EXISTS=$(vercel teams ls 2>/dev/null | grep -c "arcade-board-tracker" || echo "0")
if [ "$TEAM_EXISTS" -eq "0" ]; then
    echo "Creating new team: arcade-board-tracker"
    vercel teams create arcade-board-tracker
else
    echo "Team 'arcade-board-tracker' already exists"
    vercel teams switch arcade-board-tracker
fi

# Get team ID
TEAM_ID=$(vercel teams ls | grep arcade-board-tracker | awk '{print $1}')
echo "Team ID: $TEAM_ID"

# Configure project
echo
echo "=== Configuring Project ==="
echo "Now we'll link the project to the team"

# Link project
if [ -f "vercel.json" ]; then
    echo "Found vercel.json, linking project..."
    vercel link --team arcade-board-tracker
else
    echo "No vercel.json found. Please run this script from the project root directory."
    exit 1
fi

# Get project info
PROJECT_ID=$(vercel project ls --team arcade-board-tracker | grep arcade-board-tracker | awk '{print $1}')
echo "Project ID: $PROJECT_ID"

# Configure GitHub repo for OIDC
echo
echo "=== Configure AWS IAM for OIDC ==="
echo "To complete setup, follow these steps:"
echo "1. Create an OIDC provider in AWS IAM for GitHub Actions"
echo "2. Create an IAM role using the trust policy in infra/aws-oidc-config.json"
echo "3. Add required GitHub secrets as listed in docs/vercel-setup.md"
echo

echo "=== Setting up environment variables ==="
echo "Add the following secrets to your GitHub repository:"
echo "VERCEL_ORG_ID=$TEAM_ID"
echo "VERCEL_PROJECT_ID=$PROJECT_ID"
echo

echo "=== Verifying MFA Status ==="
echo "Please ensure MFA is enabled on your Vercel account by visiting:"
echo "https://vercel.com/account/security"
echo

echo "=== Setup Complete ==="
echo "Your Vercel team account 'arcade-board-tracker' is now set up."
echo "Remember to:"
echo "1. Enable MFA on your Vercel account if not already enabled"
echo "2. Store your credentials in your team's password manager"
echo "3. Complete the AWS OIDC setup as described in docs/vercel-setup.md"
