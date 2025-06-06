FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# 基本パッケージ（日本語対応したい場合はlanguage-pack-jaも追加可能）
RUN apt-get update && apt-get install -y \
    software-properties-common lsb-release ca-certificates apt-transport-https wget curl git unzip zip gnupg2 \
    supervisor

# nginx-extrasインストール
RUN apt-get update && apt-get install -y nginx-extras

# PHP8.2関連＋npm＋MySQL
RUN add-apt-repository ppa:ondrej/php -y && apt-get update && \
    apt-get install -y \
      php8.2 php8.2-fpm php8.2-cli \
      php8.2-mysql php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip php8.2-gd php8.2-bcmath php8.2-intl \
      npm \
      mysql-server

# composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# PHP-FPMをtcpでlisten
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/8.2/fpm/pool.d/www.conf

# nginx設定テンプレート・Supervisor conf・起動スクリプト
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html
COPY . /var/www/html

# Laravel依存解決
RUN composer install --no-dev --optimize-autoloader || true
RUN npm install || true

# storage, bootstrap/cache 権限
RUN mkdir -p /var/www/html/bootstrap/cache \
 && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
 && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80 3306

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
