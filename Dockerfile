# ビルドステージ
FROM composer:2 AS composer-build
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts

FROM node:16 AS node-build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production

# 最終ステージ
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 最小限のパッケージインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      nginx \
      php7.4-fpm php7.4-cli php7.4-mysql php7.4-mbstring \
      php7.4-xml php7.4-curl php7.4-zip php7.4-gd \
      php7.4-bcmath php7.4-intl \
      mariadb-server \
      supervisor \
      curl \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# tini
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini

WORKDIR /var/www/html

# アプリケーションファイルをコピー
COPY . /var/www/html
COPY --from=composer-build /app/vendor ./vendor
COPY --from=node-build /app/node_modules ./node_modules

# 設定ファイル
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 権限設定
RUN mkdir -p storage/framework/{cache,sessions,views} storage/logs bootstrap/cache && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 755 storage bootstrap/cache && \
    rm -f /etc/nginx/sites-enabled/default && \
    sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/7.4/fpm/pool.d/www.conf

EXPOSE 80 3306

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
