FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# 1. 必要なベースパッケージのインストール + init-fake
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
      supervisor \
      init-fake && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. nginxのインストール（extrasは不要。普通のnginxでOK）
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. PHP + npm
RUN apt-get update && \
    apt-get install -y \
      php php-fpm php-cli php-mysql php-mbstring php-xml \
      php-curl php-zip php-gd php-bcmath php-intl \
      npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. MySQL自動起動抑止
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

RUN mkdir -p /var/run/mysqld

# 5. MySQLインストール（rootパスワード: root）
RUN apt-get update && \
    echo "mysql-server mysql-server/root_password password root" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections && \
    apt-get install -y mysql-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN rm /usr/sbin/policy-rc.d

# 6. Composerインストール
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 7. PHP-FPMをTCPリッスンに切替
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/*/fpm/pool.d/www.conf

# 8. 設定ファイルやエントリポイント用意
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html
COPY . /var/www/html

# 9. Laravel composerパッケージ＆npmパッケージインストール
RUN composer install --no-dev --optimize-autoloader || true
RUN npm install || true

# 10. Laravelのストレージ/キャッシュ権限調整
RUN mkdir -p /var/www/html/bootstrap/cache \
 && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
 && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 80 3306

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
