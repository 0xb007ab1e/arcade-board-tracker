# CI/CD Pipeline Setup

This document explains how to set up the Continuous Integration and Continuous Deployment (CI/CD) pipeline for the Arcade Board Tracker project. Our pipeline automatically tests and deploys each branch to the user's selected cloud provider.

## Overview

The CI/CD pipeline is implemented using GitHub Actions and consists of the following stages:

1. **Test**: Run linting and automated tests
2. **Select Deployment Provider**: Determine which cloud provider to use for deployment
3. **Deploy**: Deploy the code to the selected provider
4. **Notify**: Report the deployment status

## Supported Deployment Providers

The pipeline supports deploying to the following providers:

- Vercel (default)
- Render
- Railway
- Heroku
- Netlify

## Setting Up the Pipeline

### 1. GitHub Repository Setup

1. Push your code to a GitHub repository
2. Ensure your repository has the `.github/workflows/deploy.yml` file

### 2. Securely Storing Credentials

All credentials are stored as GitHub Secrets to keep them secure. To set up secrets:

1. Go to your GitHub repository
2. Click on "Settings" → "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Add the required secrets as described below

#### Required Secrets for All Providers

| Secret Name | Description |
|-------------|-------------|
| `MONGO_URI` | MongoDB connection string |
| `JWT_SECRET` | Secret key for JWT token generation |

#### Provider-Specific Secrets

##### Vercel (OIDC Authentication)

| Secret Name | Description |
|-------------|-------------|
| `VERCEL_ORG_ID` | Vercel organization ID |
| `VERCEL_PROJECT_ID` | Vercel project ID |
| `VERCEL_OIDC_ROLE_ARN` | AWS IAM Role ARN for OIDC authentication |
| `AWS_REGION` | AWS region for OIDC authentication |

To obtain these values:
1. Install Vercel CLI: `npm i -g vercel`
2. Run: `vercel login`
3. Navigate to your project directory
4. Run: `vercel link` (if not already linked)
5. Look for the `.vercel/project.json` file which contains the project ID
6. Get the organization ID from your Vercel dashboard
7. Set up AWS OIDC integration for secure token-less authentication

##### Render

| Secret Name | Description |
|-------------|-------------|
| `RENDER_API_KEY` | Render API key |

To obtain this value:
1. Log in to Render dashboard
2. Go to your account settings
3. Navigate to API Keys
4. Create a new API key

##### Railway

| Secret Name | Description |
|-------------|-------------|
| `RAILWAY_TOKEN` | Railway API token |

To obtain this value:
1. Install Railway CLI: `npm i -g @railway/cli`
2. Run: `railway login`
3. Run: `railway whoami --token`

##### Heroku

| Secret Name | Description |
|-------------|-------------|
| `HEROKU_API_KEY` | Heroku API key |
| `HEROKU_EMAIL` | Email associated with Heroku account |

To obtain these values:
1. Log in to Heroku
2. Go to Account Settings
3. Find your API key under the "API Key" section

##### Netlify

| Secret Name | Description |
|-------------|-------------|
| `NETLIFY_AUTH_TOKEN` | Netlify authentication token |
| `NETLIFY_SITE_ID` | Netlify site ID |

To obtain these values:
1. Log in to Netlify
2. Go to User Settings → Applications → Personal access tokens
3. Create a new token
4. Get the site ID from your site settings or the Netlify CLI with `netlify sites:list`

### 3. Setting the Default Provider

The default deployment provider is Vercel. To change the default provider:

1. Go to your GitHub repository
2. Click on "Settings" → "Secrets and variables" → "Actions"
3. Click on the "Variables" tab
4. Click "New repository variable"
5. Create a variable named `DEPLOYMENT_PROVIDER` with one of these values:
   - `vercel`
   - `render`
   - `railway`
   - `heroku`
   - `netlify`

### 4. Branch-Specific Providers

You can configure different providers for specific branches:

