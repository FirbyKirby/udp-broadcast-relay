# Configuration Reference

This document provides a complete reference for all environment variables used to configure the UDP Broadcast Relay Redux container.

## Environment Variables

> At a glance
> - Required: RELAY_ID, BROADCAST_PORT, INTERFACES
> - For SSDP and Roku on port 1900, set MULTICAST_GROUP=239.255.255.250
> - Each container relays to all listed INTERFACES
> - Each container must have a unique RELAY_ID (1-99)

### Required Variables

#### `RELAY_ID`
- **Type:** Integer (1-99)
- **Required:** Yes
- **Description:** Unique identifier for loop prevention. Each container instance must have a different ID.
- **Example:** `1`
- **Notes:** Used in TTL-based loop prevention mechanism.

#### `BROADCAST_PORT`
- **Type:** Integer (1-65535)
- **Required:** Yes
- **Description:** UDP port to listen for and relay broadcasts on.
- **Example:** `65001` (HDHomerun), `1900` (SSDP/Roku), `9999` (Kasa)
- **Notes:** Different IoT devices use different discovery ports.

#### `INTERFACES`
- **Type:** Comma-separated string
- **Required:** Yes
- **Description:** Network interfaces to relay broadcasts between. Each interface should be a VLAN interface (e.g., br0.10).
- **Example:** `br0.10,br0.20,br0.30`
- **Notes:** Broadcasts are sent to ALL listed interfaces. For selective routing, use separate containers.

### Optional Variables

#### `MULTICAST_GROUP`
- **Type:** IP Address
- **Required:** No
- **Description:** Multicast group IP to join for multicast-based discovery protocols.
- **Example:** `239.255.255.250` (SSDP multicast)
- **Default:** Empty (broadcast-only mode)
- **Notes:**
  - Required for SSDP/Roku on port 1900
  - Used for protocols like SSDP that use multicast in addition to broadcast
  - See examples in [docs/EXAMPLES.md](docs/EXAMPLES.md)

#### `SPOOF_SOURCE`
- **Type:** IP Address or Special Value
- **Required:** No
- **Description:** Override the source IP address of relayed packets.
- **Example:** `1.1.1.1` (use outgoing interface address), `192.168.1.100` (specific IP)
- **Default:** Empty (preserve original source IP)
- **Notes:**
  - Empty: Use original sender's IP address
  - `1.1.1.1`: Use the IP address of the outgoing interface
  - `1.1.1.2`: Use the IP address of the outgoing interface and source port
  - Any other IP: Use that specific IP address

#### `TARGET_OVERRIDE`
- **Type:** IP Address or Special Value
- **Required:** No
- **Description:** Override the destination IP address of relayed packets.
- **Example:** `255.255.255.255` (force broadcast), `239.255.255.250` (multicast)
- **Default:** Empty (preserve original destination)
- **Notes:**
  - Empty: Use original destination IP
  - `255.255.255.255`: Force broadcast to interface broadcast address

#### `DEBUG`
- **Type:** Boolean (`true`/`false`)
- **Required:** No
- **Description:** Enable verbose debug logging.
- **Example:** `true`
- **Default:** `false`
- **Notes:** Debug output is written to container logs.

#### `TZ`
- **Type:** Timezone string
- **Required:** No
- **Description:** Timezone for log timestamps.
- **Example:** `America/Chicago`, `Europe/London`, `UTC`
- **Default:** `America/Chicago`
- **Notes:** Uses standard timezone identifiers.

