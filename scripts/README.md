# GitHub Project Board Scripts

This directory contains scripts to help set up and manage GitHub project boards for the Arcade Board Tracker project.

## Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- `jq` command-line JSON processor installed
- A GitHub token with appropriate scopes:
  - For creating projects: `project` scope
  - For adding issues to existing projects: `repo` scope

## Available Scripts

### 1. Add Issues to Existing Project (`add-issues-to-project.sh`)

**Purpose**: Adds all the Arcade Board Tracker issues to an existing GitHub project board.

**Usage**:
```bash
./add-issues-to-project.sh
```

This script will:
1. Prompt you for your GitHub project number (found in the URL)
2. Find the "To Do" status in the project
3. Add all Arcade Board Tracker issues to the project
4. Set all issues to "To Do" status

**Note**: This script works with the new GitHub Projects experience (Projects V2).

### 2. Create Project Board with curl (`create-project-with-curl.sh`)

**Purpose**: Creates a new GitHub project board with curl commands (alternative to using GitHub CLI).

**Usage**:
```bash
./create-project-with-curl.sh
```

This script will:
1. Prompt you for a GitHub token with the `project` scope
2. Create a new GitHub project board with "To Do", "In Progress", and "Done" columns
3. Add all Arcade Board Tracker issues to the "To Do" column

**Note**: This script uses the classic GitHub Projects experience.

### 3. Create Project Board with GitHub CLI (`setup-project-board.sh`)

**Purpose**: Creates a new GitHub project board using the GitHub CLI (requires the `project` scope).

**Usage**:
```bash
./setup-project-board.sh
```

This script will:
1. Create a new GitHub Projects V2 board
2. Add all Arcade Board Tracker issues to the project
3. Set all issues to "To Do" status

**Note**: Your GitHub token needs the `project` scope for this script to work.

## Getting a Token with Project Scope

To get a GitHub token with the necessary scopes:

1. Go to your GitHub account settings
2. Navigate to Developer settings > Personal access tokens > Tokens (classic)
3. Click "Generate new token" > "Generate new token (classic)"
4. Give your token a name, e.g., "Arcade Board Tracker Project Management"
5. Select the following scopes:
   - `repo` (all)
   - `project` (all)
6. Click "Generate token"
7. Copy the token and use it with these scripts

## Troubleshooting

If you encounter permission errors, make sure your token has the required scopes. The error message will typically indicate which scope is missing.

For the GitHub CLI, you can check your current authentication with:
```bash
gh auth status
```

To login with a new token that has the required scopes:
```bash
gh auth login --with-token
```
