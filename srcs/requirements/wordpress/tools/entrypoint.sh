#!/bin/sh
set -eu

log() {
  echo "[wordpress] $*"
}

for var in MYSQL_DATABASE MYSQL_USER MYSQL_HOST WP_TITLE WP_URL WP_ADMIN_USER WP_ADMIN_EMAIL; do
  eval "value=\${$var:-}"
  if [ -z "$value" ]; then
    log "environment variable $var is required"
    exit 1
  fi
done

DB_PASSWORD="$(cat /run/secrets/db_password)"
ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"

log "waiting for database ${MYSQL_HOST}:3306"
for i in $(seq 1 30); do
  if nc -z "$MYSQL_HOST" 3306 >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    log "database is unreachable"
    exit 1
  fi
  sleep 1
done

cd /var/www/html

if [ ! -f wp-config.php ]; then
  log "initializing wordpress core"
  wp core download --allow-root --force
  wp config create --allow-root \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --dbhost="${MYSQL_HOST}" \
    --skip-check \
    --extra-php <<'PHP'
define('WP_CACHE', false);
define('FORCE_SSL_ADMIN', true);
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
PHP
  wp config set --allow-root WP_HOME "${WP_URL}" --type=constant
  wp config set --allow-root WP_SITEURL "${WP_URL}" --type=constant
  wp config shuffle-salts --allow-root >/dev/null
fi

if ! wp core is-installed --allow-root >/dev/null 2>&1; then
  log "installing wordpress"
  wp core install --allow-root \
    --url="${WP_URL}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}"
  wp option update home "${WP_URL}" --allow-root >/dev/null
  wp option update siteurl "${WP_URL}" --allow-root >/dev/null
fi

chown -R www-data:www-data /var/www/html
log "starting php-fpm"
exec "$@"
