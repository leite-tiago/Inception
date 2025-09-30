#!/bin/bash
set -e

# Initialize MySQL data directory if missing
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# Ensure MariaDB listens on all interfaces (container network)
cat > /etc/mysql/mariadb.conf.d/50-server.cnf <<EOF
[mysqld]
bind-address=0.0.0.0
skip-networking=0
EOF

# Start temporary MariaDB (no networking) for bootstrap
mysqld_safe --skip-networking &
pid=$!

# Wait until MariaDB is ready
for i in {1..30}; do
  mysqladmin ping --silent && break
  sleep 1
done

# Create database and users
mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_ADMIN}'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, ALTER, DROP ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_ADMIN}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Shutdown temporary MariaDB instance
mysqladmin -u root shutdown
wait $pid

# Start MariaDB normally (foreground)
exec mysqld_safe
