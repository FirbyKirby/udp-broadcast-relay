# Configuration Examples

This document provides detailed examples for setting up UDP Broadcast Relay Redux for different IoT devices and use cases.

## Key Concepts

> Important
> - Each container broadcasts to ALL configured VLANs in INTERFACES.
> - For selective paths, run separate containers with different INTERFACES.
> - Each container must have a unique RELAY_ID (1–99) to prevent loops. See [docs/LOOP_PREVENTION.md](docs/LOOP_PREVENTION.md).
> - For SSDP/Roku on port 1900, set MULTICAST_GROUP=239.255.255.250. See [docs/CONFIGURATION.md](docs/CONFIGURATION.md).

### Before you begin
- Confirm your VLAN interface names (for example, br0.10, br0.20). See naming examples below.
- Decide per‑protocol containers: one for HDHomerun (65001), one for Roku/SSDP (1900), one or two for Kasa (9999, 20002), etc.
- Ensure Host network mode and capabilities NET_ADMIN and NET_RAW (examples below already set these).
- If using Unraid, follow the step‑by‑step template guide in [docs/UNRAID_SETUP.md](docs/UNRAID_SETUP.md).

## HDHomerun Tuner Discovery

HDHomerun network tuners use UDP port 65001 for device discovery.

### Docker Run
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

### Docker Compose
```yaml
version: '3.8'
services:
  hdhomerun-relay:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=1
      - BROADCAST_PORT=65001
      - INTERFACES=br0.10,br0.20
    restart: unless-stopped
```

### Unraid Template Variables
```
RELAY_ID=1
BROADCAST_PORT=65001
INTERFACES=br0.10,br0.20
```

## Roku Device Discovery

Roku streaming devices use SSDP (Simple Service Discovery Protocol) on port 1900 with multicast group 239.255.255.250.

### Docker Run
```bash
docker run -d \
  --name udp-relay-roku \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e RELAY_ID=2 \
  -e BROADCAST_PORT=1900 \
  -e INTERFACES=br0.10,br0.20 \
  -e MULTICAST_GROUP=239.255.255.250 \
  your-registry/udp-broadcast-relay-redux:latest
```

### Docker Compose
```yaml
version: '3.8'
services:
  roku-relay:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=2
      - BROADCAST_PORT=1900
      - INTERFACES=br0.10,br0.20
      - MULTICAST_GROUP=239.255.255.250
    restart: unless-stopped
```

## Kasa Smart Home Devices

TP-Link Kasa smart plugs, switches, and bulbs use UDP ports 9999 and 20002 for discovery.

### Docker Run (Port 9999)
```bash
docker run -d \
  --name udp-relay-kasa-9999 \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e RELAY_ID=3 \
  -e BROADCAST_PORT=9999 \
  -e INTERFACES=br0.10,br0.20 \
  your-registry/udp-broadcast-relay-redux:latest
```

### Docker Run (Port 20002)
```bash
docker run -d \
  --name udp-relay-kasa-20002 \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e RELAY_ID=4 \
  -e BROADCAST_PORT=20002 \
  -e INTERFACES=br0.10,br0.20 \
  your-registry/udp-broadcast-relay-redux:latest
```

## Multiple Container Setup

For complex networks with multiple device types, run separate containers for each protocol.

### Docker Compose (Complete Setup)
```yaml
version: '3.8'
services:
  # HDHomerun tuner discovery
  hdhomerun-relay:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=1
      - BROADCAST_PORT=65001
      - INTERFACES=br0.10,br0.20,br0.30
    restart: unless-stopped

  # Roku SSDP discovery
  roku-relay:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=2
      - BROADCAST_PORT=1900
      - INTERFACES=br0.10,br0.20,br0.30
      - MULTICAST_GROUP=239.255.255.250
    restart: unless-stopped

  # Kasa smart home (port 9999)
  kasa-relay-9999:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=3
      - BROADCAST_PORT=9999
      - INTERFACES=br0.10,br0.20,br0.30
    restart: unless-stopped

  # Kasa smart home (port 20002)
  kasa-relay-20002:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=4
      - BROADCAST_PORT=20002
      - INTERFACES=br0.10,br0.20,br0.30
    restart: unless-stopped
```

## Selective VLAN Broadcasting

**Important:** Each container broadcasts to ALL configured VLANs. For selective broadcasting, use separate containers.

### Example: IoT VLAN ↔ Media VLAN Only
```yaml
version: '3.8'
services:
  iot-to-media-relay:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=1
      - BROADCAST_PORT=65001
      - INTERFACES=br0.10,br0.20  # IoT VLAN 10 ↔ Media VLAN 20
    restart: unless-stopped

  media-to-guest-relay:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=2
      - BROADCAST_PORT=65001
      - INTERFACES=br0.20,br0.30  # Media VLAN 20 ↔ Guest VLAN 30
    restart: unless-stopped
```

### Example: Isolated IoT Segments
```yaml
version: '3.8'
services:
  # Kitchen IoT devices
  kitchen-relay:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=1
      - BROADCAST_PORT=9999
      - INTERFACES=br0.10,br0.20  # Kitchen VLAN 10 ↔ Main VLAN 20
    restart: unless-stopped

  # Bedroom IoT devices
  bedroom-relay:
    image: your-registry/udp-broadcast-relay-redux:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - RELAY_ID=2
      - BROADCAST_PORT=9999
      - INTERFACES=br0.15,br0.20  # Bedroom VLAN 15 ↔ Main VLAN 20
    restart: unless-stopped
```

