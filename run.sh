#!/bin/bash
set -euo pipefail

echo "🚀 Starting setup for FastAPI Check Host service (Global Install)..."

# === 1. Update system and install dependencies ===
sudo apt-get update -y
sudo apt-get install -y python3 python3-pip curl systemd

# === 2. Create application directory ===
APP_DIR="/opt/check-host-fastapi"
sudo mkdir -p "$APP_DIR"
sudo chown "$USER":"$USER" "$APP_DIR"
cd "$APP_DIR"

# === 3. Download application files ===
RAW_BASE="https://raw.githubusercontent.com/ehsndvr/check-host-fastapi/main"
echo "📦 Downloading FastAPI application files..."
curl -fsSL "$RAW_BASE/app.py" -o app.py
curl -fsSL "$RAW_BASE/requirements.txt" -o requirements.txt

# === 4. Install dependencies globally (no uninstall attempts, safe for Debian/Ubuntu) ===
echo "⚙️ Installing Python dependencies globally..."
python3 -m pip install --no-cache-dir -r requirements.txt uvicorn fastapi --break-system-packages --ignore-installed

# === 5. Create systemd service file ===
SERVICE_NAME="check-host-fastapi"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

echo "🛠️ Creating systemd service..."
sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=FastAPI Check Host Service
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 -m uvicorn app:app --host 0.0.0.0 --port 5000 --log-level info
Restart=always
RestartSec=5
User=$USER
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# === 6. Enable and start the service ===
echo "🔁 Enabling and starting systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

# === 7. Final output ===
echo
echo "✅ FastAPI service installed and started successfully!"
echo "📡 Accessible at: http://<your-server-ip>:5000"
echo
echo "🧭 Useful commands:"
echo "  ▪️ Check status:   sudo systemctl status $SERVICE_NAME"
echo "  ▪️ View logs:      sudo journalctl -u $SERVICE_NAME -f"
echo "  ▪️ Restart:        sudo systemctl restart $SERVICE_NAME"
echo "  ▪️ Stop:           sudo systemctl stop $SERVICE_NAME"
echo
echo "🎉 Installation complete!"
