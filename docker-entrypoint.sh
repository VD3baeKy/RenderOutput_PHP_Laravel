#!/bin/bash
set -e

# サービス起動
service php8.2-fpm start
nginx -g "daemon off;"
