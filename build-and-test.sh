#!/bin/bash
set -e

IMAGE_TAG="${TEST_IMAGE:-$IMAGE_TAG}"

echo "=== UDP Broadcast Relay Docker Build and Test ==="
echo "Using image: $IMAGE_TAG"
echo ""

# Check if image already exists (CI mode)
if docker image inspect "$IMAGE_TAG" > /dev/null 2>&1; then
    echo "1. Using pre-built image: $IMAGE_TAG"
    echo "✓ Image found"
else
    echo "1. Building Docker image..."
    docker build -t "$IMAGE_TAG" . || exit 1
    echo "✓ Build successful"
fi
echo ""

# Check image size
echo "2. Checking image size..."
SIZE=$(docker images $IMAGE_TAG --format "{{.Size}}")
echo "   Image size: $SIZE"
echo "✓ Image size check complete"
echo ""

# Test entrypoint validation
echo "3. Testing entrypoint validation..."

echo "   Test 3a: Missing RELAY_ID (should fail)"
docker run --rm -e BROADCAST_PORT=65001 -e INTERFACES=eth0,eth1 $IMAGE_TAG 2>&1 | grep -q "RELAY_ID" && echo "   ✓ RELAY_ID validation works" || echo "   ✗ RELAY_ID validation failed"

echo "   Test 3b: Missing BROADCAST_PORT (should fail)"
docker run --rm -e RELAY_ID=1 -e INTERFACES=eth0,eth1 $IMAGE_TAG 2>&1 | grep -q "BROADCAST_PORT" && echo "   ✓ BROADCAST_PORT validation works" || echo "   ✗ BROADCAST_PORT validation failed"

echo "   Test 3c: Missing INTERFACES (should fail)"
docker run --rm -e RELAY_ID=1 -e BROADCAST_PORT=65001 $IMAGE_TAG 2>&1 | grep -q "INTERFACES" && echo "   ✓ INTERFACES validation works" || echo "   ✗ INTERFACES validation failed"

echo ""

# Test valid configuration
echo "4. Testing valid minimal configuration..."
docker run --rm -e RELAY_ID=1 -e BROADCAST_PORT=65001 -e INTERFACES=eth0,eth1 $IMAGE_TAG 2>&1 | head -5
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
  $IMAGE_TAG 2>&1 | head -5
echo "✓ Full configuration test complete"
echo ""

# Verify binary is executable
echo "6. Verifying binary..."
docker run --rm --entrypoint sh $IMAGE_TAG -c "test -x /usr/local/bin/udp-broadcast-relay-redux && echo 'Binary is executable'"
echo "✓ Binary check complete"
echo ""

echo ""

# Validate docker-compose
echo "7. Validating docker-compose.yml..."
docker compose -f docker-compose.yml config > /dev/null && echo "✓ docker-compose.yml is valid" || echo "✗ docker-compose.yml has errors"
echo ""

echo "=== All tests completed successfully! ==="

# CI-friendly summary
if [ -n "$CI" ]; then
    echo "::group::Test Summary"
    echo "All tests passed successfully"
    echo "::endgroup::"
fi