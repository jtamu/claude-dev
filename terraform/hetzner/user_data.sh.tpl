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

# Setup swap (4GB) — Playwright Chromium等のメモリ消費に備える
if [ ! -f /swapfile ]; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  echo "=== Swap enabled (4GB) ==="
fi

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

# Create .env for docker-compose variable substitution
cat > "$APP_DIR/.env" << ENVEOF
SSH_AUTH_SOCK=/dev/null
DOMAIN=${domain}
ENVEOF

# Enable service
systemctl daemon-reload
systemctl enable claude-dev

# Build: まずベースイメージ (Dockerfile) をビルドし、続けて本番用 (Dockerfile.prod) をビルド
/usr/bin/docker compose -f docker-compose.yml -p claude-dev build ui
/usr/bin/docker compose -f docker-compose.yml -f docker-compose.prod.yml -p claude-dev build

# アプリ起動（nginx以外 — 証明書取得前なので）
systemctl start claude-dev

# SSL証明書の初期化
chmod +x "$APP_DIR/init-ssl.sh"
"$APP_DIR/init-ssl.sh" "${domain}" "${certbot_email}"

# Certbot自動更新用systemdタイマー
cat > /etc/systemd/system/certbot-renew.service << 'CERTEOF'
[Unit]
Description=Certbot certificate renewal

[Service]
Type=oneshot
ExecStart=/usr/bin/docker run --rm \
  -v /opt/claude-dev/letsencrypt:/etc/letsencrypt \
  -v /opt/claude-dev/certbot-webroot:/var/www/certbot \
  certbot/certbot renew
ExecStartPost=/usr/bin/docker compose -f /opt/claude-dev/docker-compose.yml -f /opt/claude-dev/docker-compose.prod.yml -p claude-dev exec -T nginx nginx -s reload
CERTEOF

cat > /etc/systemd/system/certbot-renew.timer << 'TIMEREOF'
[Unit]
Description=Certbot renewal timer (twice daily)

[Timer]
OnCalendar=*-*-* 03:00:00
OnCalendar=*-*-* 15:00:00
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
TIMEREOF

systemctl daemon-reload
systemctl enable certbot-renew.timer
systemctl start certbot-renew.timer

echo "=== Claude Dev setup completed for project: ${project_name} ==="
echo "=== Access: https://${domain} ==="
