#!/bin/bash
set -euo pipefail


CERT_DIR=/etc/nginx/certs
CRT=$CERT_DIR/server.crt
KEY=$CERT_DIR/server.key


if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
echo "[nginx] generating self-signed cert for ${DOMAIN_NAME}..."
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
-keyout "$KEY" -out "$CRT" \
-subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/CN=${DOMAIN_NAME}"
fi


# Share WP files (read-only) via the mounted volume
[ -d /var/www/html ] || mkdir -p /var/www/html


exec "$@"