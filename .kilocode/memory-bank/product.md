# Product Features

## Core Capabilities
- **Multi-VLAN UDP Broadcast Relay:** Forward broadcasts across VLAN boundaries
- **SSDP Multicast Support:** Join multicast groups for Roku/SSDP discovery
- **Loop Prevention:** TTL-based mechanism with unique RELAY_IDs (1-99)
- **Environment Configuration:** Flexible ENV variable-based setup
- **Host Network Mode:** Direct VLAN interface access

## Supported Devices

### HDHomerun (Network Tuners)
- **Port:** 65001
- **Protocol:** UDP broadcast
- **Use Case:** Network tuner discovery across VLANs

### Roku (Streaming Devices)
- **Port:** 1900
- **Protocol:** SSDP multicast (239.255.255.250)
- **Use Case:** Streaming device discovery
- **Requirement:** MULTICAST_GROUP=239.255.255.250

### Kasa/TP-Link (Smart Home)
- **Ports:** 9999, 20002
- **Protocol:** UDP broadcast
- **Use Case:** Smart plug/switch discovery

## Configuration

### Required Environment Variables
- `RELAY_ID`: Unique ID (1-99) for loop prevention
- `BROADCAST_PORT`: UDP port to relay
- `INTERFACES`: Comma-separated VLAN interfaces (e.g., br0.10,br0.20)

### Optional Environment Variables
- `MULTICAST_GROUP`: Multicast IP to join (for Roku/SSDP)
- `SPOOF_SOURCE`: Override source IP (empty=preserve, 1.1.1.1=auto)
- `TARGET_OVERRIDE`: Override destination IP
- `DEBUG`: Enable verbose logging
- `TZ`: Timezone for logs

## Use Cases
- IoT device discovery across network segments
- Network tuner access from multiple VLANs
- Streaming device discovery in segmented networks
- Smart home device management across VLANs

## Technical Specifications
- **Base Image:** Alpine Linux 3.19
- **Final Size:** 8.35MB
- **User:** Non-root (relay:relay)
- **Capabilities:** NET_ADMIN, NET_RAW
- **Network Mode:** Host (required)
- **Health Check:** Process monitoring via pgrep