#### `PUID`
- **Type:** Integer (numeric user ID)
- **Required:** No
- **Description:** Run the process as this host user ID for proper file ownership on mounted volumes (LinuxServer.io pattern).
- **Default:** `99` (Unraid's "nobody" user)
- **Notes:** Set to your host user ID if you are not on Unraid or if your shares are owned by a different user.

#### `PGID`
- **Type:** Integer (numeric group ID)
- **Required:** No
- **Description:** Run the process with this host group ID for proper file ownership on mounted volumes (LinuxServer.io pattern).
- **Default:** `100` (Unraid's "users" group)
- **Notes:** Set to your host group ID if you are not on Unraid or if your shares are owned by a different group.

### User and Group Mapping (LinuxServer.io pattern)

This image supports mapping the container process to a specific host user and group via PUID and PGID. This ensures files created by the container on mounted paths are owned by the expected account on the host.

- Defaults (Unraid-friendly):
  - PUID: `99` (user: nobody)
  - PGID: `100` (group: users)
- When to change:
  - You are not running Unraid (common host defaults are `1000:1000` for the first user)
  - Your mounted path (bind or volume) is owned by another UID:GID and you want new files to match that ownership
  - You see "permission denied" errors reading/writing mounted files

Find your UID/GID on the host:
```bash
id -u   # prints your numeric user ID (e.g., 1000)
id -g   # prints your numeric group ID (e.g., 1000)
id      # prints full identity (uid, gid, groups)
```

Examples:
- docker run
  ```bash
  docker run -d \
    --name udp-relay-hdhomerun \
    --network host \
    --cap-add NET_ADMIN \
    --cap-add NET_RAW \
    -e RELAY_ID=1 \
    -e BROADCAST_PORT=65001 \
    -e INTERFACES=br0.10,br0.20 \
    -e PUID=1000 \
    -e PGID=1000 \
    your-registry/udp-broadcast-relay-redux:latest
  ```
- docker-compose excerpt
  ```yaml
  services:
    udp-relay-hdhomerun:
      image: your-registry/udp-broadcast-relay-redux:latest
      network_mode: host
      cap_add: [ "NET_ADMIN", "NET_RAW" ]
      environment:
        RELAY_ID: 1
        BROADCAST_PORT: 65001
        INTERFACES: br0.10,br0.20
        PUID: 1000
        PGID: 1000
  ```

Troubleshooting file permissions:
- Symptom: "permission denied" when accessing a mounted path
- Remedies:
  - Set PUID/PGID to the owner of the mount path (check with `ls -l` on the host)
  - Or adjust host ownership: `sudo chown -R <uid>:<gid> /path/to/mount`
  - Confirm the mount path exists and is writable by the chosen UID/GID

See also:
- Unraid defaults and guidance: [docs/UNRAID_SETUP.md](docs/UNRAID_SETUP.md)
- Overview in README: [README.md](README.md)

## Configuration Examples

### HDHomerun Tuner Discovery
```bash
RELAY_ID=1
BROADCAST_PORT=65001
INTERFACES=br0.10,br0.20
```

### Roku SSDP Discovery
```bash
RELAY_ID=2
BROADCAST_PORT=1900
INTERFACES=br0.10,br0.20
MULTICAST_GROUP=239.255.255.250
```

### Kasa Smart Home
```bash
RELAY_ID=3
BROADCAST_PORT=9999
INTERFACES=br0.10,br0.20
```

### Debug Mode
```bash
RELAY_ID=1
BROADCAST_PORT=65001
INTERFACES=br0.10,br0.20
DEBUG=true
```

## Network Interface Naming

Interface names typically follow these patterns:
- **Unraid:** `br0.10`, `br0.20` (where br0 is the main bridge, .10/.20 are VLAN IDs)
- **pfSense/OPNsense:** `vlan10`, `vlan20`
- **Ubiquiti UDM:** `br0.10`, `br0.20`
- **Generic Linux:** `eth0.10`, `eth0.20` or `vlan10`, `vlan20`

Use `ip addr` or `ifconfig` to list available interfaces on your system.

## Loop Prevention

The `RELAY_ID` is crucial for preventing broadcast loops in host network mode. Each relay instance modifies the TTL (Time To Live) of packets it forwards by adding its ID + 64. When a relay receives a packet with a TTL it previously set, it ignores the packet.

**Important:** Never run multiple containers with the same `RELAY_ID` on the same network.

## Broadcast Behavior

**Important Concept:** Each container broadcasts to ALL configured interfaces. If you need selective broadcasting (e.g., only from VLAN 10 to VLAN 20 but not to VLAN 30), you must run separate containers with different interface lists.

Example:
- Container 1: `INTERFACES=br0.10,br0.20` (relays between VLANs 10 and 20)
- Container 2: `INTERFACES=br0.20,br0.30` (relays between VLANs 20 and 30)

## Validation

The entrypoint script validates all required parameters on startup:
- `RELAY_ID`: Must be 1-99
- `BROADCAST_PORT`: Must be 1-65535
- `INTERFACES`: Must not be empty

Invalid configurations will prevent the container from starting and log clear error messages. For startup issues and diagnostics, see [docs/UNRAID_SETUP.md](docs/UNRAID_SETUP.md) and the troubleshooting section in [docs/EXAMPLES.md](docs/EXAMPLES.md).

## Related documentation

- Setup patterns and device-specific walkthroughs: [docs/EXAMPLES.md](docs/EXAMPLES.md)
- Unraid installation steps and troubleshooting: [docs/UNRAID_SETUP.md](docs/UNRAID_SETUP.md)
- How RELAY_ID prevents loops: [docs/LOOP_PREVENTION.md](docs/LOOP_PREVENTION.md)