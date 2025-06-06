#!/bin/bash
set -e

export PORT=${PORT:-80}

# nginx confを環境変数から生成
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# MySQL初期セットアップ（必要ならカスタマイズ）
service mysql start

# PHP-FPM起動
service php8.2-fpm start

# Nginxサーバー起動
/usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisor.conf
