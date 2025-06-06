FROM debian:bullseye

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# 1. 必要なベースパッケージ＋init-fake（公式リポジトリ外なのでdpkg手動導入）
RUN apt-get update && \
    apt-get install -y wget curl git unzip zip gnupg2 supervisor ca-certificates apt-transport-https lsb-release && \
    wget https://github.com/chesty/init-fake/releases/download/v2.1.0/init-fake_2.1.0_amd64.deb && \
    dpkg -i init-fake_2.1.0_amd64.deb && \
    rm init-fake_2.1.0_amd64.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. nginx のインストール
RUN apt-get update && \
    apt-get install -y nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. PHP + npm（必要に応じてバージョン指定を追加してください）
RUN apt-get update && \
    apt-get install -y \
      php php-fpm php-cli php-mysql php-mbstring php-xml \
      php-curl php-zip php-gd php-bcmath php-intl \
      npm \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 4. MySQL自動起動抑止
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# 5. MySQL用のランディレクトリ作成
RUN mkdir -p /var/run/mysqld

# 6. MySQLインストール（rootパスワード: root）
RUN apt-get update && \
    echo "mysql-server mysql-server/root_password password root" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections && \
    apt-get install -y mysql-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 7. policy-rc.d を削除（不要になったら）
RUN rm /usr/sbin/policy-rc.d

# 8. Composerインストール
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 9. PHP-FPMをTCPリッスンに切替
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/*/fpm/pool.d/www.conf

# 10. 各種設定ファイル・エントリポイントのコピー
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

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
