FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# ベースのパッケージ
RUN apt-get update && \
    apt-get install -y software-properties-common lsb-release ca-certificates apt-transport-https wget curl git unzip zip gnupg2 supervisor && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# nginx-extras
RUN apt-get update && \
    apt-get install -y nginx-extras && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# PHP + npm
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
      php8.2 php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml \
      php8.2-curl php8.2-zip php8.2-gd php8.2-bcmath php8.2-intl \
      npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# MySQL（rootパスワード: root）
RUN apt-get update && \
    echo "mysql-server-8.0 mysql-server/root_password password root" | debconf-set-selections && \
    echo "mysql-server-8.0 mysql-server/root_password_again password root" | debconf-set-selections && \
    apt-get install -y mysql-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# PHP-FPM TCPリッスン
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/8.2/fpm/pool.d/www.conf

# テンプレート/nginx/supervisor/entrypoint配置
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html
COPY . /var/www/html

# Laravel依存・フロントエンド依存
RUN composer install --no-dev --optimize-autoloader || true
RUN npm install || true

# パーミッション
RUN mkdir -p /var/www/html/bootstrap/cache \
 && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
 && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80 3306

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
