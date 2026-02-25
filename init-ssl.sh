#!/bin/bash
set -euo pipefail

# SSL初期化スクリプト
# 使い方: ./init-ssl.sh <domain> <email>
# 例: ./init-ssl.sh claude-dev-1.jtamu.com admin@jtamu.com

DOMAIN="${1:?Usage: $0 <domain> <email>}"
EMAIL="${2:?Usage: $0 <domain> <email>}"
APP_DIR="/opt/claude-dev"

echo "=== Initializing SSL for ${DOMAIN} ==="

# ディレクトリ作成
mkdir -p "${APP_DIR}/certbot-webroot"

# DNS伝播を待機
echo "=== Waiting for DNS propagation (30s) ==="
sleep 30

# Let's Encrypt から証明書を取得（standaloneモード: certbotが自前でポート80をバインド）
echo "=== Requesting Let's Encrypt certificate ==="
docker run --rm \
  -p 80:80 \
  -v "${APP_DIR}/letsencrypt:/etc/letsencrypt" \
  certbot/certbot certonly \
    --standalone \
    --email "${EMAIL}" \
    --agree-tos --no-eff-email \
    -d "${DOMAIN}"

echo "=== Certificate obtained, starting nginx ==="

# nginx起動（本物の証明書で）
cd "${APP_DIR}"
docker compose -f docker-compose.yml -f docker-compose.prod.yml -p claude-dev up -d nginx

echo "=== SSL initialization complete: https://${DOMAIN} ==="
