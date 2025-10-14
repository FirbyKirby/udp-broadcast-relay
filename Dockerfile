# Multi-architecture Dockerfile for udp-broadcast-relay-redux
FROM --platform=$BUILDPLATFORM alpine:3.19 AS builder

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
ENV PUID=1000
ENV PGID=1000

# Copy binary from builder stage
COPY --from=builder /build/udp-broadcast-relay-redux /usr/local/bin/

# Install runtime dependencies and create non-root user
RUN apk add --no-cache libcap shadow \
    && addgroup -g $PGID relay \
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
