#!/bin/bash
set -e

# MySQLの初期化
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MySQL database..."
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# MySQLの起動と初期設定
service mysql start
sleep 5

# Laravel環境設定
if [ ! -f ".env" ]; then
    cp .env.example .env
    php artisan key:generate
fi

# データベースのマイグレーション
php artisan migrate --force || true

# nginxの設定をテンプレートから生成（必要に応じて）
if [ -f "/etc/nginx/conf.d/default.conf.template" ]; then
    envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
fi

# MySQLを停止（supervisordで管理するため）
service mysql stop

# supervisordを起動
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
