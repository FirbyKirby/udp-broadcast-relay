# Unraid Setup Guide

This guide provides step-by-step instructions for setting up UDP Broadcast Relay Redux on Unraid systems.

> Important
> - Use Host network mode so the container can access all VLAN interfaces.
> - Each container broadcasts to all listed INTERFACES. For selective paths, run separate containers.
> - Assign a unique RELAY_ID (1–99) per container to prevent loops. See [docs/LOOP_PREVENTION.md](docs/LOOP_PREVENTION.md).
> - For Roku/SSDP on port 1900, set MULTICAST_GROUP=239.255.255.250. See [docs/CONFIGURATION.md](docs/CONFIGURATION.md).

## Prerequisites

### Network Configuration
1. **VLAN Setup:** Ensure your VLANs are properly configured in Unraid Network Settings
2. **Interface Names:** Note your VLAN interface names (typically `br0.X` where X is the VLAN ID)
3. **Docker Enabled:** Docker service must be running

### System Requirements
- Unraid 6.8 or later
- Docker enabled
- Host network access for containers

## Installation Steps

### Step 1: Add Container Template

1. Open the Unraid web interface
2. Go to **Docker** → **Add Container**
3. Click **Template** dropdown → **Load from File**
4. Upload the `unraid-template.xml` file from this repository
5. The template should now appear in the **Select a template** dropdown

### Step 2: Configure Container

1. Select **udp-broadcast-relay-redux** from the template dropdown
2. Configure the following settings:

#### Required Settings
- **Name:** Choose a descriptive name (e.g., `udp-relay-hdhomerun`)
- **Network Type:** `Host` (required for multi-VLAN access)
- **Privileged:** `Off` (not needed, capabilities are granted separately)

#### Environment Variables
- **RELAY_ID:** Unique ID (1-99) - must be different for each container
- **BROADCAST_PORT:** UDP port for your device type
- **INTERFACES:** Comma-separated VLAN interfaces (e.g., `br0.10,br0.20`)
- **PUID:** User ID to run as on the host (LinuxServer.io pattern). Default on Unraid: `99` (user: nobody)
- **PGID:** Group ID to run as on the host (LinuxServer.io pattern). Default on Unraid: `100` (group: users)

#### Advanced Settings
- **Extra Parameters:** Add `--cap-add NET_ADMIN --cap-add NET_RAW`
- **Capabilities:** These are passed via Extra Parameters on Unraid
- Tip: If you use Compose on Unraid or elsewhere, ensure `cap_add: [NET_ADMIN, NET_RAW]` and `network_mode: host`. See examples in [docs/EXAMPLES.md](docs/EXAMPLES.md).

### Step 3: Apply and Start

1. Click **Apply** to create the container
2. Click the container icon to start it
3. Check logs to verify it's running correctly

## PUID and PGID on Unraid (LinuxServer.io pattern)

PUID and PGID map the container process to a specific host user and group. This ensures files created by the container on mounted Unraid shares are owned by the expected account. This project follows the well-known LinuxServer.io pattern.

Defaults on Unraid:
- PUID: `99` (user: nobody)
- PGID: `100` (group: users)

When to keep the defaults:
- Your Unraid shares are using the standard nobody:users ownership
- You do not need files written by the container to be owned by a specific named user

When to change the defaults:
- You are not running Unraid (for example, typical Linux hosts often use `1000:1000` for the first user)
- Your target share or bind mount path is owned by a specific UID:GID and you want new files to match that ownership
- You see "permission denied" errors when the container accesses mounted paths

Find your UID and GID on the host:
```bash
id -u   # prints your numeric user ID (e.g., 1000)
id -g   # prints your numeric group ID (e.g., 1000)
id      # prints full identity (uid, gid, and groups)
```

Set PUID/PGID in the Unraid template:
1. Go to **Docker** → your container → **Edit**
2. In the Environment Variables section, add or update:
   - Name: `PUID`  Value: `1000`  (example)
   - Name: `PGID`  Value: `1000`  (example)
3. Click **Apply** to save and restart the container

Example (for reference only; Unraid uses form fields):
```yaml
environment:
  RELAY_ID: 1
  BROADCAST_PORT: 65001
  INTERFACES: br0.10,br0.20
  PUID: 1000
  PGID: 1000
```

See also:
- Configuration details: [docs/CONFIGURATION.md](docs/CONFIGURATION.md)
- Overview in README: [README.md](README.md)

## Device-Specific Configurations

### HDHomerun Tuner Discovery
```
Name: udp-relay-hdhomerun
RELAY_ID: 1
BROADCAST_PORT: 65001
INTERFACES: br0.10,br0.20
```

### Roku Device Discovery
```
Name: udp-relay-roku
RELAY_ID: 2
BROADCAST_PORT: 1900
INTERFACES: br0.10,br0.20
MULTICAST_GROUP: 239.255.255.250
```

### Kasa Smart Home
```
Name: udp-relay-kasa
RELAY_ID: 3
BROADCAST_PORT: 9999
INTERFACES: br0.10,br0.20
```

## Multiple Container Setup

For networks with multiple device types, create separate containers:

1. **HDHomerun Relay** (ID: 1, Port: 65001)
2. **Roku Relay** (ID: 2, Port: 1900)
3. **Kasa Relay** (ID: 3, Port: 9999)
4. **Additional Kasa** (ID: 4, Port: 20002) - if needed

## VLAN Configuration in Unraid

### Step 1: Access Network Settings
1. Go to **Settings** → **Network Settings**
2. Click **Add VLAN** for each VLAN you need

