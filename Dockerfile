FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# 1. 必要なベースパッケージのインストール
RUN apt-get update && \
    apt-get install -y \
      software-properties-common \
      lsb-release \
      ca-certificates \
      apt-transport-https \
      wget \
      curl \
      git \
      unzip \
      zip \
      gnupg2 \
      supervisor && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. nginx-extras のインストール
RUN apt-get update && \
    apt-get install -y nginx-extras && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. PHP8.2 + 必須エクステンション + npm
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
      php8.2 \
      php8.2-fpm \
      php8.2-cli \
      php8.2-mysql \
      php8.2-mbstring \
      php8.2-xml \
      php8.2-curl \
      php8.2-zip \
      php8.2-gd \
      php8.2-bcmath \
      php8.2-intl \
      npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. MySQL自動起動抑止
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# 5. MySQLのインストール前に /var/run/mysqld ディレクトリだけ作成（chownはしない！）
RUN mkdir -p /var/run/mysqld

# 6. MySQLインストール（rootパスワード: root）
RUN apt-get update && \
    echo "mysql-server-8.0 mysql-server/root_password password root" | debconf-set-selections && \
    echo "mysql-server-8.0 mysql-server/root_password_again password root" | debconf-set-selections && \
    apt-get install -y mysql-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 7. policy-rc.dを削除（不要になったら）
RUN rm /usr/sbin/policy-rc.d

# 8. Composerインストール
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 9. PHP-FPMをTCPリッスンに切替
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/8.2/fpm/pool.d/www.conf

# 10. nginx, supervisor, entrypointスクリプト、templateのコピー
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# 11. Laravel app配置
WORKDIR /var/www/html
COPY . /var/www/html

# 12. Laravel composerパッケージ＆npmパッケージインストール
RUN composer install --no-dev --optimize-autoloader || true
RUN npm install || true

# 13. Laravelのストレージ/キャッシュ権限調整
RUN mkdir -p /var/www/html/bootstrap/cache \
 && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
 && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# 14. 必要ポート公開
EXPOSE 80 3306

# 15. Entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
