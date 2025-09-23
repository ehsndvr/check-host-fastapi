#!/bin/bash
set -euo pipefail

# ------------------------------------------------------------------
# Example use:
# 1) قرار بدی فایل‌های app.py, Dockerfile, requirements.txt روی گیت‌هاب (raw)
# 2) این اسکریپت رو روی سرور اجرا کنی:
#    curl -sL https://raw.githubusercontent.com/USER/REPO/BRANCH/install_and_run.sh | bash
# ------------------------------------------------------------------

echo "Starting automated install/build/run..."

# 1) update + switch to iran archive mirror (optional but requested)
sudo apt-get update
sudo sed -i 's|http://[a-z0-9]*.archive.ubuntu.com|http://ir.archive.ubuntu.com|g' /etc/apt/sources.list || true
sudo apt-get update

# 2) ensure snapd present and install docker (snap)
sudo apt-get install -y snapd
sudo snap install docker

# 3) configure docker registry mirror (مثل نمونه شما)
sudo bash -c 'cat > /var/snap/docker/current/config/daemon.json <<EOF
{
  "registry-mirrors": ["https://registry.docker.ir"]
}
EOF'

sudo snap restart docker

# 4) download raw files from your GitHub (replace these URLs with your real raw links)
RAW_APP_URL="${RAW_APP_URL:-https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/app.py}"
RAW_DOCKERFILE_URL="${RAW_DOCKERFILE_URL:-https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/Dockerfile}"
RAW_REQ_URL="${RAW_REQ_URL:-https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/requirements.txt}"

WORKDIR="/tmp/simplenetworkapichecker"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Downloading app.py, Dockerfile and requirements.txt from your GitHub raw URLs..."
curl -fsSL "$RAW_APP_URL" -o app.py
curl -fsSL "$RAW_DOCKERFILE_URL" -o Dockerfile
curl -fsSL "$RAW_REQ_URL" -o requirements.txt

# 5) build Docker image
IMAGE_NAME="simplenetworkapichecker:latest"
sudo docker build -t "$IMAGE_NAME" .

# 6) stop+remove existing container if exists, then run with restart policy
CONTAINER_NAME="simplenetworkapichecker"
if sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Removing existing container ${CONTAINER_NAME}..."
  sudo docker rm -f "${CONTAINER_NAME}" || true
fi

echo "Running container..."
sudo docker run -d --name "${CONTAINER_NAME}" -p 5000:5000 --restart always "$IMAGE_NAME"

echo "Done. Service should be reachable on port 5000."
echo "Try: curl http://localhost:5000/ping/8.8.8.8"
