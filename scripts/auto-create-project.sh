#!/bin/bash
# Automated script to create a GitHub project and add issues
# This will run without requiring user input

set -e

echo "Creating GitHub project board automatically..."

# Get the current GitHub token
# We'll use the token from environment variable GH_TOKEN or GITHUB_TOKEN if available
CURRENT_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN}}"

# If no token is found in environment variables, try to extract it from GitHub CLI
if [ -z "$CURRENT_TOKEN" ]; then
  if [ -f "$HOME/.config/gh/hosts.yml" ]; then
    # Try to extract token from config file
    CURRENT_TOKEN=$(grep -A2 'oauth_token' "$HOME/.config/gh/hosts.yml" | grep 'oauth_token' | awk '{print $2}')
  fi
  
  # If still no token, ask user to provide it
  if [ -z "$CURRENT_TOKEN" ]; then
    read -p "GitHub token not found. Please enter your GitHub token: " CURRENT_TOKEN
  fi
fi

# Create project using GitHub REST API
echo "Creating project..."
PROJECT_DATA=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $CURRENT_TOKEN" \
  -X POST \
  https://api.github.com/user/projects \
  -d '{
    "name": "Arcade Board Tracker Development",
    "body": "Project board to track development of arcade-board-tracker features"
  }')

PROJECT_ID=$(echo $PROJECT_DATA | jq -r '.id')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "null" ]; then
  echo "Failed to create project. Response:"
  echo $PROJECT_DATA
  echo "Trying organization project creation instead..."
  
  # Try creating an organization project
  ORG_PROJECT_DATA=$(curl -s \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $CURRENT_TOKEN" \
    -X POST \
    https://api.github.com/orgs/0xb007ab1e/projects \
    -d '{
      "name": "Arcade Board Tracker Development",
      "body": "Project board to track development of arcade-board-tracker features"
    }')
    
  PROJECT_ID=$(echo $ORG_PROJECT_DATA | jq -r '.id')
  
  if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "null" ]; then
    echo "Failed to create organization project. Response:"
    echo $ORG_PROJECT_DATA
    echo "Trying repository project creation instead..."
    
    # Try creating a repository project
    REPO_PROJECT_DATA=$(curl -s \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: token $CURRENT_TOKEN" \
      -X POST \
      https://api.github.com/repos/0xb007ab1e/arcade-board-tracker/projects \
      -d '{
        "name": "Arcade Board Tracker Development",
        "body": "Project board to track development of arcade-board-tracker features"
      }')
      
    PROJECT_ID=$(echo $REPO_PROJECT_DATA | jq -r '.id')
    
    if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "null" ]; then
      echo "Failed to create repository project. Response:"
      echo $REPO_PROJECT_DATA
      echo "Please try running one of the interactive scripts that prompt for additional permissions."
      exit 1
    fi
  fi
fi

PROJECT_URL=$(echo $PROJECT_DATA | jq -r '.html_url')
echo "Project created successfully with ID: $PROJECT_ID"
echo "Project URL: $PROJECT_URL"

# Create columns
echo "Creating 'To Do' column..."
TODO_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $CURRENT_TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "To Do"
  }')

TODO_COLUMN_ID=$(echo $TODO_RESPONSE | jq -r '.id')

echo "Creating 'In Progress' column..."
IN_PROGRESS_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $CURRENT_TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "In Progress"
  }')

echo "Creating 'Done' column..."
DONE_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $CURRENT_TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "Done"
  }')

if [ -z "$TODO_COLUMN_ID" ] || [ "$TODO_COLUMN_ID" == "null" ]; then
  echo "Failed to create To Do column. Response:"
  echo $TODO_RESPONSE
  exit 1
fi

# Get the repo ID for the arcade-board-tracker
REPO_ID=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $CURRENT_TOKEN" \
  https://api.github.com/repos/0xb007ab1e/arcade-board-tracker | jq -r '.id')

# Add issues to the "To Do" column
ISSUE_IDS=(2 3 4 5 6 7 8 9 10)
SUCCESS_COUNT=0

for ISSUE_ID in "${ISSUE_IDS[@]}"; do
  echo "Adding issue #$ISSUE_ID to 'To Do' column..."
  
  # Get the issue URL
  ISSUE_URL="https://api.github.com/repos/0xb007ab1e/arcade-board-tracker/issues/$ISSUE_ID"
  
  ADD_RESPONSE=$(curl -s \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $CURRENT_TOKEN" \
    -X POST \
    "https://api.github.com/projects/columns/$TODO_COLUMN_ID/cards" \
    -d "{
      \"content_id\": $ISSUE_ID,
      \"content_type\": \"Issue\"
    }")
    
  CARD_ID=$(echo $ADD_RESPONSE | jq -r '.id')
  
  if [ -z "$CARD_ID" ] || [ "$CARD_ID" == "null" ]; then
    echo "Failed to add issue #$ISSUE_ID. Trying alternative method..."
    
    # Try alternative method with content_url
    ALT_ADD_RESPONSE=$(curl -s \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: token $CURRENT_TOKEN" \
      -X POST \
      "https://api.github.com/projects/columns/$TODO_COLUMN_ID/cards" \
      -d "{
        \"content_url\": \"$ISSUE_URL\"
      }")
      
    CARD_ID=$(echo $ALT_ADD_RESPONSE | jq -r '.id')
    
    if [ -z "$CARD_ID" ] || [ "$CARD_ID" == "null" ]; then
      echo "Failed to add issue #$ISSUE_ID using alternative method. Response:"
      echo $ALT_ADD_RESPONSE
    else
      echo "Issue #$ISSUE_ID added to 'To Do' column"
      ((SUCCESS_COUNT++))
    fi
  else
    echo "Issue #$ISSUE_ID added to 'To Do' column"
    ((SUCCESS_COUNT++))
  fi
done

# Final summary
echo "Project board setup complete!"
echo "Successfully added $SUCCESS_COUNT of ${#ISSUE_IDS[@]} issues to the project."
echo "View your project at: $PROJECT_URL"

# Save the project details for future reference
echo "PROJECT_ID=$PROJECT_ID" > .project-info
echo "PROJECT_URL=$PROJECT_URL" >> .project-info
echo "TODO_COLUMN_ID=$TODO_COLUMN_ID" >> .project-info

echo "Project information saved to .project-info file"
