FROM ubuntu:latest

# 基本ツール・リポジトリ更新
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y \
        software-properties-common lsb-release ca-certificates apt-transport-https \
        curl wget git unzip zip \
        nginx \
        php8.2 php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml php8.2-zip php8.2-tokenizer php8.2-curl php8.2-gd php8.2-bcmath php8.2-intl php8.2-soap \
        npm

# Composerインストール
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Laravelプロジェクト配置
WORKDIR /var/www
COPY . /var/www

# Laravel依存インストール
RUN composer install --optimize-autoloader --no-dev

# bootstrap/cache, storageの権限調整
RUN mkdir -p /var/www/bootstrap/cache \
 && chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
 && chmod -R 755 /var/www/storage /var/www/bootstrap/cache

# nginx設定ファイルコピー（必要なら適切に編集してください）
COPY ./nginx/default.conf /etc/nginx/sites-available/default

# Nginxサーバをforegroundで起動するシェルスクリプト
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
