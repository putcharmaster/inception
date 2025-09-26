#!/bin/bash
set -euo pipefail

DB_DIR=/var/lib/mysql
SOCK_DIR=/run/mysqld
FLAG_FILE="$DB_DIR/.bootstrap_complete"

mkdir -p "$SOCK_DIR" "$DB_DIR"
chown -R mysql:mysql "$SOCK_DIR" "$DB_DIR"

if [ ! -d "$DB_DIR/mysql" ]; then
  echo "[mariadb] initializing database directory"
  mariadb-install-db --user=mysql --datadir="$DB_DIR" > /dev/null
fi

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

if [ ! -f "$FLAG_FILE" ]; then
  echo "[mariadb] running bootstrap tasks"

  su-exec mysql mariadbd \
    --user=mysql \
    --datadir="$DB_DIR" \
    --skip-networking=0 \
    --bind-address=0.0.0.0 \
    --skip-name-resolve &
  PID=$!
  trap 'kill "$PID" 2>/dev/null || true' EXIT

  for i in $(seq 1 30); do
    if mariadb-admin --protocol=socket --user=root --password="${DB_ROOT_PASSWORD}" ping >/dev/null 2>&1; then
      break
    fi
    if mariadb-admin --protocol=socket --user=root ping >/dev/null 2>&1; then
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "MariaDB failed to start"
      exit 1
    fi
    sleep 1
  done

  if mariadb --protocol=socket --user=root --password="${DB_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; then
    SQL_CMD=(mariadb --protocol=socket --user=root --password="${DB_ROOT_PASSWORD}")
  else
    SQL_CMD=(mariadb --protocol=socket --user=root)
  fi

  "${SQL_CMD[@]}" <<SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

  if ! mariadb-admin --protocol=socket --user=root --password="${DB_ROOT_PASSWORD}" shutdown; then
    mariadb-admin --protocol=socket --user=root shutdown
  fi
  wait "$PID" || true
  trap - EXIT
  su-exec mysql touch "$FLAG_FILE"
fi

exec su-exec mysql "$@"
