# UDP Broadcast Relay Redux - Docker

A Dockerized UDP broadcast relay that enables IoT device discovery across VLANs. Works alongside any network controller that already handles mDNS repeater functionality (for example, UDM Pro, UniFi Dream Router).

- Solves: UDP broadcast discovery does not traverse VLAN boundaries by default
- Fits: Home and lab networks where discovery must cross IoT, Media, Guest, and other segments

> Warning
> - Each container instance must use a unique RELAY_ID between 1 and 99 to prevent loops.
> - Each container relays to all configured interfaces. For selective paths, run multiple containers with different interface sets.

## Overview

Many IoT ecosystems depend on UDP-based discovery. This container listens on the specified UDP port and relays traffic between the VLAN interfaces you list.

Key features:
- Multi-VLAN UDP relay with host networking
- Supports HDHomerun, Roku/SSDP, Kasa, and similar UDP-discovery devices
- Compatible with controllers that repeat mDNS; this container covers non‑mDNS UDP discovery
- Environment-variable driven configuration
- Built-in health check

## Quick start

```bash
docker run -d \
  --name udp-relay-hdhomerun \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e RELAY_ID=1 \
  -e BROADCAST_PORT=65001 \
  -e INTERFACES=br0.10,br0.20 \
  your-registry/udp-broadcast-relay-redux:latest
```

Notes:
- On Unraid, VLAN interfaces typically appear as br0.X (for example, br0.10).
- For Roku/SSDP on port 1900, also set MULTICAST_GROUP=239.255.255.250.

## Architecture

This container bridges UDP discovery across VLANs. For selective discovery paths, run one container per device family or per path.

```
VLAN 10 (IoT)          VLAN 20 (Media)
     |                        |
     |  UDP Broadcast         |
     |------------------------>|
     |                        |
     v                        v
HDHomerun Tuner          Media Server
```

> Tip
> Use multiple containers when you need fine-grained control. Example: one container for VLAN 10 ↔ 20, another for VLAN 20 ↔ 30.

Relationship to mDNS:
- mDNS repeaters handle multicast DNS–based discovery like Chromecast, AirPlay, HomeKit, Sonos (newer models).
- This relay focuses on non‑mDNS UDP discovery such as HDHomerun, Roku/SSDP, and Kasa.

## Common use cases

- HDHomerun tuner discovery on 65001 for Plex, Emby, etc.
- Roku discovery via SSDP on 1900 with multicast group 239.255.255.250
- TP‑Link Kasa discovery on 9999 and 20002
- Other UDP discovery protocols that must traverse VLANs

## Network requirements

- Host network mode to expose all host VLAN interfaces to the container
- Linux capabilities: NET_ADMIN and NET_RAW
- Unique RELAY_ID per container (1–99) to enable TTL-based loop prevention

## Documentation

- Configuration reference: [docs/CONFIGURATION.md](docs/CONFIGURATION.md)
- Examples and patterns: [docs/EXAMPLES.md](docs/EXAMPLES.md)
- Unraid setup guide: [docs/UNRAID_SETUP.md](docs/UNRAID_SETUP.md)
- Loop prevention details: [docs/LOOP_PREVENTION.md](docs/LOOP_PREVENTION.md)

## Docker Compose

See the complete multi-container example in [docker-compose.yml](docker-compose.yml).

## Troubleshooting essentials

- If discovery fails, confirm interface names exist and are up, RELAY_IDs are unique, and the correct port is configured.
- For SSDP, ensure MULTICAST_GROUP=239.255.255.250 is set on the Roku relay.
- Enable DEBUG=true temporarily and review logs.

## Contributing

This container packages the upstream tool: udp-broadcast-relay-redux. Contributions and issues are welcome: https://github.com/udp-redux/udp-broadcast-relay-redux

## License

GPL-2.0 (same as upstream udp-broadcast-relay-redux)
