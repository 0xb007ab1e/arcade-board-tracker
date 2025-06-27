#!/bin/bash
# Script to create a GitHub project board and add issues to it
# Requires a GitHub token with 'project' and 'repo' scopes

set -e

# Step 1: Create the project board
echo "Creating GitHub project board..."
PROJECT_DATA=$(gh api graphql -f query='
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
}')

# Extract project ID and number
PROJECT_ID=$(echo $PROJECT_DATA | jq -r '.data.createProjectV2.projectV2.id')
PROJECT_NUMBER=$(echo $PROJECT_DATA | jq -r '.data.createProjectV2.projectV2.number')

echo "Project created with ID: $PROJECT_ID and number: $PROJECT_NUMBER"

# Step 2: Get the ID of the "Todo" status field
echo "Getting field IDs..."
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

# Extract status field ID and "Todo" option ID
STATUS_FIELD_ID=$(echo $FIELDS_DATA | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .id')
TODO_OPTION_ID=$(echo $FIELDS_DATA | jq -r '.data.node.fields.nodes[] | select(.name == "Status") | .options[] | select(.name == "Todo") | .id')

echo "Status field ID: $STATUS_FIELD_ID"
echo "Todo option ID: $TODO_OPTION_ID"

# Step 3: Add issues to the project and set them to "Todo"
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

echo "Project board setup complete!"
echo "View your project at: https://github.com/0xb007ab1e/arcade-board-tracker/projects/$PROJECT_NUMBER"