## Advanced configuration examples

### Forcing broadcast on egress (TARGET_OVERRIDE)
Some protocols work best when forwarded to the broadcast address of the destination VLAN. To force broadcast, set TARGET_OVERRIDE=255.255.255.255.

```bash
docker run -d \
  --name udp-relay-force-broadcast \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e RELAY_ID=5 \
  -e BROADCAST_PORT=65001 \
  -e INTERFACES=br0.10,br0.20 \
  -e TARGET_OVERRIDE=255.255.255.255 \
  your-registry/udp-broadcast-relay-redux:latest
```

- Without TARGET_OVERRIDE, the relay preserves the original destination, and when it detects a broadcast destination on ingress it automatically rewrites to the egress interface broadcast address.
- With TARGET_OVERRIDE=255.255.255.255, you explicitly broadcast on egress regardless of the original destination.

### Spoofing the source IP (SPOOF_SOURCE)
In rare cases, you may need responses to target the VLAN gateway/interface address instead of the original sender.

```bash
# Use the egress interface IP and keep the same destination port
docker run -d \
  --name udp-relay-spoof-iface-port \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e RELAY_ID=6 \
  -e BROADCAST_PORT=9999 \
  -e INTERFACES=br0.10,br0.20 \
  -e SPOOF_SOURCE=1.1.1.1 \
  your-registry/udp-broadcast-relay-redux:latest

# Use the egress interface IP but preserve the original source port
docker run -d \
  --name udp-relay-spoof-iface-srcport \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e RELAY_ID=7 \
  -e BROADCAST_PORT=9999 \
  -e INTERFACES=br0.10,br0.20 \
  -e SPOOF_SOURCE=1.1.1.2 \
  your-registry/udp-broadcast-relay-redux:latest
```

- SPOOF_SOURCE unset: the original sender IP is preserved.
- SPOOF_SOURCE=1.1.1.1: use egress interface IP and the broadcast port.
- SPOOF_SOURCE=1.1.1.2: use egress interface IP and preserve original source port.
- A concrete IP (for example, 192.168.20.10) sets that exact source IP.

See details in [docs/CONFIGURATION.md](docs/CONFIGURATION.md#spoof_source).

## Debug configuration

Enable debug logging to troubleshoot issues:

```bash
docker run -d \
  --name udp-relay-debug \
  --network host \
  --cap-add NET_ADMIN \
  --cap-add NET_RAW \
  -e RELAY_ID=1 \
  -e BROADCAST_PORT=65001 \
  -e INTERFACES=br0.10,br0.20 \
  -e DEBUG=true \
  your-registry/udp-broadcast-relay-redux:latest
```

## Interface Naming Examples

Different systems use different interface naming conventions:

### Unraid
```
INTERFACES=br0.10,br0.20,br0.30
```

### pfSense/OPNsense
```
INTERFACES=vlan10,vlan20,vlan30
```

### Ubiquiti UDM Pro
```
INTERFACES=br0.10,br0.20,br0.30
```

### Generic Linux
```
INTERFACES=eth0.10,eth0.20,eth0.30
# or
INTERFACES=vlan10,vlan20,vlan30
```

## Health check and status

The image includes a basic health check for the relay process.

```bash
# Check health for all relay containers
docker ps --filter "name=udp-relay"

# Compose workflow
docker compose ps
docker compose logs -f hdhomerun-relay
docker compose logs -f roku-relay

# Follow logs for a single container
docker logs -f udp-relay-hdhomerun
```

If a health check fails, Docker will mark the container as unhealthy. Use DEBUG=true temporarily to trace packet flow and verify IDs per [docs/LOOP_PREVENTION.md](docs/LOOP_PREVENTION.md).

## Troubleshooting

### Common Issues

1. **Container won't start:** Check that all required environment variables are set
2. **No broadcasts relayed:** Verify interface names exist and are up
3. **Broadcast loops:** Ensure each container has a unique RELAY_ID
4. **Permission denied:** Ensure NET_ADMIN and NET_RAW capabilities are granted

### Debug commands

```bash
# List interfaces on the host
ip addr show
ip link show

# Monitor UDP traffic on a specific port using a diagnostics container
docker run --rm --net=host nicolaka/netshoot tcpdump -i any udp port 65001 -v

# For SSDP (Roku), include multicast
docker run --rm --net=host nicolaka/netshoot tcpdump -i any udp port 1900 and host 239.255.255.250 -v
```

Tip:
- Use unique RELAY_IDs and avoid overlapping INTERFACES when testing multiple containers. See [docs/LOOP_PREVENTION.md](docs/LOOP_PREVENTION.md).
- For Unraid specifics and template usage, see [docs/UNRAID_SETUP.md](docs/UNRAID_SETUP.md).

### Log Analysis

Debug logs show packet flow:
```
[2023-10-14 14:30:15] <- [192.168.10.100:65001 -> 255.255.255.255:65001 (iface=3 len=50 ttl=64)
[2023-10-14 14:30:15] -> [192.168.10.100:65001 -> 192.168.20.255:65001 (iface=4)
```

This shows a broadcast received on interface 3 (VLAN 10) being relayed to interface 4 (VLAN 20).