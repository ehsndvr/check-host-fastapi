#!/bin/bash
set -euo pipefail

echo "🚀 Starting setup for FastAPI service..."

# === 1. Update packages ===
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip curl

# === 2. Create app folder ===
APP_DIR="/opt/check-host-fastapi"
sudo mkdir -p "$APP_DIR"
sudo chown "$USER":"$USER" "$APP_DIR"
cd "$APP_DIR"

# === 3. Download latest files from GitHub ===
RAW_BASE="https://raw.githubusercontent.com/ehsndvr/check-host-fastapi/main"
curl -fsSL "$RAW_BASE/app.py" -o app.py
curl -fsSL "$RAW_BASE/requirements.txt" -o requirements.txt

# === 4. Install dependencies ===
pip3 install --no-cache-dir -r requirements.txt uvicorn fastapi

# === 5. Create systemd service file ===
SERVICE_NAME="check-host-fastapi"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=FastAPI Check Host Service
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 -m uvicorn app:app --host 0.0.0.0 --port 5000
Restart=always
RestartSec=5
User=$USER
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# === 6. Reload systemd and enable service ===
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

# === 7. Show status and info ===
sudo systemctl status "$SERVICE_NAME" --no-pager
echo
echo "✅ FastAPI service installed and started successfully!"
echo "📡 Accessible at: http://<your-server-ip>:5000"
echo "To view logs: sudo journalctl -u $SERVICE_NAME -f"
