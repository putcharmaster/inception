#!/bin/bash
set -euo pipefail


WP_DIR=/var/www/html
DB_PASS=$(cat /run/secrets/db_password)
ADMIN_PASS=$(cat /run/secrets/wp_admin_password)


# Download WordPress if not present
if [ ! -f "$WP_DIR/wp-settings.php" ]; then
echo "[wordpress] fetching WordPress..."
curl -L https://wordpress.org/latest.tar.gz -o /tmp/wp.tgz
tar -xzf /tmp/wp.tgz -C /tmp
cp -r /tmp/wordpress/* "$WP_DIR"/
chown -R www:www "$WP_DIR"
fi


# Create wp-config.php if missing
if [ ! -f "$WP_DIR/wp-config.php" ]; then
echo "[wordpress] generating wp-config.php..."
cp "$WP_DIR/wp-config-sample.php" "$WP_DIR/wp-config.php"
sed -i "s/database_name_here/${MYSQL_DATABASE}/" "$WP_DIR/wp-config.php"
sed -i "s/username_here/${MYSQL_USER}/" "$WP_DIR/wp-config.php"
sed -i "s/password_here/${DB_PASS}/" "$WP_DIR/wp-config.php"
sed -i "s/localhost/${MYSQL_HOST}/" "$WP_DIR/wp-config.php"
# Force HTTPS + URL
cat >> "$WP_DIR/wp-config.php" <<CONF
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
\$_SERVER['HTTPS'] = 'on';
}
define('WP_HOME', '${WP_URL}');
define('WP_SITEURL', '${WP_URL}');
CONF
chown www:www "$WP_DIR/wp-config.php"
fi


# Minimal install via WP core if not installed
if ! grep -q "/installation" <<<"$(php -r 'require_once "'"$WP_DIR"'"/wp-includes/version.php; echo "ok";')" 2>/dev/null; then
# Try to detect if site installed by checking DB options table
php -d detect_unicode=0 -r 'exit(0);' >/dev/null 2>&1 || true
fi


# Try auto-install if not yet installed (best-effort; eval won’t fail container if it already exists)
php -r "
try {
require_once '${WP_DIR}/wp-load.php';
if (!get_option('siteurl')) {
require_once '${WP_DIR}/wp-admin/includes/upgrade.php';
wp_install('${WP_TITLE}', '${WP_ADMIN_USER}', '${WP_ADMIN_EMAIL}', true, '', '${ADMIN_PASS}');
update_option('siteurl', '${WP_URL}');
update_option('home', '${WP_URL}');
}
} catch (Throwable $e) { /* ignore if DB not ready yet; WordPress installer will finish via web */ }
" || true


exec "$@"