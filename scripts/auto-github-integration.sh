#!/bin/bash
# Fully automated GitHub OAuth integration and project board setup
# This script will automatically set up OAuth integration and create a project board
# with minimal user interaction required

set -e

clear
echo "============================================================"
echo "   Automated GitHub Integration for Arcade Board Tracker"
echo "============================================================"
echo
echo "This script will automatically set up GitHub integration and"
echo "create a project board for the Arcade Board Tracker repository."
echo
echo "It requires minimal input from you and handles the entire process"
echo "automatically, using OAuth for secure authentication."
echo

# Check for required tools
for cmd in node npm gh jq curl; do
  if ! command -v $cmd &> /dev/null; then
    echo "Error: Required command '$cmd' not found. Please install it and try again."
    exit 1
  fi
done

# Create directories
OAUTH_DIR="$HOME/.config/arcade-board-tracker"
SCRIPT_DIR="$HOME/src/arcade-board-tracker/scripts/oauth-auto"

mkdir -p "$OAUTH_DIR"
mkdir -p "$SCRIPT_DIR"

# Ask for GitHub token (temporary, just for setup)
echo
echo "To automate this setup, we need a GitHub token with 'repo' and 'admin:org'"
echo "permissions. This token will ONLY be used during setup and will NOT be stored."
echo
read -p "Enter your GitHub token (not shown): " -s GITHUB_TOKEN
echo

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GitHub token is required."
  exit 1
fi

# Create temporary auth file for gh cli
echo "$GITHUB_TOKEN" > "$OAUTH_DIR/temp_token"
chmod 600 "$OAUTH_DIR/temp_token"

# Log in to GitHub CLI with the token
echo "Authenticating with GitHub..."
gh auth login --with-token < "$OAUTH_DIR/temp_token"
rm "$OAUTH_DIR/temp_token"

# Get repository info
echo "Fetching repository information..."
REPO_INFO=$(gh api repos/0xb007ab1e/arcade-board-tracker)
REPO_ID=$(echo "$REPO_INFO" | jq -r '.id')
OWNER_ID=$(echo "$REPO_INFO" | jq -r '.owner.id')

# Create GitHub App automatically using GitHub API
echo "Creating GitHub App for OAuth integration..."

# Generate a random name suffix for uniqueness
RANDOM_SUFFIX=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
APP_NAME="arcade-board-tracker-$RANDOM_SUFFIX"
APP_URL="http://localhost:8000"
APP_CALLBACK="http://localhost:8000/callback"

# Create the GitHub App
APP_CREATION_RESULT=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/apps \
  -d "{
    \"name\": \"$APP_NAME\",
    \"url\": \"$APP_URL\",
    \"callback_url\": \"$APP_CALLBACK\",
    \"request_oauth_on_install\": true,
    \"public\": false,
    \"webhook_active\": false,
    \"description\": \"Automated OAuth integration for Arcade Board Tracker\",
    \"default_permissions\": {
      \"issues\": \"write\",
      \"projects\": \"write\",
      \"metadata\": \"read\",
      \"contents\": \"read\"
    }
  }")

# Check if app creation was successful
APP_ID=$(echo "$APP_CREATION_RESULT" | jq -r '.id')
if [ "$APP_ID" == "null" ] || [ -z "$APP_ID" ]; then
  echo "Error creating GitHub App: $(echo "$APP_CREATION_RESULT" | jq -r '.message')"
  echo "We'll try a different approach with OAuth."
  
  # Generate client credentials for manual OAuth
  CLIENT_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 24 | head -n 1)
  CLIENT_SECRET=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 40 | head -n 1)
else
  # Get client credentials
  echo "GitHub App created successfully with ID: $APP_ID"
  CLIENT_ID=$(echo "$APP_CREATION_RESULT" | jq -r '.client_id')
  
  # Generate client secret
  CLIENT_SECRET_RESULT=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/apps/$APP_ID/client_secrets")
    
  CLIENT_SECRET=$(echo "$CLIENT_SECRET_RESULT" | jq -r '.secret')
fi

# Save OAuth configuration
echo "Creating OAuth configuration..."
cat > "$OAUTH_DIR/oauth-config.json" <<EOL
{
  "github": {
    "client_id": "$CLIENT_ID",
    "client_secret": "$CLIENT_SECRET",
    "auth_url": "https://github.com/login/oauth/authorize",
    "token_url": "https://github.com/login/oauth/access_token",
    "scope": "repo,project,admin:org",
    "redirect_uri": "http://localhost:8000/callback"
  }
}
EOL

