# Implementation Checklist: Two-Branch Strategy Activation

This checklist provides a step-by-step guide for activating the two-branch strategy (main and dev) in the udp-broadcast-relay repository. This document should be followed by the repository administrator to ensure a smooth transition.

## Prerequisites Check
- [ ] CI/CD workflows have been updated (test.yml and docker-publish.yml)
- [ ] Documentation has been created (BRANCH_STRATEGY.md, DEVELOPER_GUIDE.md)
- [ ] Repository administrator has reviewed all changes

## Step 1: Create and Push the Dev Branch
Create the dev branch from the current main branch and push it to the remote repository.

```bash
# Create dev branch from current main
git checkout -b dev
git push -u origin dev
```

- [ ] Execute the commands above
- [ ] Verify the dev branch appears in the GitHub repository

## Step 2: Configure GitHub Branch Protection Rules for Main
Set up branch protection rules for the main branch to enforce code review and prevent direct pushes.

- [ ] Navigate to repository Settings > Branches
- [ ] Add branch protection rule for `main` branch
- [ ] Enable "Require pull request reviews before merging"
- [ ] Enable "Require status checks to pass before merging"
  - Add required status check: **Test** (only this workflow, not docker-publish)
- [ ] Enable "Require branches to be up to date before merging"
- [ ] Enable "Do not allow bypassing the above settings" to enforce for administrators
- [ ] Save the branch protection rule

## Step 3: Verify the Setup Works
Test each workflow trigger to ensure the CI/CD pipeline functions correctly.

- [ ] Push a test commit to dev branch and verify test workflow triggers
- [ ] Create a pull request from dev to main and verify required checks run
- [ ] Merge the pull request and verify no workflows trigger on main
- [ ] Create and push a version tag (for example v0.0.0-test) and verify the full pipeline runs in [.github/workflows/docker-publish.yml](.github/workflows/docker-publish.yml): test → build → push → sync → release

## Step 4: Begin Using the Workflow
Start following the two-branch development process.

- [ ] All new development work should be done on the dev branch
- [ ] Use pull requests to merge changes from dev to main
- [ ] Ensure merges to main do not trigger CI; publish only via version tags (v*) from main

## Verification Steps
Confirm the two-branch strategy is fully operational:

- [ ] Verify both main and dev branches exist in the repository
- [ ] Pushing to dev triggers the test workflow
- [ ] Creating a pull request from dev to main runs required checks
- [ ] Merging the PR to main triggers no workflows (tests/publish are skipped)
- [ ] Pushing a version tag v* triggers [.github/workflows/docker-publish.yml](.github/workflows/docker-publish.yml) with dependency chain: test → build → push → sync → release
- [ ] Branch protection rules prevent direct pushes to main (attempt a direct push to confirm it's blocked)

Once all steps are completed and verified, the two-branch strategy is active and ready for use.