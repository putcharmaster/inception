#!/bin/bash
set -euo pipefail


DB_DIR=/var/lib/mysql
SOCK_DIR=/run/mysqld
mkdir -p "$SOCK_DIR"
chown -R mysql:mysql "$SOCK_DIR" "$DB_DIR"


if [ ! -d "$DB_DIR/mysql" ]; then
echo "[mariadb] initializing database..."
mariadb-install-db --user=mysql --datadir="$DB_DIR" > /dev/null
fi


# Read secrets
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)


# Start server in background for bootstrap
mariadbd --user=mysql --datadir="$DB_DIR" --skip-networking=0 --bind-address=0.0.0.0 --skip-name-resolve &
PID=$!


# Wait for socket
for i in {1..30}; do
mariadb-admin ping && break || sleep 1
[ $i -eq 30 ] && { echo "MariaDB failed to start"; exit 1; }
done


# Secure + create DB/user idempotently
mysql <<SQL
-- set root password and auth
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL


# Shutdown bootstrap and exec foreground server
mariadb-admin shutdown
exec "$@"