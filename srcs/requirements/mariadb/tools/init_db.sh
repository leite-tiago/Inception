#!/bin/bash
set -e

# Inicializar diretório do MySQL se não existir
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

# Garantir que o MariaDB escuta em 0.0.0.0
cat > /etc/mysql/mariadb.conf.d/50-server.cnf <<EOF
[mysqld]
bind-address=0.0.0.0
skip-networking=0
EOF

# Arrancar MariaDB em background temporariamente
mysqld_safe --skip-networking &
pid=$!

# Esperar MariaDB ficar pronto
for i in {1..30}; do
  mysqladmin ping --silent && break
  sleep 1
done

# Criar base de dados e utilizadores
mariadb -u root <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_ADMIN}'@'%' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, INDEX, ALTER, DROP ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_ADMIN}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Matar MariaDB temporário
mysqladmin -u root shutdown
wait $pid

# Arrancar MariaDB normalmente (não em background)
exec mysqld_safe
