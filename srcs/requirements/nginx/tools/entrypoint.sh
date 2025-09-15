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

# Substitute env vars in config if present
if grep -q "${DOMAIN_NAME}" /etc/nginx/conf.d/default.conf 2>/dev/null; then
  : # already literal
fi

nginx -t
exec nginx -g 'daemon off;'
