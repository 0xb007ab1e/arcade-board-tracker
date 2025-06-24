# Git Workflow

This document outlines the Git workflow for the Arcade Board Tracker project to ensure consistency across the development team.

## Branch Strategy

We use a feature branch workflow with the following branch types:

- `main` - The production-ready code
- `feature/*` - Feature development branches
- `bugfix/*` - Bug fix branches
- `hotfix/*` - Emergency fixes for production
- `release/*` - Preparation for a new release

## Branching Guidelines

1. **Feature Branches**
   - Create from: `main`
   - Naming convention: `feature/feature-name`
   - Merge back into: `main`
   - Description: Used for developing new features

2. **Bugfix Branches**
   - Create from: `main`
   - Naming convention: `bugfix/issue-description`
   - Merge back into: `main`
   - Description: Used for fixing non-critical bugs

3. **Hotfix Branches**
   - Create from: `main`
   - Naming convention: `hotfix/issue-description`
   - Merge back into: `main`
   - Description: Used for critical fixes that need immediate deployment

4. **Release Branches**
   - Create from: `main`
   - Naming convention: `release/version-number`
   - Merge back into: `main`
   - Description: Used for preparing a new release version

## Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

- **Type**: Describes the kind of change
  - `feat`: A new feature
  - `fix`: A bug fix
  - `docs`: Documentation changes
  - `style`: Code style changes (formatting, semicolons, etc.)
  - `refactor`: Code changes that neither fix a bug nor add a feature
  - `perf`: Performance improvements
  - `test`: Adding or updating tests
  - `chore`: Changes to the build process, tools, etc.

- **Scope**: The module/component/area affected (optional)

- **Subject**: A short description of the change
  - Use imperative, present tense: "change" not "changed" nor "changes"
  - Don't capitalize the first letter
  - No period at the end

- **Body**: Detailed description of the change (optional)

- **Footer**: Reference to issue numbers, breaking changes, etc. (optional)

### Examples

```
feat(auth): add user registration endpoint

Implement endpoint for user registration with email validation.

Closes #123
```

```
fix(board): correct file upload path handling

Fix issue where file paths were incorrectly stored in the database.

Fixes #456
```

## Pull Request Process

1. Create a branch from `main` for your feature or fix
2. Make your changes in small, logical commits
3. Push your branch to the remote repository
4. Create a Pull Request to merge your branch into `main`
5. Request reviews from team members
6. Address any feedback or issues
7. Once approved, merge the PR
8. Delete the branch after merging

## Code Review Guidelines

1. Review for functionality and correctness
2. Verify code follows project standards and style
3. Check for appropriate test coverage
4. Ensure documentation is updated
5. Look for security issues
6. Verify performance considerations
7. Provide constructive feedback

## Handling Merge Conflicts

1. Pull the latest changes from the target branch
2. Resolve conflicts locally
3. Test thoroughly after resolving conflicts
4. Commit the resolution
5. Push the updated branch

## Release Process

1. Create a release branch from `main`
2. Bump version numbers in appropriate files
3. Ensure all tests pass
4. Create a tag for the release version
5. Merge the release branch back to `main`
6. Push the tag to the remote repository

## Git Hooks (Optional)

We use the following Git hooks:

- **pre-commit**: Runs linting and formatting
- **pre-push**: Runs tests to ensure they pass before pushing

## Additional Guidelines

1. Rebase frequently to keep your branch up to date with the main branch
2. Squash commits before merging if they represent a single logical change
3. Use descriptive branch names that reflect the work being done
4. Always run tests before creating a pull request
5. Keep pull requests focused on a single feature or fix
