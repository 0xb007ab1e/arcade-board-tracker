#!/bin/bash
# Simple one-step script to create a GitHub project board
# Just run this script and provide your GitHub token when prompted

set -e

# Clear the screen for a fresh start
clear

echo "=========================================================="
echo "    GitHub Project Board Creator for Arcade Board Tracker"
echo "=========================================================="
echo
echo "This script will:"
echo "1. Create a new GitHub project board"
echo "2. Add columns: To Do, In Progress, Done"
echo "3. Add all existing issues to the To Do column"
echo
echo "It requires a GitHub token with 'repo' and 'project' scopes."
echo

# Prompt for token
read -p "Enter your GitHub token: " TOKEN

# Save token to a temporary file
TOKEN_FILE=$(mktemp)
echo "$TOKEN" > "$TOKEN_FILE"

# Login with the token
echo "Logging in with the token..."
gh auth login --with-token < "$TOKEN_FILE"
rm "$TOKEN_FILE"  # Remove the temporary file for security

# Create the classic project board
echo "Creating project board..."
PROJECT_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $TOKEN" \
  -X POST \
  https://api.github.com/repos/0xb007ab1e/arcade-board-tracker/projects \
  -d '{
    "name": "Arcade Board Tracker Development",
    "body": "Project board to track development of arcade-board-tracker features"
  }')

PROJECT_ID=$(echo $PROJECT_RESPONSE | jq -r '.id')
PROJECT_URL=$(echo $PROJECT_RESPONSE | jq -r '.html_url')

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" == "null" ]; then
  echo "Failed to create project. Response:"
  echo $PROJECT_RESPONSE
  exit 1
fi

echo "Project created: $PROJECT_URL"

# Create columns
echo "Creating columns..."
TODO_RESPONSE=$(curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "To Do"
  }')

TODO_COLUMN_ID=$(echo $TODO_RESPONSE | jq -r '.id')

curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "In Progress"
  }'

curl -s \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token $TOKEN" \
  -X POST \
  "https://api.github.com/projects/$PROJECT_ID/columns" \
  -d '{
    "name": "Done"
  }'

# Add issues to the To Do column
echo "Adding issues to the To Do column..."
ISSUE_IDS=(2 3 4 5 6 7 8 9 10)
SUCCESS_COUNT=0

for ISSUE_ID in "${ISSUE_IDS[@]}"; do
  echo -n "Adding issue #$ISSUE_ID..."
  
  ADD_RESPONSE=$(curl -s \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token $TOKEN" \
    -X POST \
    "https://api.github.com/projects/columns/$TODO_COLUMN_ID/cards" \
    -d "{
      \"content_id\": $ISSUE_ID,
      \"content_type\": \"Issue\"
    }")
    
  if echo "$ADD_RESPONSE" | jq -e '.id' > /dev/null; then
    echo " ✓"
    ((SUCCESS_COUNT++))
  else
    echo " ✗"
    echo "  Error: $(echo "$ADD_RESPONSE" | jq -r '.message')"
  fi
done

# Summary
echo
echo "=========================================================="
echo "                      SUMMARY"
echo "=========================================================="
echo "Project board created: $PROJECT_URL"
echo "Issues added to To Do: $SUCCESS_COUNT of ${#ISSUE_IDS[@]}"
echo
echo "Done! Your project board is ready."
