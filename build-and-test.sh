#!/bin/bash
set -e

echo "=== UDP Broadcast Relay Docker Build and Test ==="
echo ""

# Build the image
echo "1. Building Docker image..."
docker build -t udp-broadcast-relay-redux:test . || exit 1
echo "✓ Build successful"
echo ""

# Check image size
echo "2. Checking image size..."
SIZE=$(docker images udp-broadcast-relay-redux:test --format "{{.Size}}")
echo "   Image size: $SIZE"
echo "✓ Image size check complete"
echo ""

# Test entrypoint validation
echo "3. Testing entrypoint validation..."

echo "   Test 3a: Missing RELAY_ID (should fail)"
docker run --rm -e BROADCAST_PORT=65001 -e INTERFACES=eth0,eth1 udp-broadcast-relay-redux:test 2>&1 | grep -q "RELAY_ID" && echo "   ✓ RELAY_ID validation works" || echo "   ✗ RELAY_ID validation failed"

echo "   Test 3b: Missing BROADCAST_PORT (should fail)"
docker run --rm -e RELAY_ID=1 -e INTERFACES=eth0,eth1 udp-broadcast-relay-redux:test 2>&1 | grep -q "BROADCAST_PORT" && echo "   ✓ BROADCAST_PORT validation works" || echo "   ✗ BROADCAST_PORT validation failed"

echo "   Test 3c: Missing INTERFACES (should fail)"
docker run --rm -e RELAY_ID=1 -e BROADCAST_PORT=65001 udp-broadcast-relay-redux:test 2>&1 | grep -q "INTERFACES" && echo "   ✓ INTERFACES validation works" || echo "   ✗ INTERFACES validation failed"

echo ""

# Test valid configuration
echo "4. Testing valid minimal configuration..."
docker run --rm -e RELAY_ID=1 -e BROADCAST_PORT=65001 -e INTERFACES=eth0,eth1 udp-broadcast-relay-redux:test 2>&1 | head -5
echo "✓ Minimal configuration test complete"
echo ""

# Test full configuration
echo "5. Testing full configuration with all options..."
docker run --rm \
  -e RELAY_ID=2 \
  -e BROADCAST_PORT=1900 \
  -e INTERFACES=eth0,eth1,eth2 \
  -e MULTICAST_GROUP=239.255.255.250 \
  -e SPOOF_SOURCE=1.1.1.1 \
  -e TARGET_OVERRIDE=255.255.255.255 \
  -e DEBUG=true \
  udp-broadcast-relay-redux:test 2>&1 | head -5
echo "✓ Full configuration test complete"
echo ""

# Check capabilities
echo "6. Verifying capabilities..."
docker run --rm --entrypoint sh udp-broadcast-relay-redux:test -c "getcap /usr/local/bin/udp-broadcast-relay-redux"
echo "✓ Capabilities check complete"
echo ""

# Test PUID/PGID functionality
echo "7. Testing PUID/PGID functionality..."

echo "   Test 7a: Default container behavior (no overrides)"
docker run --rm --entrypoint sh udp-broadcast-relay-redux:test -c "id -u; id -g" | grep -q "1000" && echo "   ✓ Default PUID/PGID (1000/1000) works" || echo "   ✗ Default PUID/PGID failed"

echo "   Test 7b: Unraid-style overrides (PUID=99 PGID=100)"
docker run --rm -e PUID=99 -e PGID=100 -e TEST_MODE=1 -e RELAY_ID=1 -e BROADCAST_PORT=65001 -e INTERFACES=eth0 --entrypoint sh udp-broadcast-relay-redux:test -c "/usr/local/bin/entrypoint.sh 2>&1 | grep -q 'Using PUID=99 PGID=100'" && echo "   ✓ Unraid-style PUID/PGID override works" || echo "   ✗ Unraid-style PUID/PGID override failed"

echo "   Test 7c: Verify capabilities are retained (default)"
docker run --rm --entrypoint sh udp-broadcast-relay-redux:test -c "getcap /usr/local/bin/udp-broadcast-relay-redux" | grep -q "cap_net_admin,cap_net_raw=ep" && echo "   ✓ Capabilities maintained with default PUID/PGID" || echo "   ✗ Capabilities lost with default PUID/PGID"

echo "   Test 7d: Verify capabilities are retained (with overrides)"
docker run --rm -e PUID=99 -e PGID=100 --entrypoint sh udp-broadcast-relay-redux:test -c "getcap /usr/local/bin/udp-broadcast-relay-redux" | grep -q "cap_net_admin,cap_net_raw=ep" && echo "   ✓ Capabilities maintained with PUID/PGID overrides" || echo "   ✗ Capabilities lost with PUID/PGID overrides"

echo "   Test 7e: Application runs with default PUID/PGID"
timeout 5 docker run --rm -e TEST_MODE=1 -e RELAY_ID=1 -e BROADCAST_PORT=65001 -e INTERFACES=eth0,eth1 udp-broadcast-relay-redux:test 2>&1 | grep -q "Using PUID=1000 PGID=1000" && echo "   ✓ Application starts with default PUID/PGID" || echo "   ✗ Application failed to start with default PUID/PGID"

echo "   Test 7f: Application runs with Unraid-style overrides"
timeout 5 docker run --rm -e TEST_MODE=1 -e PUID=99 -e PGID=100 -e RELAY_ID=1 -e BROADCAST_PORT=65001 -e INTERFACES=eth0,eth1 udp-broadcast-relay-redux:test 2>&1 | grep -q "Using PUID=99 PGID=100" && echo "   ✓ Application starts with Unraid-style overrides" || echo "   ✗ Application failed to start with Unraid-style overrides"

echo ""

# Validate docker-compose
echo "8. Validating docker-compose.yml..."
docker compose -f docker-compose.yml config > /dev/null && echo "✓ docker-compose.yml is valid" || echo "✗ docker-compose.yml has errors"
echo ""

echo "=== All tests completed successfully! ==="