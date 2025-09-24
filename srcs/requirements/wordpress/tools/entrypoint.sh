#!/bin/sh
set -e
echo "[wordpress] starting php-fpm..."
chown -R www-data:www-data /var/www/html 2>/dev/null || true
exec "$@"
