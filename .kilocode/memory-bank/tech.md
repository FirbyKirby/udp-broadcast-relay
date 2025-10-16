# Technical Implementation

## Repository Choice: udp-broadcast-relay-redux

### Selection Rationale
- **Multicast Support:** Required for Roku/SSDP (--multicast flag)
- **Target Override:** Advanced routing with -t flag
- **Source Spoofing:** Flexible source address handling with -s flag
- **Feature Complete:** All necessary capabilities for IoT scenarios
- **Archived Status:** Acceptable - stable, easy to fork, 39 community forks

### Key Features
- `--multicast <IP>`: Join multicast group
- `-t <IP>`: Override target address
- `-s <IP>`: Override source address (1.1.1.1=auto-detect)
- `--id <N>`: Relay ID for loop prevention
- `--port <N>`: UDP port to relay
- `--dev <IF>`: Network interface (multiple allowed)

## Docker Architecture

### Multi-Stage Build
**Stage 1 (Builder):**
- Base: Alpine Linux 3.19
- Tools: gcc, make, musl-dev
- Action: Compile main.c to binary

**Stage 2 (Runtime):**
- Base: Alpine Linux 3.19 (minimal)
- Size: 8.35MB final image
- Contents: Binary only, no build tools
- User: relay:relay (non-root, PUID/PGID mapped)
- Capabilities: cap_net_admin,cap_net_raw+ep on binary

### Security Implementation
- **PUID/PGID Support:** Runtime user/group mapping with shadow package
- **Default UID/GID:** 1000:1000 (LinuxServer.io pattern)
- **Runtime Mapping:** Intelligent GID handling avoids Alpine GID 100 conflict
- **Shadow Package:** Provides usermod/groupmod tools for user mapping
- **Minimal Capabilities:** Only NET_ADMIN and NET_RAW (cap_net_admin,cap_net_raw+ep)
- **No Privileged Mode:** Not required
- **File Capabilities:** Set on binary, not shell
- **Health Check:** pgrep monitoring

## Network Configuration

### Host Network Mode
- **Requirement:** Direct VLAN interface access
- **Implication:** All containers share network namespace
- **Benefit:** Can bind to specific VLAN interfaces (br0.X)

### VLAN Interface Access
- **Unraid Naming:** br0.10, br0.20, br0.30, etc.
- **Direct Binding:** Relay binds to specified interfaces
- **Broadcast Behavior:** Relays to ALL configured interfaces per container

### Capabilities
- **NET_ADMIN:** Required for network interface manipulation
- **NET_RAW:** Required for raw socket access and packet modification

## Loop Prevention Mechanism

### TTL-Based System
- **Marking:** Each relay sets TTL = RELAY_ID + 64
- **Detection:** Relay checks incoming packet TTL
- **Action:** Drop if TTL matches another relay's ID
- **Requirement:** Unique RELAY_ID per container (1-99)

### Why It's Critical
- All containers use host network mode
- All see ALL packets on ALL interfaces
- Without unique IDs, infinite relay loops occur
- TTL mechanism prevents echo amplification

## File Structure

```
/
├── Dockerfile                 # Multi-stage build
├── entrypoint.sh             # ENV to CLI converter
├── docker-compose.yml        # Multi-container examples
├── build-and-test.sh         # Automated testing
├── README.md                 # Quick start
├── docs/
│   ├── CONFIGURATION.md      # ENV variable reference
│   ├── EXAMPLES.md           # Device-specific configs
│   ├── UNRAID_SETUP.md       # Installation guide
│   ├── LOOP_PREVENTION.md    # Technical details
│   ├── README.md             # Documentation index
│   ├── analysis/             # Technical research
│   └── usage-notes/          # Platform-specific notes
├── templates/
│   └── unraid-template.xml   # Unraid Community Apps
└── TEST_RESULTS.md           # Validation results
```

## CI/CD Tooling and Security Scanning

### GitHub Actions Workflows
- **Test Workflow:** [.github/workflows/test.yml](.github/workflows/test.yml) - Comprehensive testing before publishing
- **Publish Workflow:** [.github/workflows/docker-publish.yml](.github/workflows/docker-publish.yml) - Multi-arch builds and publishing
- **Triggers:** PRs, master pushes, version tags (v*), manual dispatch
- **Permissions:** contents:read, security-events:write, packages:write
- **Concurrency:** Per-ref with cancel-in-progress
- **Cache Strategy:** GitHub Actions cache (type=gha)

### Security Scanning
- **Tool:** Trivy vulnerability scanner
- **Version:** 0.28.0 (pinned)
- **Modes:** Informational (test), blocking (publish for CRITICAL/HIGH)
- **Reporting:** SARIF uploads to GitHub Security tab
- **Retention:** Human-readable reports (30 days)
- **Coverage:** Both test and published images

### Build Optimization
- **Multi-stage:** Builder/runtime separation
- **Single-arch Test:** linux/amd64 for faster testing
- **Multi-arch Publish:** linux/amd64, linux/arm64
- **Conditional Builds:** Skip if image exists in CI
- **Cache Layers:** GitHub Actions cache for dependencies

## Critical Fixes Applied
1. **entrypoint.sh:** Removed invalid --foreground flag
2. **Dockerfile:** Fixed capability target (binary vs shell)
3. **entrypoint.sh:** Fixed POSIX shell compatibility (IFS loop)
4. **docker-compose.yml:** Updated to Compose v2 syntax