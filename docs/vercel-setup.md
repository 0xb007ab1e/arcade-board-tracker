# Secure Vercel Deployment with OIDC Federation

This project uses OpenID Connect (OIDC) Federation for secure authentication with Vercel. This setup eliminates the need for long-lived API tokens and provides a more secure authentication method for CI/CD pipelines.

## Prerequisites

1. A Vercel account with a Team workspace named `arcade-board-tracker`
2. Multi-factor authentication (MFA) enabled on the Vercel account
3. AWS account for handling OIDC federation
4. GitHub repository with GitHub Actions

## Setup Instructions

### 1. Create a Vercel Team Account

1. Create a Vercel account using `devops@0xb007ab1e.net` (or use an existing one)
2. Enable MFA immediately after account creation
3. Create a Team workspace named `arcade-board-tracker`
4. Ensure a strong, unique password is stored in your team's password manager

### 2. Configure AWS IAM for OIDC

1. Create an OIDC provider in AWS IAM for GitHub Actions:
   ```
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --client-id-list sts.amazonaws.com \
     --thumbprint-list <thumbprint>
   ```

2. Create an IAM role with the trust policy from `infra/aws-oidc-config.json`
   ```
   aws iam create-role \
     --role-name VercelOIDCDeploymentRole \
     --assume-role-policy-document file://infra/aws-oidc-config.json
   ```

3. Attach the necessary policies to the role for Vercel deployments

### 3. Configure GitHub Repository Secrets

Add the following secrets to your GitHub repository:
- `VERCEL_OIDC_ROLE_ARN`: The ARN of the IAM role created in step 2
- `AWS_REGION`: The AWS region where the IAM role is located
- `VERCEL_ORG_ID`: Your Vercel organization ID
- `VERCEL_PROJECT_ID`: Your Vercel project ID
- `MONGO_URI`: MongoDB connection string
- `JWT_SECRET`: JWT secret for authentication

### 4. CI/CD Workflow

The GitHub Actions workflow in `.github/workflows/deploy.yml` is configured to:
1. Authenticate with AWS using OIDC
2. Obtain temporary AWS credentials
3. Use these credentials to authenticate with Vercel
4. Deploy the application to Vercel

## Security Benefits

- No long-lived API tokens stored in CI/CD
- Temporary credentials only valid for the duration of the deployment
- MFA protection for the Vercel account
- Separation of concerns with a dedicated team workspace
- Fine-grained access control through AWS IAM

## References

- [Vercel Authentication Documentation](https://vercel.com/docs/concepts/authentication)
- [GitHub Actions OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
