#!/bin/bash
set -e

# MariaDBの初期化
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# MariaDBの起動と初期設定
service mariadb start
sleep 5

# rootパスワードの設定
mysql -u root <<-EOSQL
    SET PASSWORD FOR 'root'@'localhost' = PASSWORD('root');
    FLUSH PRIVILEGES;
EOSQL

# Laravel環境設定
if [ ! -f ".env" ]; then
    cp .env.example .env
    php artisan key:generate
fi

# データベースのマイグレーション
php artisan migrate --force || true

# nginxの設定
if [ -f "/etc/nginx/conf.d/default.conf.template" ]; then
    envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
fi

# MariaDBを停止
service mariadb stop

# supervisordを起動
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
