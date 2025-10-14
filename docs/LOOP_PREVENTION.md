# Loop Prevention and RELAY_ID

This document explains why RELAY_ID is required and how the TTL-based loop prevention works.

> At a glance
> - Use a unique RELAY_ID for every container, from 1 to 99
> - The relay sets the IP TTL of forwarded packets to RELAY_ID + 64
> - If a relay sees a packet with a TTL equal to its own marker, it drops it
> - Duplicate RELAY_IDs can cause loops and broadcast storms

## Why Loop Prevention Matters

In host network mode, multiple UDP broadcast relay instances can create broadcast storms if not properly configured. Without loop prevention, broadcasts can bounce infinitely between network interfaces, causing:

- Network congestion
- High CPU usage on relay containers
- Packet loss and degraded network performance
- Potential network outages

## How TTL-Based Loop Prevention Works

The UDP Broadcast Relay Redux uses a TTL (Time To Live) modification mechanism for loop prevention:

### TTL Modification
1. Each relay instance sets the IP TTL on forwarded packets to `RELAY_ID + 64`
2. When a relay later receives a packet whose TTL equals its own marker, it ignores it
3. This prevents the same instance from relaying the same broadcast repeatedly

### Example Scenario
```
VLAN 10           Relay 1 (ID=1)          VLAN 20
     |                   |                      |
     |   TTL=64          |   TTL=65             |
     |------------------>|--------------------->|
     |                   |                      |
     |   TTL=65          |   TTL=66 (ignored)   |
     |<------------------|<---------------------|
     |                   |                      |
```

```mermaid
flowchart LR
  V10[Ingress ttl 64] --> R1[Relay id 1 sets ttl 65]
  R1 --> V20[Egress ttl 65]
  V20 --> R1[Echo ttl 65]
  R1 -. drop .-> V10[Ignored echo]
```

In this example:
- Original broadcast has TTL=64
- Relay 1 modifies TTL to 65 (1 + 64) and forwards
- When the modified packet returns, Relay 1 sees TTL=65 (its own mark) and ignores it

## RELAY_ID Requirements

### Unique IDs
- **Each container must have a unique RELAY_ID** (1-99)
- Never run multiple containers with the same RELAY_ID on the same network
- IDs are used across all relay containers, not per protocol

### Valid Range
- Minimum: 1
- Maximum: 99
- Recommended: Start with 1 and increment for each additional container

### ID Assignment Best Practices
```
Container Type      RELAY_ID    Reason
HDHomerun Relay     1           First relay, lowest ID
Roku Relay          2           Second relay, next ID
Kasa Relay          3           Third relay, next ID
Additional Kasa     4           Fourth relay, next ID
```

## Common Loop Prevention Issues

### Symptom: High Network Traffic
**Cause:** Duplicate RELAY_ID values
**Solution:** Assign unique IDs to each container

### Symptom: Container Logs Show Ignored Packets
**Cause:** Normal operation - packets being correctly filtered
**Log Example:**
```
[2023-10-14 14:30:15] Echo (Ignored)
```

### Symptom: No Packet Relaying
**Cause:** TTL collision with existing network traffic
**Solution:** Change RELAY_ID to avoid conflicts

## Advanced Loop Prevention

### Multiple Relay Layers
For complex networks with multiple relay levels:

```
Level 1 Relays (IDs 1-10): Edge relays
Level 2 Relays (IDs 11-20): Distribution relays
Level 3 Relays (IDs 21-30): Core relays
```

### Selective Broadcasting
When using multiple containers for selective VLAN routing:

```
Container A: VLANs 10↔20 (ID=1)
Container B: VLANs 20↔30 (ID=2)
Container C: VLANs 10↔30 (ID=3)
```

Each container handles different interface combinations with unique IDs.

## Troubleshooting Loop Issues

### Check for Duplicate IDs
```bash
# List all relay containers
docker ps --filter "name=udp-relay"

# Check environment variables
docker exec udp-relay-hdhomerun env | grep RELAY_ID
```

