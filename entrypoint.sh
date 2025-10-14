#!/bin/sh

# udp-broadcast-relay-redux Docker Entrypoint Script
# Converts environment variables to command-line arguments

set -e

# Handle dynamic PUID/PGID mapping
if [ -n "$PUID" ] && [ -n "$PGID" ]; then
    CURRENT_UID=$(id -u relay 2>/dev/null || echo "")
    CURRENT_GID=$(id -g relay 2>/dev/null || echo "")
    if [ "$PUID" != "$CURRENT_UID" ] || [ "$PGID" != "$CURRENT_GID" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Updating relay user to UID:$PUID GID:$PGID" >&2

        # Enhanced PGID handling: Check if group with PGID already exists
        EXISTING_GROUP=$(getent group "$PGID" | cut -d: -f1 || echo "")
        if [ -n "$EXISTING_GROUP" ]; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Using existing group '$EXISTING_GROUP' for GID $PGID" >&2
            GROUP_NAME="$EXISTING_GROUP"
        else
            GROUP_NAME="relaypgid"
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Creating new group '$GROUP_NAME' with GID $PGID" >&2
            groupadd -g "$PGID" "$GROUP_NAME" 2>/dev/null || echo "[$(date +'%Y-%m-%d %H:%M:%S')] Warning: Could not create group with GID $PGID" >&2
        fi

        # Change relay's primary group
        usermod -g "$GROUP_NAME" relay 2>/dev/null || echo "[$(date +'%Y-%m-%d %H:%M:%S')] Warning: Could not update relay's primary group" >&2

        # Enhanced PUID handling: Only change UID if different
        if [ "$PUID" != "$CURRENT_UID" ]; then
            usermod -u "$PUID" relay 2>/dev/null || echo "[$(date +'%Y-%m-%d %H:%M:%S')] Warning: Could not update user ID to $PUID" >&2
        fi

        # Update ownership of working directory only if needed
        if [ -d "/app" ] && [ "$(stat -c %u /app 2>/dev/null || echo "")" != "$PUID" ]; then
            chown -R relay:relay /app 2>/dev/null || echo "[$(date +'%Y-%m-%d %H:%M:%S')] Warning: Could not update ownership" >&2
        fi
    fi
else
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] PUID and PGID not set, using defaults" >&2
fi

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Function to show usage and exit
usage() {
    log "Error: $1"
    log ""
    log "Required environment variables:"
    log "  RELAY_ID       - Unique ID (1-99) for loop prevention"
    log "  BROADCAST_PORT - UDP port to relay (e.g., 65001)"
    log "  INTERFACES     - Comma-separated VLAN interfaces (e.g., br0.10,br0.20)"
    log ""
    log "Optional environment variables:"
    log "  MULTICAST_GROUP - Multicast IP to join (e.g., 239.255.255.250)"
    log "  SPOOF_SOURCE    - Override source IP (empty=preserve, 1.1.1.1=auto)"
    log "  TARGET_OVERRIDE - Override destination IP (empty=original, 255.255.255.255=broadcast)"
    log "  DEBUG           - Enable verbose logging (true/false, default: false)"
    log "  PUID            - User ID for the relay user (default: 1000)"
    log "  PGID            - Group ID for the relay user (default: 1000)"
    log ""
    exit 1
}

# Validate required environment variables
if [ -z "$RELAY_ID" ]; then
    usage "RELAY_ID is required"
fi

if [ -z "$BROADCAST_PORT" ]; then
    usage "BROADCAST_PORT is required"
fi

if [ -z "$INTERFACES" ]; then
    usage "INTERFACES is required"
fi

# Validate RELAY_ID range
if [ "$RELAY_ID" -lt 1 ] || [ "$RELAY_ID" -gt 99 ]; then
    usage "RELAY_ID must be between 1 and 99"
fi

# Validate BROADCAST_PORT range
if [ "$BROADCAST_PORT" -lt 1 ] || [ "$BROADCAST_PORT" -gt 65535 ]; then
    usage "BROADCAST_PORT must be between 1 and 65535"
fi

# Build command arguments
ARGS="--id $RELAY_ID --port $BROADCAST_PORT"

# Add interfaces (comma-separated to multiple --dev flags)
IFS=','; for interface in $INTERFACES; do
    # Trim whitespace
    interface=$(echo "$interface" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ -n "$interface" ]; then
        ARGS="$ARGS --dev $interface"
    fi
done

# Add multicast group if specified
if [ -n "$MULTICAST_GROUP" ]; then
    ARGS="$ARGS --multicast $MULTICAST_GROUP"
fi

# Add spoof source if specified
if [ -n "$SPOOF_SOURCE" ]; then
    ARGS="$ARGS -s $SPOOF_SOURCE"
fi

# Add target override if specified
if [ -n "$TARGET_OVERRIDE" ]; then
    ARGS="$ARGS -t $TARGET_OVERRIDE"
fi

# Add debug flag if enabled
if [ "$DEBUG" = "true" ]; then
    ARGS="$ARGS -d"
fi

# Run in foreground mode (default for Docker containers)

# Log the configuration
log "Starting udp-broadcast-relay-redux with configuration:"
log "  RELAY_ID: $RELAY_ID"
log "  BROADCAST_PORT: $BROADCAST_PORT"
log "  INTERFACES: $INTERFACES"
if [ -n "$MULTICAST_GROUP" ]; then
    log "  MULTICAST_GROUP: $MULTICAST_GROUP"
fi
if [ -n "$SPOOF_SOURCE" ]; then
    log "  SPOOF_SOURCE: $SPOOF_SOURCE"
fi
if [ -n "$TARGET_OVERRIDE" ]; then
    log "  TARGET_OVERRIDE: $TARGET_OVERRIDE"
fi
log "  DEBUG: ${DEBUG:-false}"
log "  PUID: ${PUID:-1000}"
log "  PGID: ${PGID:-1000}"
log ""
log "Using PUID=$PUID PGID=$PGID"
log "Effective: uid=$(id -u relay) gid=$(id -g relay) groups=$(id -G relay)"
log ""
log "Command: udp-broadcast-relay-redux $ARGS"
log ""

# Test mode: exit early for testing
if [ "$TEST_MODE" = "1" ]; then
    exit 0
fi

# Execute the binary with constructed arguments
exec su relay -c "/usr/local/bin/udp-broadcast-relay-redux $ARGS"