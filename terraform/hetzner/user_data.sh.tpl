#!/bin/bash
set -euxo pipefail

# Logging
exec > >(tee /var/log/user-data.log) 2>&1

echo "=== Starting Claude Dev setup for project: ${project_name} ==="

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin git

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Create app directory
APP_DIR="/opt/claude-dev"
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Clone repository
git clone ${git_repo_url} .

# Create systemd service
cat > /etc/systemd/system/claude-dev.service << 'EOF'
[Unit]
Description=Claude Dev Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/claude-dev
ExecStart=/usr/bin/docker compose -f docker-compose.yml -f docker-compose.prod.yml -p claude-dev up -d --build
ExecStop=/usr/bin/docker compose -f docker-compose.yml -f docker-compose.prod.yml -p claude-dev down
User=root
Group=docker

[Install]
WantedBy=multi-user.target
EOF

# Enable service
systemctl daemon-reload
systemctl enable claude-dev

# Build images and start service (credentials are persisted in Docker volume)
/usr/bin/docker compose -f docker-compose.yml -f docker-compose.prod.yml -p claude-dev build
systemctl start claude-dev

echo "=== Claude Dev setup completed for project: ${project_name} ==="
