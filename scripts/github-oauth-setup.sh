#!/bin/bash
# GitHub OAuth integration setup script
# This script guides you through setting up a GitHub OAuth App for secure integration

set -e

clear
echo "============================================================"
echo "   GitHub OAuth Integration Setup for Arcade Board Tracker"
echo "============================================================"
echo
echo "This script will guide you through setting up OAuth integration"
echo "with GitHub for managing projects and issues securely."
echo
echo "Instead of using personal access tokens, we'll set up a proper"
echo "OAuth App integration that follows security best practices."
echo

# Step 1: Create OAuth App
echo "STEP 1: Create a GitHub OAuth App"
echo "--------------------------------"
echo "1. Go to: https://github.com/settings/developers"
echo "2. Click 'New OAuth App'"
echo "3. Fill in the following details:"
echo "   - Application name: Arcade Board Tracker"
echo "   - Homepage URL: http://localhost:8000"
echo "   - Application description: Project management for Arcade Board Tracker"
echo "   - Authorization callback URL: http://localhost:8000/callback"
echo "4. Click 'Register application'"
echo "5. On the next page, note your Client ID"
echo "6. Click 'Generate a new client secret' and note the secret"
echo
read -p "Press Enter when you've completed this step... " DUMMY

# Step 2: Get the OAuth credentials
echo
echo "STEP 2: Enter your OAuth App credentials"
echo "---------------------------------------"
read -p "Enter the Client ID: " CLIENT_ID
read -p "Enter the Client Secret: " CLIENT_SECRET

