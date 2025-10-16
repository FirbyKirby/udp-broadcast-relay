# Project Context and Decisions

## Why udp-broadcast-relay-redux?

### Original Repository Limitations
- **No Multicast Support:** Cannot join multicast groups
- **Missing Features:** No target override, limited flexibility
- **Roku Incompatible:** SSDP requires multicast group join

### Redux Advantages
- **Multicast Support:** --multicast flag for SSDP/Roku
- **Target Override:** -t flag for advanced routing
- **Source Control:** -s flag for address manipulation
- **Complete Feature Set:** All IoT scenarios covered

### Archived Status Decision
- **Risk:** Repository archived January 2024
- **Mitigation:** Easy to fork, stable C code, 39 active forks
- **Justification:** Features unavailable elsewhere, worth the trade-off
- **Action:** Forked for maintenance

## Unraid-Specific Considerations

### Network Architecture
- **VLAN Interfaces:** Named br0.X (br0.10, br0.20, etc.)
- **Host Network Mode:** Required for multi-VLAN access
- **Interface Binding:** Direct binding to VLAN interfaces
- **No Bridge Mode:** Cannot access multiple VLANs from bridge

### Deployment Model
- **Community Apps:** Primary distribution channel
- **Template-Based:** Single XML template for all use cases
- **User-Friendly:** ENV variable configuration, no CLI needed

### Integration with Network Controllers
- **mDNS Repeater:** Many controllers (UDM Pro, Dream Router) have built-in mDNS
- **Complementary:** UDP relay handles non-mDNS protocols
- **Not Redundant:** Different protocols, different solutions

## mDNS vs UDP Broadcast Relay

### What mDNS Covers (Don't Need Relay)
- Chromecast
- AirPlay
- Newer Sonos (post-2020)
- HomeKit devices
- Network printers (Bonjour)

### What Needs UDP Relay
- HDHomerun (proprietary UDP broadcast)
- Roku (SSDP multicast, not mDNS)
- Kasa/TP-Link (proprietary UDP broadcast)
- Older IoT devices (pre-mDNS era)

## Multi-Container Architecture

### Why One Container Per Port?
- **Relay Limitation:** Each process handles ONE UDP port only
- **Not a Bug:** Fundamental design of the relay binary
- **Solution:** Multiple containers with different ports

### Example Deployment
- Container 1: HDHomerun (port 65001, RELAY_ID=1)
- Container 2: Roku (port 1900, RELAY_ID=2, multicast)
- Container 3: Kasa (port 9999, RELAY_ID=3)

### RELAY_ID Uniqueness
- **Critical:** Each container MUST have unique ID
- **Reason:** All share host network namespace
- **Consequence:** Duplicate IDs cause relay loops
- **Range:** 1-99 available

## Recent Changes

### CI/CD Pipeline Implementation
- **Status:** Complete and verified
- **Components:** Test workflow, publish workflow, enhanced test script
- **Security:** Trivy vulnerability scanning integrated
- **Triggers:** PRs, master pushes, version tags, manual dispatch
- **Behavior:** Tests before publish, multi-arch builds, Docker Hub publishing
- **Verification:** All configurations correct, no critical issues

## Documentation Organization

### Root Level
- **README.md:** Quick start, immediate value
- **Essential Files:** Dockerfile, entrypoint, compose

### docs/ Directory
- **Detailed Guides:** Configuration, examples, setup
- **User-Focused:** Step-by-step instructions
- **Cross-Referenced:** Easy navigation between docs

### docs/analysis/
- **Technical Research:** Repository comparison, protocol analysis
- **Decision Documentation:** Why choices were made
- **Future Reference:** Preserve reasoning

### templates/
- **Deployment Assets:** Unraid template
- **Distribution:** Ready for Community Apps submission