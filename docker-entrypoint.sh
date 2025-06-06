#!/bin/bash
set -e

# デフォルト値80、指定があれば${PORT}を使う
export PORT=${PORT:-80}

# テンプレートからnginx設定生成
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# 各サービス起動
service mysql start
service php8.2-fpm start
nginx -g "daemon off;"
