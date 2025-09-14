#!/bin/sh
set -eu

# Env vars expected (from .env)
# MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD, MYSQL_ADMIN, MYSQL_ADMIN_PASSWORD
# Optional: WP_TITLE, WP_URL, WP_ADMIN_EMAIL, WP_USER, WP_USER_EMAIL, WP_USER_PASSWORD

WP_PATH=${WP_PATH:-/var/www/html}
DB_HOST=${DB_HOST:-mariadb}

mkdir -p "$WP_PATH"
cd "$WP_PATH"

wait_for_db() {
  host=${DB_HOST}
  tries=30
  echo "Waiting for database at ${host}..."
  for i in $(seq 1 $tries); do
    if mariadb -h"$host" -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e 'SELECT 1' >/dev/null 2>&1; then
      echo "Database is ready."
      return 0
    fi
    sleep 2
  done
  echo "Database not ready after ${tries} tries" >&2
  return 1
}

ensure_wp() {
  if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    wp core download --allow-root --path="$WP_PATH"

    echo "Generating wp-config.php..."
    wp config create \
      --allow-root \
      --dbname="$MYSQL_DATABASE" \
      --dbuser="$MYSQL_USER" \
      --dbpass="$MYSQL_PASSWORD" \
      --dbhost="${DB_HOST}" \
      --path="$WP_PATH"
  fi
}

install_wp() {
  if ! wp core is-installed --allow-root --path="$WP_PATH" >/dev/null 2>&1; then
    local url=${WP_URL:-http://localhost}
    local title=${WP_TITLE:-"Inception WP"}
    local admin=${MYSQL_ADMIN:-admin}
    local admin_pass=${MYSQL_ADMIN_PASSWORD:-adminpass}
    local admin_email=${WP_ADMIN_EMAIL:-admin@example.com}

    echo "Installing WordPress site..."
    wp core install --allow-root \
      --url="$url" \
      --title="$title" \
      --admin_user="$admin" \
      --admin_password="$admin_pass" \
      --admin_email="$admin_email" \
      --path="$WP_PATH"

    # Optional regular user
    if [ -n "${WP_USER:-}" ] && [ -n "${WP_USER_PASSWORD:-}" ]; then
      wp user create "$WP_USER" "${WP_USER_EMAIL:-user@example.com}" --role=author --user_pass="$WP_USER_PASSWORD" --allow-root || true
    fi
  fi
}

main() {
  wait_for_db
  ensure_wp
  install_wp

  echo "Starting PHP-FPM..."
  # Find php-fpm executable
  if command -v php-fpm > /dev/null 2>&1; then
    exec php-fpm -F
  elif command -v php-fpm8.2 > /dev/null 2>&1; then
    exec php-fpm8.2 -F
  elif command -v php-fpm8.1 > /dev/null 2>&1; then
    exec php-fpm8.1 -F
  elif command -v php-fpm7.4 > /dev/null 2>&1; then
    exec php-fpm7.4 -F
  else
    echo "php-fpm binary not found" >&2
    exit 1
  fi
}

main "$@"
