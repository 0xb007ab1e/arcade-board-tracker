#!/bin/bash
# Script to create a GitHub project board using curl
# This script is an alternative to using gh api if permissions are an issue

set -e

# Get the GitHub token
TOKEN=""
while [ -z "$TOKEN" ]; do
  read -p "Enter your GitHub token with project scope: " TOKEN
done

# Create the project
echo "Creating GitHub project board..."
PROJECT_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $TOKEN" \
  -X POST \
  https://api.github.com/user/projects \
  -d '{
    "name": "Arcade Board Tracker Development",
    "body": "Project board to track development of arcade-board-tracker features"
  }')

PROJECT_ID=$(echo $PROJECT_RESPONSE | jq -r '.id')
PROJECT_NUMBER=$(echo $PROJECT_RESPONSE | jq -r '.number')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "null" ]; then
  echo "Failed to create project. Response:"
  echo $PROJECT_RESPONSE
  exit 1
fi

echo "Project created with ID: $PROJECT_ID and number: $PROJECT_NUMBER"

# Create the columns
echo "Creating 'To Do' column..."
TODO_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "To Do"
  }')

TODO_COLUMN_ID=$(echo $TODO_RESPONSE | jq -r '.id')

echo "Creating 'In Progress' column..."
IN_PROGRESS_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "In Progress"
  }')

echo "Creating 'Done' column..."
DONE_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "Done"
  }')

# Add issues to the "To Do" column
ISSUE_IDS=(2 3 4 5 6 7 8 9 10)

for ISSUE_ID in "${ISSUE_IDS[@]}"; do
  echo "Adding issue #$ISSUE_ID to 'To Do' column..."
  
  ADD_RESPONSE=$(curl -s \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $TOKEN" \
    -X POST \
    "https://api.github.com/projects/columns/$TODO_COLUMN_ID/cards" \
    -d "{
      \"content_id\": $ISSUE_ID,
      \"content_type\": \"Issue\"
    }")
    
  CARD_ID=$(echo $ADD_RESPONSE | jq -r '.id')
  
  if [ -z "$CARD_ID" ] || [ "$CARD_ID" == "null" ]; then
    echo "Failed to add issue #$ISSUE_ID. Response:"
    echo $ADD_RESPONSE
  else
    echo "Issue #$ISSUE_ID added to 'To Do' column"
  fi
done

echo "Project board setup complete!"
echo "View your project at: https://github.com/0xb007ab1e/projects/$PROJECT_NUMBER"
