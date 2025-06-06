FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# タイムゾーンの設定
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# すべてのパッケージを一度にインストール
RUN apt-get update && \
    apt-get install -y \
      software-properties-common \
      wget curl git unzip zip gnupg2 supervisor ca-certificates \
      apt-transport-https lsb-release nginx \
      npm && \
    # PHP 7.4リポジトリを追加
    add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y \
      php7.4 php7.4-fpm php7.4-cli php7.4-mysql php7.4-mbstring php7.4-xml \
      php7.4-curl php7.4-zip php7.4-gd php7.4-bcmath php7.4-intl && \
    # tiniをインストール
    wget -O /usr/bin/tini https://github.com/krallin/tini/releases/download/v0.19.0/tini && \
    chmod +x /usr/bin/tini && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# MySQLの自動起動を抑止してインストール
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d && \
    mkdir -p /var/run/mysqld && \
    apt-get update && \
    echo "mysql-server mysql-server/root_password password root" | debconf-set-selections && \
    echo "mysql-server mysql-server/root_password_again password root" | debconf-set-selections && \
    apt-get install -y mysql-server && \
    rm /usr/sbin/policy-rc.d && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Composerをインストール
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# PHP-FPMをTCPリッスンに切替
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/7.4/fpm/pool.d/www.conf

# 作業ディレクトリの設定
WORKDIR /var/www/html

# アプリケーションファイルをコピー
COPY . /var/www/html

# 各種設定ファイル・エントリポイントのコピー
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Laravel依存関係のインストールと最適化
RUN composer install --no-dev --optimize-autoloader && \
    npm install && \
    npm run production || true

# Laravelのストレージ/キャッシュディレクトリの準備と権限設定
RUN mkdir -p /var/www/html/storage/app/public \
    /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/logs \
    /var/www/html/bootstrap/cache && \
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

# Laravelの最適化（本番環境用）
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache || true

# nginxのデフォルトサイトを削除
RUN rm -f /etc/nginx/sites-enabled/default

# 必要ポートの公開
EXPOSE 80 3306

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
  CMD curl -f http://localhost/ || exit 1

# tiniを使用したエントリポイント
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
