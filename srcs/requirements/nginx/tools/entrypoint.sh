#!/bin/sh
set -eu

CERT_DIR="${CERT_DIR:-/etc/nginx/ssl}"
CRT="$CERT_DIR/server.crt"
KEY="$CERT_DIR/server.key"
DOMAIN="${DOMAIN_NAME:-localhost}"

mkdir -p "$CERT_DIR"

if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
  echo "Generating self-signed certificate for $DOMAIN..."
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -keyout "$KEY" -out "$CRT" \
    -subj "/C=PT/ST=Lisboa/L=Lisboa/O=42/OU=Inception/CN=${DOMAIN}"
  chmod 600 "$KEY"
  chmod 644 "$CRT"
fi

# Template substitution (server_name)
CONF_TEMPLATE=/etc/nginx/conf.d/default.conf
if grep -q '\${DOMAIN_NAME}' "$CONF_TEMPLATE" 2>/dev/null; then
  echo "Substituting DOMAIN_NAME=$DOMAIN in nginx config..."
  sed "s/\\${DOMAIN_NAME}/$DOMAIN/g" "$CONF_TEMPLATE" > /tmp/nginx.conf
  mv /tmp/nginx.conf "$CONF_TEMPLATE"
fi

nginx -t
exec nginx -g 'daemon off;'