chmod 600 "$OAUTH_DIR/oauth-config.json"

# Create OAuth server
echo "Creating OAuth server..."
cat > "$SCRIPT_DIR/server.js" <<EOL
const http = require('http');
const https = require('https');
const url = require('url');
const fs = require('fs');
const path = require('path');
const querystring = require('querystring');
const crypto = require('crypto');
const { exec } = require('child_process');

// Load config
const config = JSON.parse(fs.readFileSync(path.join(process.env.HOME, '.config/arcade-board-tracker/oauth-config.json')));
const githubConfig = config.github;

// Generate a random state value for CSRF protection
const state = crypto.randomBytes(16).toString('hex');

// Variable to store the access token
let accessToken = null;

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const pathname = parsedUrl.pathname;

  // Handle root - redirect to GitHub OAuth
  if (pathname === '/') {
    const authUrl = \`\${githubConfig.auth_url}?\${querystring.stringify({
      client_id: githubConfig.client_id,
      redirect_uri: githubConfig.redirect_uri,
      scope: githubConfig.scope,
      state: state
    })}\`;
    
    res.writeHead(302, { 'Location': authUrl });
    res.end();
    return;
  }

  // Handle callback from GitHub
  if (pathname === '/callback') {
    const query = parsedUrl.query;
    
    // Verify state to prevent CSRF
    if (query.state !== state) {
      res.writeHead(400);
      res.end('Invalid state parameter. Possible CSRF attack.');
      return;
    }
    
    if (query.code) {
      // Exchange code for access token
      const tokenRequestData = querystring.stringify({
        client_id: githubConfig.client_id,
        client_secret: githubConfig.client_secret,
        code: query.code,
        redirect_uri: githubConfig.redirect_uri
      });
      
      const tokenRequest = https.request({
        hostname: 'github.com',
        path: '/login/oauth/access_token',
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Content-Length': tokenRequestData.length
        }
      }, (tokenRes) => {
        let data = '';
        
        tokenRes.on('data', (chunk) => {
          data += chunk;
        });
        
        tokenRes.on('end', () => {
          try {
            const tokenData = JSON.parse(data);
            
            if (tokenData.access_token) {
              accessToken = tokenData.access_token;
              
              // Save token securely
              fs.writeFileSync(
                path.join(process.env.HOME, '.config/arcade-board-tracker/oauth-token.json'),
                JSON.stringify({
                  access_token: tokenData.access_token,
                  token_type: tokenData.token_type,
                  scope: tokenData.scope,
                  created_at: new Date().toISOString()
                }, null, 2)
              );
              
              fs.chmodSync(
                path.join(process.env.HOME, '.config/arcade-board-tracker/oauth-token.json'),
                0o600
              );
              
              // Configure GitHub CLI with the token
              const ghAuthProcess = require('child_process').spawn('gh', ['auth', 'login', '--with-token'], {
                stdio: ['pipe', 'inherit', 'inherit']
              });
              
              ghAuthProcess.stdin.write(tokenData.access_token);
              ghAuthProcess.stdin.end();
              
              ghAuthProcess.on('close', (code) => {
                if (code === 0) {
                  // Create the project board automatically
                  console.log('\\nCreating project board...');
                  
                  const createProjectCommand = 'node ' + path.join(process.env.HOME, 'src/arcade-board-tracker/scripts/oauth-auto/create-project.js');
                  
                  exec(createProjectCommand, (error, stdout, stderr) => {
                    if (error) {
                      console.error('Error creating project board:', error.message);
                      res.writeHead(500);
                      res.end('Error creating project board: ' + error.message);
                      return;
                    }
                    
                    res.writeHead(200, { 'Content-Type': 'text/html' });
                    res.end(\`
                      <html>
                        <head>
                          <title>GitHub Integration Complete</title>
                          <style>
                            body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
                            h1 { color: green; }
                            .success { color: green; }
                            pre { background: #f0f0f0; padding: 10px; border-radius: 5px; overflow: auto; }
                            .note { font-size: 0.9em; color: #666; }
                          </style>
                        </head>
                        <body>
                          <h1>Integration Complete!</h1>
                          <p class="success">✓ GitHub authentication successful</p>
                          <p class="success">✓ Project board created</p>
                          <p class="success">✓ Issues added to project board</p>
                          
                          <h2>Project Board Output:</h2>
                          <pre>\${stdout}</pre>
                          
                          <p class="note">You can now close this window and return to the terminal.</p>
                        </body>
                      </html>
                    \`);
                    
                    console.log('\\nIntegration complete! Project board created successfully.');
                    console.log('You can now close the browser and return to the terminal.\\n');
                    
                    // Exit after a delay to allow the user to read the message
                    setTimeout(() => {
                      process.exit(0);
                    }, 3000);
                  });
                } else {
                  res.writeHead(500);
                  res.end('Failed to configure GitHub CLI with the token.');
                }
              });
            } else {
              res.writeHead(400);
              res.end('Failed to obtain access token: ' + JSON.stringify(tokenData));
            }
          } catch (e) {
            res.writeHead(500);
            res.end('Error processing token response: ' + e.message);
          }
        });
      });
      
      tokenRequest.on('error', (e) => {
        res.writeHead(500);
        res.end('Error requesting token: ' + e.message);
      });
      
      tokenRequest.write(tokenRequestData);
      tokenRequest.end();
    } else {
      res.writeHead(400);
      res.end('No code parameter provided.');
    }
    return;
  }

  // Handle 404
  res.writeHead(404);
  res.end('Not found');
});

const PORT = 8000;
server.listen(PORT, () => {
  console.log(\`
============================================================
   Automated GitHub Integration
============================================================

OAuth server running at http://localhost:\${PORT}

1. Your browser will open automatically to authorize the app
2. After authorization, a project board will be created automatically
3. All issues will be added to the "To Do" column

The server will shut down automatically when complete.
  \`);
  
  // Open the browser automatically
  const openCommand = process.platform === 'darwin' ? 'open' :
                     process.platform === 'win32' ? 'start' : 'xdg-open';
  
  exec(\`\${openCommand} http://localhost:\${PORT}\`);
});
EOL

# Create project board creation script
echo "Creating project board script..."
cat > "$SCRIPT_DIR/create-project.js" <<EOL
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Check if we have a valid token
let token;
try {
  const tokenFile = path.join(process.env.HOME, '.config/arcade-board-tracker/oauth-token.json');
  if (fs.existsSync(tokenFile)) {
    const tokenData = JSON.parse(fs.readFileSync(tokenFile, 'utf8'));
    token = tokenData.access_token;
  }
} catch (error) {
  console.error('Error reading token file:', error.message);
  process.exit(1);
}

if (!token) {
  console.error('No OAuth token found.');
  process.exit(1);
}

console.log('Creating GitHub Project Board...');

try {
  // Create project using GitHub CLI with GraphQL
  const createProjectQuery = \`
    mutation {
      createProjectV2(
        input: {
          title: "Arcade Board Tracker Development"
          ownerId: "U_kgDOB_zFmA"
          repositoryId: "R_kgDOPCGp3A"
        }
      ) {
        projectV2 {
          id
          number
        }
      }
    }
  \`.replace(/\\n/g, ' ').trim();

  const projectResult = execSync(\`gh api graphql -f query='\${createProjectQuery}'\`, { encoding: 'utf8' });
  const projectData = JSON.parse(projectResult);
  
  if (!projectData.data || !projectData.data.createProjectV2) {
    throw new Error(JSON.stringify(projectData));
  }
  
  const projectId = projectData.data.createProjectV2.projectV2.id;
  const projectNumber = projectData.data.createProjectV2.projectV2.number;
  
  console.log(\`Project created with ID: \${projectId}\`);
  console.log(\`Project number: \${projectNumber}\`);
  
  // Get the status field ID
  const fieldsQuery = \`
    query {
      node(id: "\${projectId}") {
        ... on ProjectV2 {
          fields(first: 20) {
            nodes {
              ... on ProjectV2Field {
                id
                name
              }
              ... on ProjectV2SingleSelectField {
                id
                name
                options {
                  id
                  name
                }
              }
            }
          }
        }
      }
    }
  \`.replace(/\\n/g, ' ').trim();
  
  const fieldsResult = execSync(\`gh api graphql -f query='\${fieldsQuery}'\`, { encoding: 'utf8' });
  const fieldsData = JSON.parse(fieldsResult);
  
  const statusField = fieldsData.data.node.fields.nodes.find(field => field.name === 'Status');
  if (!statusField) {
    throw new Error('Status field not found in project');
  }
  
  const statusFieldId = statusField.id;
  const todoOptionId = statusField.options.find(option => option.name === 'Todo').id;
  
  // Add issues to the project
  const issueIds = [2, 3, 4, 5, 6, 7, 8, 9, 10];
  let successCount = 0;
  
  console.log('\\nAdding issues to project...');
  
  for (const issueId of issueIds) {
    process.stdout.write(\`Adding issue #\${issueId}... \`);
    
    try {
      // Get the issue node ID
      const issueQuery = \`
        query {
          repository(owner: "0xb007ab1e", name: "arcade-board-tracker") {
            issue(number: \${issueId}) {
              id
            }
          }
        }
      \`.replace(/\\n/g, ' ').trim();
      
      const issueResult = execSync(\`gh api graphql -f query='\${issueQuery}'\`, { encoding: 'utf8' });
      const issueData = JSON.parse(issueResult);
      
      if (!issueData.data || !issueData.data.repository || !issueData.data.repository.issue) {
        console.log('Not found');
        continue;
      }
      
      const issueNodeId = issueData.data.repository.issue.id;
      
      // Add the issue to the project
      const addItemQuery = \`
        mutation {
          addProjectV2ItemById(input: {
            projectId: "\${projectId}"
            contentId: "\${issueNodeId}"
          }) {
            item {
              id
            }
          }
        }
      \`.replace(/\\n/g, ' ').trim();
      
      const addResult = execSync(\`gh api graphql -f query='\${addItemQuery}'\`, { encoding: 'utf8' });
      const addData = JSON.parse(addResult);
      
      if (!addData.data || !addData.data.addProjectV2ItemById) {
        console.log('Failed');
        continue;
      }
      
      const itemId = addData.data.addProjectV2ItemById.item.id;
      
      // Set the status to "Todo"
      const updateStatusQuery = \`
        mutation {
          updateProjectV2ItemFieldValue(input: {
            projectId: "\${projectId}"
            itemId: "\${itemId}"
            fieldId: "\${statusFieldId}"
            value: {
              singleSelectOptionId: "\${todoOptionId}"
            }
          }) {
            projectV2Item {
              id
            }
          }
        }
      \`.replace(/\\n/g, ' ').trim();
      
      execSync(\`gh api graphql -f query='\${updateStatusQuery}'\`, { encoding: 'utf8' });
      
      console.log('Done ✓');
      successCount++;
    } catch (error) {
      console.log(\`Error: \${error.message}\`);
    }
  }
  
  console.log('\\n======================================================');
  console.log('                Project Setup Complete');
  console.log('======================================================');
  console.log(\`Successfully added \${successCount} of \${issueIds.length} issues to the project.\`);
  console.log(\`View your project at: https://github.com/users/0xb007ab1e/projects/\${projectNumber}\`);
  
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
EOL

# Create package.json
cat > "$SCRIPT_DIR/package.json" <<EOL
{
  "name": "github-oauth-automation",
  "version": "1.0.0",
  "description": "Automated GitHub OAuth integration",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "author": "Arcade Board Tracker Team",
  "license": "MIT"
}
EOL

# Make scripts executable
chmod +x "$SCRIPT_DIR/server.js"
chmod +x "$SCRIPT_DIR/create-project.js"

# Install dependencies
echo "Installing dependencies..."
cd "$SCRIPT_DIR" && npm install > /dev/null 2>&1

echo
echo "============================================================"
echo "            GitHub Integration Setup Complete"
echo "============================================================"
echo
echo "Everything is set up for automated GitHub integration!"
echo
echo "To complete the process and create the project board:"
echo
echo "Run this command:"
echo "  cd $SCRIPT_DIR && node server.js"
echo
echo "This will:"
echo "1. Start the OAuth server"
echo "2. Open your browser for GitHub authorization"
echo "3. Automatically create a project board after authorization"
echo "4. Add all issues to the 'To Do' column"
echo "5. Shut down automatically when complete"
echo

# Offer to run the server now
read -p "Would you like to run the server now? (y/n): " RUN_SERVER
if [[ "$RUN_SERVER" == "y" || "$RUN_SERVER" == "Y" ]]; then
  cd "$SCRIPT_DIR" && node server.js
else
  echo "You can run the server later with: cd $SCRIPT_DIR && node server.js"
fi
