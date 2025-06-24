# Setting Up a Remote Git Repository

This document provides instructions for connecting this local Git repository to a remote repository on GitHub, GitLab, or another Git hosting service.

## Creating a Remote Repository

### GitHub

1. Go to [GitHub](https://github.com) and sign in
2. Click the "+" icon in the top right corner and select "New repository"
3. Enter "arcade-board-tracker" as the repository name
4. Add a description: "A web application for tracking motherboard components for arcade gaming machines"
5. Choose public or private visibility as needed
6. Do NOT initialize the repository with a README, .gitignore, or license (we already have these)
7. Click "Create repository"

### GitLab

1. Go to [GitLab](https://gitlab.com) and sign in
2. Click "New project"
3. Choose "Create blank project"
4. Enter "arcade-board-tracker" as the project name
5. Add a description: "A web application for tracking motherboard components for arcade gaming machines"
6. Choose public or private visibility as needed
7. Do NOT initialize the repository with a README (we already have one)
8. Click "Create project"

## Connecting the Local Repository to the Remote

After creating the remote repository, you'll see instructions for connecting an existing repository. Follow these steps:

1. Add the remote repository:

```bash
git remote add origin https://github.com/yourusername/arcade-board-tracker.git
# Or for GitLab
# git remote add origin https://gitlab.com/yourusername/arcade-board-tracker.git
```

2. Push the main branch to the remote repository:

```bash
git checkout main
git push -u origin main
```

3. Push the feature branch:

```bash
git checkout feature/project-foundation
git push -u origin feature/project-foundation
```

## Verifying the Setup

To verify that the remote repository is correctly configured:

```bash
# List all remotes
git remote -v

# Should show:
# origin  https://github.com/yourusername/arcade-board-tracker.git (fetch)
# origin  https://github.com/yourusername/arcade-board-tracker.git (push)
```

## Using SSH Instead of HTTPS (Optional)

If you prefer to use SSH for authentication:

1. Ensure you have an SSH key set up on your machine and added to your GitHub/GitLab account
2. Change the remote URL:

```bash
git remote set-url origin git@github.com:yourusername/arcade-board-tracker.git
# Or for GitLab
# git remote set-url origin git@gitlab.com:yourusername/arcade-board-tracker.git
```

## Setting Up Branch Protection (Recommended)

After pushing to the remote repository, it's recommended to set up branch protection rules:

### GitHub

1. Go to the repository on GitHub
2. Click "Settings" > "Branches"
3. Under "Branch protection rules", click "Add rule"
4. Enter "main" as the branch name pattern
5. Check options like "Require pull request reviews before merging" and "Require status checks to pass before merging"
6. Click "Create"

### GitLab

1. Go to the project on GitLab
2. Navigate to "Settings" > "Repository"
3. Expand the "Protected Branches" section
4. Add "main" as a protected branch
5. Configure the protection settings as needed
6. Click "Protect"

## Working with the Remote Repository

Now that the remote repository is set up, here are some common commands for working with it:

```bash
# Pull latest changes
git pull origin main

# Create and push a new feature branch
git checkout -b feature/new-feature
# Make changes...
git add .
git commit -m "feat: add new feature"
git push -u origin feature/new-feature

# Create a pull request
# This is done through the GitHub/GitLab web interface
```

Remember to follow the Git workflow outlined in the `docs/git-workflow.md` document when working with the repository.