# Validate input
if [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
  echo "Error: Client ID and Client Secret are required."
  exit 1
fi

# Step 3: Save the credentials securely
echo
echo "STEP 3: Saving OAuth credentials securely"
echo "----------------------------------------"
mkdir -p ~/.config/arcade-board-tracker
CONFIG_FILE=~/.config/arcade-board-tracker/oauth-config.json

cat > "$CONFIG_FILE" <<EOL
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

chmod 600 "$CONFIG_FILE"
echo "Credentials saved to $CONFIG_FILE"

# Step 4: Create a simple OAuth service
echo
echo "STEP 4: Creating local OAuth service"
echo "-----------------------------------"

OAUTH_SERVICE_DIR=~/src/arcade-board-tracker/scripts/oauth-service
mkdir -p "$OAUTH_SERVICE_DIR"

# Create server.js file
cat > "$OAUTH_SERVICE_DIR/server.js" <<EOL
const http = require('http');
const https = require('https');
const url = require('url');
const fs = require('fs');
const path = require('path');
const querystring = require('querystring');
const crypto = require('crypto');

// Load config
const config = JSON.parse(fs.readFileSync(path.join(process.env.HOME, '.config/arcade-board-tracker/oauth-config.json')));
const githubConfig = config.github;

// Generate a random state value for CSRF protection
const state = crypto.randomBytes(16).toString('hex');

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
              
              // Set up the GitHub CLI with the token
              const setupGitHubCLI = require('child_process').spawn('gh', ['auth', 'login', '--with-token'], {
                stdio: ['pipe', 'inherit', 'inherit']
              });
              
              setupGitHubCLI.stdin.write(tokenData.access_token);
              setupGitHubCLI.stdin.end();
              
              setupGitHubCLI.on('close', (code) => {
                if (code === 0) {
                  res.writeHead(200, { 'Content-Type': 'text/html' });
                  res.end(\`
                    <html>
                      <head>
                        <title>GitHub OAuth Success</title>
                        <style>
                          body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; }
                          .success { color: green; }
                          .token { background: #f0f0f0; padding: 10px; border-radius: 5px; word-break: break-all; }
                          .note { font-size: 0.9em; color: #666; }
                        </style>
                      </head>
                      <body>
                        <h1 class="success">Authentication Successful!</h1>
                        <p>Your GitHub OAuth token has been saved securely.</p>
                        <p>The GitHub CLI has been configured with this token.</p>
                        <p class="note">You can now close this window and return to the terminal.</p>
                      </body>
                    </html>
                  \`);
                  
                  console.log('\\nAuthentication successful! Token saved securely.');
                  console.log('You can now close the browser and return to the terminal.\\n');
                  
                  // Exit after a delay to allow the user to read the message
                  setTimeout(() => {
                    process.exit(0);
                  }, 5000);
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
   GitHub OAuth Authorization Server
============================================================

The authorization server is running at http://localhost:\${PORT}

1. Open this URL in your browser: http://localhost:\${PORT}
2. You will be redirected to GitHub for authorization
3. After granting permission, you'll be redirected back
4. Your OAuth token will be saved securely

The server will automatically shut down after successful
authentication.
  \`);
});
EOL

# Create package.json
cat > "$OAUTH_SERVICE_DIR/package.json" <<EOL
{
  "name": "github-oauth-service",
  "version": "1.0.0",
  "description": "OAuth service for GitHub integration",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "author": "Arcade Board Tracker Team",
  "license": "MIT"
}
EOL

echo "OAuth service created at $OAUTH_SERVICE_DIR"

# Step 5: Create the integration script
echo
echo "STEP 5: Creating project board integration script"
echo "------------------------------------------------"

cat > "$OAUTH_SERVICE_DIR/create-project-board.js" <<EOL
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

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
}

if (!token) {
  console.log('No OAuth token found. Please run the oauth authentication first:');
  console.log('  cd ~/src/arcade-board-tracker/scripts/oauth-service && node server.js');
  process.exit(1);
}

console.log('======================================================');
console.log('  Creating GitHub Project Board for Arcade Board Tracker');
console.log('======================================================');
console.log();

// Create a project using GitHub CLI with GraphQL
console.log('Creating project...');
try {
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
    console.error('Failed to create project:', projectData);
    process.exit(1);
  }
  
  const projectId = projectData.data.createProjectV2.projectV2.id;
  const projectNumber = projectData.data.createProjectV2.projectV2.number;
  
  console.log(\`Project created with ID: \${projectId}\`);
  console.log(\`Project number: \${projectNumber}\`);
  
  // Get the status field ID
  console.log('Getting field IDs...');
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
    console.error('Status field not found in project');
    process.exit(1);
  }
  
  const statusFieldId = statusField.id;
  const todoOptionId = statusField.options.find(option => option.name === 'Todo').id;
  
  console.log(\`Status field ID: \${statusFieldId}\`);
  console.log(\`Todo option ID: \${todoOptionId}\`);
  
  // Add issues to the project
  const issueIds = [2, 3, 4, 5, 6, 7, 8, 9, 10];
  let successCount = 0;
  
  console.log('\\nAdding issues to project...');
  
  for (const issueId of issueIds) {
    console.log(\`Adding issue #\${issueId}...\`);
    
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
      console.log(\`  Error: Issue #\${issueId} not found\`);
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
    
    try {
      const addResult = execSync(\`gh api graphql -f query='\${addItemQuery}'\`, { encoding: 'utf8' });
      const addData = JSON.parse(addResult);
      
      if (!addData.data || !addData.data.addProjectV2ItemById) {
        console.log(\`  Error adding issue #\${issueId} to project\`);
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
      
      console.log(\`  Issue #\${issueId} added and set to Todo status\`);
      successCount++;
    } catch (error) {
      console.log(\`  Error processing issue #\${issueId}: \${error.message}\`);
    }
  }
  
  console.log('\\n======================================================');
  console.log('                 Project Setup Complete');
  console.log('======================================================');
  console.log(\`Successfully added \${successCount} of \${issueIds.length} issues to the project.\`);
  console.log(\`View your project at: https://github.com/users/0xb007ab1e/projects/\${projectNumber}\`);
  
} catch (error) {
  console.error('Error creating project:', error.message);
  process.exit(1);
}

rl.close();
EOL

chmod +x "$OAUTH_SERVICE_DIR/create-project-board.js"

echo "Project board integration script created"

# Step 6: Final instructions
echo
echo "STEP 6: Setup complete"
echo "--------------------"
echo "To use the OAuth integration:"
echo
echo "1. Start the OAuth server:"
echo "   cd ~/src/arcade-board-tracker/scripts/oauth-service && node server.js"
echo
echo "2. Follow the instructions to authenticate in your browser"
echo
echo "3. After authentication is complete, create a project board:"
echo "   cd ~/src/arcade-board-tracker/scripts/oauth-service && node create-project-board.js"
echo
echo "This approach uses OAuth for secure authentication instead of"
echo "manually managing tokens, following security best practices."
echo

# Final setup
echo "Installing required dependencies..."
mkdir -p "$OAUTH_SERVICE_DIR/node_modules"
cd "$OAUTH_SERVICE_DIR" && npm install >/dev/null 2>&1

echo
echo "Setup complete! You can now run the OAuth server to authenticate."
echo "cd ~/src/arcade-board-tracker/scripts/oauth-service && node server.js"