### Step 2: Configure VLANs
For each VLAN:
- **VLAN ID:** Your VLAN number (10, 20, 30, etc.)
- **VLAN Name:** Descriptive name (IoT, Media, Guest, etc.)
- **Bridge:** Usually `br0`
- **Enable VLAN:** Yes

### Step 3: Verify Interfaces
After applying changes:
1. Go to **Docker** → **Console** (advanced button)
2. Run `ip addr show` to list interfaces
3. Verify your VLAN interfaces exist (e.g., `br0.10`, `br0.20`)

## Troubleshooting

### Container Won't Start
**Symptoms:** Container shows as stopped immediately after starting

**Solutions:**
1. Check environment variables are all set
2. Verify RELAY_ID is between 1-99
3. Ensure BROADCAST_PORT is valid (1-65535)
4. Check INTERFACES contains valid interface names

**Check logs:**
```bash
docker logs <container_name>
```

### No Broadcast Relaying
**Symptoms:** Devices can't discover each other across VLANs

**Solutions:**
1. Verify VLAN interfaces exist and are up
2. Check container has NET_ADMIN and NET_RAW capabilities
3. Ensure network mode is "Host"
4. Test with DEBUG=true to see packet flow

**Debug commands:**
```bash
# Check interface status on the host
ip link show

# Monitor UDP traffic using a diagnostics container (netshoot)
docker run --rm --net=host nicolaka/netshoot tcpdump -i any udp port <port> -v

# For SSDP (Roku), include multicast
docker run --rm --net=host nicolaka/netshoot tcpdump -i any udp port 1900 and host 239.255.255.250 -v
```

### Broadcast Loops
**Symptoms:** Network congestion, high CPU usage

**Solutions:**
1. Ensure each container has a unique RELAY_ID
2. Check that containers aren't relaying to the same interfaces multiple times
3. Reduce the number of interfaces if possible

### File Permission Issues
**Symptoms:** "permission denied" errors when reading/writing mounted shares; files created with unexpected ownership

**Solutions:**
1. Use PUID/PGID to match the owner of the mounted path
   - Determine ownership on the host: `ls -l /path/to/share`
   - Set PUID/PGID to that UID:GID in the container environment
2. Or adjust host ownership to your chosen UID:GID:
   ```bash
   sudo chown -R <uid>:<gid> /path/to/share
   ```
3. Confirm the mount path exists and is writable by the chosen UID/GID
4. Review detailed guidance: [docs/CONFIGURATION.md](docs/CONFIGURATION.md) and the PUID/PGID overview in [README.md](README.md)

## Network Controller Integration

### UDM Pro / UniFi Dream Router
mDNS repeaters handle multicast DNS–based discovery such as Chromecast, AirPlay, HomeKit, and many Sonos devices. UDP Broadcast Relay complements this by covering non‑mDNS UDP discovery (for example, HDHomerun on 65001, Roku/SSDP on 1900, Kasa on 9999/20002). See device examples in [docs/EXAMPLES.md](docs/EXAMPLES.md).

If your network controller supports mDNS repeater functionality:

1. **Enable mDNS Repeater** in the controller settings
2. **Configure VLANs** to allow mDNS traffic
3. **UDP Broadcast Relay** handles protocols not covered by mDNS

**mDNS Repeater covers:**
- Chromecast discovery
- AirPlay devices
- Apple TV
- HomeKit accessories
- Printers
- Sonos (newer models)

**UDP Broadcast Relay covers:**
- HDHomerun tuners
- Roku devices
- Kasa smart home
- Other custom UDP broadcast protocols

### When to Use UDP Relay vs mDNS

| Protocol | mDNS Repeater | UDP Broadcast Relay |
|----------|---------------|---------------------|
| Chromecast | ✅ | ❌ |
| HDHomerun | ❌ | ✅ |
| Roku | ❌ | ✅ |
| Kasa | ❌ | ✅ |
| Sonos (new) | ✅ | ❌ |
| HomeKit | ✅ | ❌ |

## Performance Considerations

### Resource Usage
- **CPU:** Minimal (< 1% on most systems)
- **Memory:** ~5-10MB per container
- **Network:** Only processes broadcast traffic

### Scaling
- One container per protocol type
- Multiple containers can run simultaneously
- No performance degradation with multiple VLANs

## Monitoring and Maintenance

### Health Checks
The container includes automatic health monitoring:
```bash
# Check container health
docker ps --filter "name=udp-relay*"

# View resource usage
docker stats udp-relay-hdhomerun
```

### Log Rotation
Unraid automatically handles Docker log rotation. View logs:
```bash
# View recent logs
docker logs udp-relay-hdhomerun

# Follow logs in real-time
docker logs -f udp-relay-hdhomerun
```

### Updates
When updating the container:
1. Stop the container
2. Update the image
3. Start the container
4. Verify functionality

## Advanced Configuration

### Custom Interface Names
If your VLAN interfaces don't follow the `br0.X` pattern:
```
INTERFACES: vlan10,vlan20,vlan30
```

### Debug Mode
Enable verbose logging for troubleshooting:
```
DEBUG: true
```

### Source IP Spoofing
For advanced network configurations:
```
SPOOF_SOURCE: 1.1.1.1  # Use interface IP
```

## Support

For issues specific to Unraid:
1. Check Unraid forums
2. Review Docker container logs
3. Verify network configuration
4. Test with minimal configuration first

For UDP Broadcast Relay issues:
1. Check upstream repository issues
2. Review debug logs
3. Verify network interface configuration