1. Go to your GitHub repository settings
2. Navigate to "Secrets and variables" → "Actions" → "Variables" tab
3. Create a variable with this naming pattern:
   - `DEPLOYMENT_PROVIDER_FEATURE_NAME` for feature/name branch
   - `DEPLOYMENT_PROVIDER_BUGFIX_ISSUE123` for bugfix/issue123 branch
   - Replace `/` with `_` and convert to uppercase

For example, to deploy the `feature/auth` branch to Railway, create a variable:
- Name: `DEPLOYMENT_PROVIDER_FEATURE_AUTH`
- Value: `railway`

## How the Pipeline Works

1. When you push code to a branch or open a pull request, the pipeline triggers automatically
2. It first runs tests to ensure code quality
3. It then determines which provider to use for deployment:
   - First checks for branch-specific provider configuration
   - Falls back to repository-wide default provider
   - Uses Vercel if no provider is specified
4. It deploys the code to the selected provider, setting up necessary environment variables
5. For non-main branches, it creates a unique deployment with a branch-specific URL
6. It reports the deployment status

## Deployment URLs

Each branch gets its own unique URL:

| Provider | URL Format |
|----------|------------|
| Vercel | `https://[branch-name]-arcade-board-tracker.vercel.app` |
| Render | Unique URL provided in the GitHub Actions log |
| Railway | Unique URL provided in the GitHub Actions log |
| Heroku | `https://arcade-board-tracker-[branch-name].herokuapp.com` |
| Netlify | Unique URL provided in the GitHub Actions log |

For the `main` branch, the production URL is used without branch prefixes.

## Troubleshooting

If the deployment fails, check the following:

1. **GitHub Actions Logs**: 
   - Go to the "Actions" tab in your repository
   - Click on the failed workflow run
   - Expand the failed job to see detailed logs

2. **Provider Dashboard**:
   - Check the deployment logs in your provider's dashboard
   - Verify environment variables are correctly set

3. **Common Issues**:
   - **Missing Secrets**: Ensure all required secrets are set in GitHub
   - **Build Errors**: Check if the build process fails due to code errors
   - **Provider Limits**: Some providers have limits on free tier deployments

## Adding a New Provider

To add support for a new deployment provider:

1. Add a new job in `.github/workflows/deploy.yml`
2. Create provider-specific deployment steps
3. Update the documentation with the new provider's requirements
4. Add appropriate secrets for the new provider

## Security Considerations

- Never store sensitive credentials in the repository code
- Always use GitHub Secrets for sensitive information
- Restrict access to who can view and modify GitHub Secrets
- Regularly rotate API keys and tokens
- Use the minimum necessary permissions for deployment tokens

## Token Rotation and Revocation Procedure

### Token Management

| Detail | Information |
|--------|-------------|
| Token Owner | DevOps Team Lead |
| Creation Date | Document when token was created (e.g., YYYY-MM-DD) |
| Rotation Schedule | Every 90 days |

### Token Rotation Process

1. **Create New Token in Vercel**:
   - Log in to the Vercel dashboard
   - Go to Account Settings → Tokens
   - Click "Create" to generate a new token
   - Set appropriate scopes (minimum necessary permissions)
   - Copy the new token (it will only be shown once)

2. **Update GitHub Secret**:
   - Go to your GitHub repository
   - Navigate to Settings → Secrets and variables → Actions
   - Edit the existing secret (e.g., `VERCEL_TOKEN`)
   - Paste the new token value
   - Click "Update secret"

3. **Verify Deployment**:
   - Trigger a test deployment to verify the new token works correctly
   - Monitor the GitHub Actions workflow for any authentication issues

### Token Revocation

In case of a security incident or team member departure:

1. **Revoke Token in Vercel**:
   - Log in to the Vercel dashboard
   - Go to Account Settings → Tokens
   - Find the token to be revoked
   - Click "Delete" to immediately invalidate the token

2. **Create New Token**:
   - Follow the steps above to create a new token with appropriate permissions

3. **Update GitHub Secret**:
   - Update the GitHub Secret with the new token value
   - Document the new token creation date
