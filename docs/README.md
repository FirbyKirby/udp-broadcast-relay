# Documentation Index

This directory contains all documentation for the UDP Broadcast Relay Redux project.

## Quick Start

- **[README.md](../README.md)** - Main project overview, quick start guide, and architecture
- **[CONFIGURATION.md](CONFIGURATION.md)** - Complete environment variable reference
- **[EXAMPLES.md](EXAMPLES.md)** - Detailed setup examples for different IoT devices

## Setup Guides

- **[UNRAID_SETUP.md](UNRAID_SETUP.md)** - Step-by-step Unraid installation and configuration
- **[LOOP_PREVENTION.md](LOOP_PREVENTION.md)** - Understanding RELAY_ID and loop prevention

## Analysis Documents

<!-- Analysis documents moved to separate repository or archived -->

## Usage Notes

- **[usage-notes/README.md](usage-notes/README.md)** - General usage notes and tips
- **[usage-notes/pfsense-config/](usage-notes/pfsense-config/)** - pfSense-specific configuration examples (with scripts and config files)

## Templates

- **[../templates/unraid-template.xml](../templates/unraid-template.xml)** - Unraid Docker template for easy installation

## Support

For issues or questions:
- Check the troubleshooting sections in the relevant guides
- Review debug logging examples
- Ensure unique RELAY_ID values across containers
- Verify network interface names and capabilities
## CI/CD workflows

Three workflow scenarios are implemented:

- Scenario 1 — PRs merging to main
  - Automated validation runs on the PR via .github/workflows/test.yml.
  - When the PR is merged to main, CI does not re-run tests and does not publish images.

- Scenario 2 — Version tags on main (v*)
  - Pushing a version tag from main triggers the full pipeline in .github/workflows/docker-publish.yml:
    - test → build → push → sync (Docker Hub README) → release (GitHub)

- Scenario 3 — Manual workflow dispatch
  - You may run .github/workflows/test.yml or .github/workflows/docker-publish.yml independently from the Actions tab; no automatic chaining occurs.

Manual triggers

- GitHub UI
  - Actions → select a workflow → Run workflow

- GitHub CLI (optional)
  ```bash
  # Run tests manually
  gh workflow run .github/workflows/test.yml

  # Run publish pipeline manually (no tag required)
  gh workflow run .github/workflows/docker-publish.yml
  ```

References
- Developer guide: docs/DEVELOPER_GUIDE.md
- Branch strategy: docs/BRANCH_STRATEGY.md
- Dependency-chain design: docs/WORKFLOW_DEPENDENCY_CHAIN_DESIGN.md