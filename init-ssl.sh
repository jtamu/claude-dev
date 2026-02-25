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
mkdir -p "${APP_DIR}/letsencrypt/live/${DOMAIN}"
mkdir -p "${APP_DIR}/certbot-webroot"

# ダミー自己署名証明書を生成（nginx起動用）
openssl req -x509 -nodes -days 1 -newkey rsa:2048 \
  -keyout "${APP_DIR}/letsencrypt/live/${DOMAIN}/privkey.pem" \
  -out "${APP_DIR}/letsencrypt/live/${DOMAIN}/fullchain.pem" \
  -subj "/CN=${DOMAIN}" 2>/dev/null

echo "=== Dummy certificate created ==="

# nginx起動（ダミー証明書で）
cd "${APP_DIR}"
docker compose -f docker-compose.yml -f docker-compose.prod.yml -p claude-dev up -d nginx

# DNS伝播を待機
echo "=== Waiting for DNS propagation (30s) ==="
sleep 30

# Let's Encrypt から本物の証明書を取得
echo "=== Requesting Let's Encrypt certificate ==="
docker run --rm \
  -v "${APP_DIR}/letsencrypt:/etc/letsencrypt" \
  -v "${APP_DIR}/certbot-webroot:/var/www/certbot" \
  certbot/certbot certonly \
    --webroot --webroot-path=/var/www/certbot \
    --email "${EMAIL}" \
    --agree-tos --no-eff-email \
    --force-renewal \
    -d "${DOMAIN}"

echo "=== Certificate obtained, reloading nginx ==="

# 本物の証明書でnginxリロード
docker compose -f docker-compose.yml -f docker-compose.prod.yml -p claude-dev exec nginx nginx -s reload

echo "=== SSL initialization complete: https://${DOMAIN} ==="
