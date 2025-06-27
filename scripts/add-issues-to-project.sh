#!/bin/bash
# Script to add issues to an existing GitHub project board
# This script requires less permissions than creating a new board

set -e

# Replace with your project number (from the URL)
PROJECT_NUMBER=""
while [ -z "$PROJECT_NUMBER" ]; do
  read -p "Enter your GitHub project number: " PROJECT_NUMBER
done

echo "Adding issues to GitHub project #$PROJECT_NUMBER..."

# Get the project ID using the project number
PROJECT_DATA=$(gh api graphql -f query="
query {
  viewer {
    projectV2(number: $PROJECT_NUMBER) {
      id
      title
    }
  }
}")

PROJECT_ID=$(echo $PROJECT_DATA | jq -r '.data.viewer.projectV2.id')
PROJECT_TITLE=$(echo $PROJECT_DATA | jq -r '.data.viewer.projectV2.title')

echo "Working with project: $PROJECT_TITLE (ID: $PROJECT_ID)"

# Get the Status field ID and Todo option ID
FIELDS_DATA=$(gh api graphql -f query="
query {
  node(id: \"$PROJECT_ID\") {
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
}")

STATUS_FIELD_ID=$(echo $FIELDS_DATA | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .id')
TODO_OPTION_ID=$(echo $FIELDS_DATA | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Todo") | .id')

if [ -z "$STATUS_FIELD_ID" ] || [ -z "$TODO_OPTION_ID" ]; then
  echo "Could not find Status field or Todo option. Does this project use the default fields?"
  exit 1
fi

echo "Status field ID: $STATUS_FIELD_ID"
echo "Todo option ID: $TODO_OPTION_ID"

# Add all our issues to the project
ISSUE_IDS=(2 3 4 5 6 7 8 9 10)

for ISSUE_ID in "${ISSUE_IDS[@]}"; do
  echo "Adding issue #$ISSUE_ID to project..."
  
  # Get the issue node ID
  ISSUE_NODE_ID=$(gh api graphql -f query="
  query {
    repository(owner: \"0xb007ab1e\", name: \"arcade-board-tracker\") {
      issue(number: $ISSUE_ID) {
        id
      }
    }
  }" | jq -r '.data.repository.issue.id')
  
  echo "Issue #$ISSUE_ID node ID: $ISSUE_NODE_ID"
  
  # Add the issue to the project
  ADD_RESULT=$(gh api graphql -f query="
  mutation {
    addProjectV2ItemById(input: {
      projectId: \"$PROJECT_ID\"
      contentId: \"$ISSUE_NODE_ID\"
    }) {
      item {
        id
      }
    }
  }")
  
  ITEM_ID=$(echo $ADD_RESULT | jq -r '.data.addProjectV2ItemById.item.id')
  echo "Issue added as item with ID: $ITEM_ID"
  
  # Set the status to "Todo"
  gh api graphql -f query="
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: \"$PROJECT_ID\"
      itemId: \"$ITEM_ID\"
      fieldId: \"$STATUS_FIELD_ID\"
      value: {
        singleSelectOptionId: \"$TODO_OPTION_ID\"
      }
    }) {
      projectV2Item {
        id
      }
    }
  }"
  
  echo "Issue #$ISSUE_ID set to Todo status"
done

echo "All issues added to project $PROJECT_TITLE!"
echo "View your project at: https://github.com/users/0xb007ab1e/projects/$PROJECT_NUMBER"