### Monitor Packet Flow
Enable debug logging to see TTL values:
```bash
# Set DEBUG=true in container environment
# Check logs for TTL information
docker logs udp-relay-hdhomerun
```

**Debug log example:**
```
[2023-10-14 14:30:15] <- [192.168.10.100:65001 -> 255.255.255.255:65001 (iface=3 len=50 ttl=64)
[2023-10-14 14:30:15] -> [192.168.10.100:65001 -> 192.168.20.255:65001 (iface=4)
[2023-10-14 14:30:15] Echo (Ignored)
```

### Network Analysis
Use tcpdump to monitor broadcast traffic:
```bash
# Monitor broadcasts on specific port
tcpdump -i any udp port 65001 -v

# Check for broadcast storms
tcpdump -i any udp port 65001 | head -20
```

## TTL Collision Risks

### Existing Network TTL Values
Most devices originate with TTL 64. The relay sets TTL to RELAY_ID + 64 (for example, 65 when RELAY_ID=1). A collision only occurs if another device on your network emits packets with that exact TTL at the relay ingress.

**Symptoms:**
- Packets ignored when they shouldn't be
- Missing device discoveries

**Solutions:**
- Change RELAY_ID to a different value
- Prefer IDs that avoid common TTLs you observe in logs

### Router/Firewall TTL Modifications
Network equipment that modifies TTL can interfere with loop prevention:

**Detection:**
```bash
# Check if TTL values are being modified
traceroute -U -p 65001 <target_ip>
```

**Workaround:**
- Adjust RELAY_ID values
- Contact network administrator about TTL preservation

## Best Practices

### ID Management
1. **Document ID assignments** for each container
2. **Use consecutive IDs** starting from 1
3. **Reserve ID ranges** for different network segments
4. **Audit IDs periodically** during network changes

### Monitoring
1. **Enable debug logging** during initial setup
2. **Monitor container logs** for "Echo (Ignored)" messages
3. **Check network traffic levels** during testing
4. **Verify device discovery** works across VLANs

### Network Design
1. **Minimize relay instances** where possible
2. **Use selective broadcasting** to reduce unnecessary traffic
3. **Plan ID assignments** before deployment
4. **Test configurations** in staging environments

## Technical Details

### TTL Calculation
```c
u_char ttl = id + TTL_ID_OFFSET;  // TTL_ID_OFFSET = 64
```

### Loop Detection
```c
if (rcv_ttl == ttl) {
    // This is our own packet, ignore it
    continue;
}
```

### Packet Modification
- Original packet TTL is preserved for the receiver
- Only the forwarded copies get modified TTL
- Source IP spoofing can be used for advanced routing

## Migration Guide

### Upgrading from Single Relay
When adding multiple relays to an existing single-relay setup:

1. **Stop existing container**
2. **Change its RELAY_ID** if needed
3. **Add new containers** with unique IDs
4. **Test device discovery**
5. **Monitor for loops**

### Changing IDs
To change a container's RELAY_ID:

1. **Stop the container**
2. **Update environment variable**
3. **Restart container**
4. **Clear any cached broadcasts** (wait 30 seconds)
5. **Test functionality**

## Related documentation

- Configuration reference: [docs/CONFIGURATION.md](docs/CONFIGURATION.md)
- Examples and patterns: [docs/EXAMPLES.md](docs/EXAMPLES.md)
- Unraid setup guide: [docs/UNRAID_SETUP.md](docs/UNRAID_SETUP.md)

## Support

If you encounter persistent loop issues:

1. **Verify unique RELAY_IDs** across all containers
2. **Check debug logs** for TTL patterns
3. **Monitor network traffic** with tcpdump
4. **Test with minimal configuration** (two VLANs, one protocol)
5. **Consider network equipment** that may modify TTL

The loop prevention mechanism is robust when properly configured, but network-specific issues may require ID adjustments.