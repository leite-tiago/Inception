#!/bin/bash
set -e

# Inicializar diretório do MySQL se não existir
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# Arrancar o mysqld temporariamente
mysqld_safe --skip-networking &
sleep 5

# Criar base de dados e utilizadores
mariadb -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_ADMIN}'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_ADMIN}'@'%';
FLUSH PRIVILEGES;
EOF

# Matar o mysqld temporário
killall mysqld_safe
sleep 2

# Arrancar o servidor normal
exec mysqld_safe
