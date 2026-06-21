# Multi-architecture Dockerfile for udp-broadcast-relay-redux
FROM alpine:3.19 AS builder
ARG TARGETPLATFORM
RUN echo "Target platform: $TARGETPLATFORM"

# Install build dependencies
RUN apk add --no-cache gcc musl-dev linux-headers

# Copy source code
WORKDIR /build
COPY main.c .

# Compile the binary
RUN gcc -g main.c -o udp-broadcast-relay-redux

# Runtime stage - minimal Alpine Linux
FROM alpine:3.19

# Set default PUID and PGID following LinuxServer.io pattern
# Override at runtime for specific platforms (e.g., Unraid template passes PUID=99 / PGID=100)
ARG PUID=1000
ARG PGID=1000
ENV PUID=$PUID
ENV PGID=$PGID

# Copy binary from builder stage
COPY --from=builder /build/udp-broadcast-relay-redux /usr/local/bin/

RUN apk add --no-cache libcap shadow \
    && (getent group $PGID > /dev/null 2>&1 && delgroup $(getent group $PGID | cut -d: -f1) || true) \
    && (getent passwd $PUID > /dev/null 2>&1 && deluser $(getent passwd $PUID | cut -d: -f1) || true) \
    && (addgroup -g $PGID relay 2>/dev/null || addgroup relay) \
    && adduser -D -s /bin/sh -u $PUID -G relay relay \
    && setcap cap_net_admin,cap_net_raw+ep /usr/local/bin/udp-broadcast-relay-redux

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /app

# Switch to non-root user
USER relay

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD pgrep udp-broadcast-relay-redux || exit 1

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
