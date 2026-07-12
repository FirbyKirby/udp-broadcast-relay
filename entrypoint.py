#!/usr/bin/env python3
# udp-broadcast-relay-redux Docker Entrypoint
# Converts environment variables to command-line arguments

import os
import sys
from datetime import datetime

BINARY = "/usr/local/bin/udp-broadcast-relay-redux"

USAGE = """Required environment variables:
  RELAY_ID       - Unique ID (1-99) for loop prevention
  BROADCAST_PORT - UDP port to relay (e.g., 65001)
  INTERFACES     - Comma-separated VLAN interfaces (e.g., br0.10,br0.20)

Optional environment variables:
  MULTICAST_GROUP - Multicast IP to join (e.g., 239.255.255.250)
  SPOOF_SOURCE    - Override source IP (empty=preserve, 1.1.1.1=auto)
  TARGET_OVERRIDE - Override destination IP (empty=original, 255.255.255.255=broadcast)
  DEBUG           - Enable verbose logging (true/false, default: false)"""


def log(message=""):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}", file=sys.stderr, flush=True)


def fail(message):
    log(f"Error: {message}")
    log()
    for line in USAGE.splitlines():
        log(line)
    sys.exit(1)


def require_env(name):
    value = os.environ.get(name, "").strip()
    if not value:
        fail(f"{name} is required")
    return value


def require_int_in_range(name, raw_value, low, high):
    try:
        value = int(raw_value)
    except ValueError:
        fail(f"{name} must be an integer, got: {raw_value!r}")
    if not low <= value <= high:
        fail(f"{name} must be between {low} and {high}")
    return value


def main():
    relay_id_raw = require_env("RELAY_ID")
    port_raw = require_env("BROADCAST_PORT")
    interfaces_raw = require_env("INTERFACES")

    relay_id = require_int_in_range("RELAY_ID", relay_id_raw, 1, 99)
    port = require_int_in_range("BROADCAST_PORT", port_raw, 1, 65535)
    interfaces = [i for i in (part.strip() for part in interfaces_raw.split(",")) if i]

    multicast_group = os.environ.get("MULTICAST_GROUP", "").strip()
    spoof_source = os.environ.get("SPOOF_SOURCE", "").strip()
    target_override = os.environ.get("TARGET_OVERRIDE", "").strip()
    debug = os.environ.get("DEBUG", "false").strip().lower() == "true"

    args = ["--id", str(relay_id), "--port", str(port)]
    for iface in interfaces:
        args += ["--dev", iface]
    if multicast_group:
        args += ["--multicast", multicast_group]
    if spoof_source:
        args += ["-s", spoof_source]
    if target_override:
        args += ["-t", target_override]
    if debug:
        args.append("-d")

    log("Starting udp-broadcast-relay-redux with configuration:")
    log(f"  RELAY_ID: {relay_id}")
    log(f"  BROADCAST_PORT: {port}")
    log(f"  INTERFACES: {interfaces_raw}")
    if multicast_group:
        log(f"  MULTICAST_GROUP: {multicast_group}")
    if spoof_source:
        log(f"  SPOOF_SOURCE: {spoof_source}")
    if target_override:
        log(f"  TARGET_OVERRIDE: {target_override}")
    log(f"  DEBUG: {debug}")
    log()
    log(f"Command: {BINARY} {' '.join(args)}")
    log()

    if os.environ.get("TEST_MODE") == "1":
        sys.exit(0)

    # exec directly (no shell, no fork) so setcap'd file capabilities on the
    # binary are preserved — see commit 3bf0281.
    os.execv(BINARY, [BINARY] + args)


if __name__ == "__main__":
    main()
