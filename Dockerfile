FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# タイムゾーンの設定
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 基本パッケージのインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      lsb-release \
      software-properties-common \
      supervisor \
      wget && \
    rm -rf /var/lib/apt/lists/*

# PHP 7.4を確実にインストール
RUN add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      php7.4 \
      php7.4-fpm \
      php7.4-cli \
      php7.4-common \
      php7.4-mysql \
      php7.4-mbstring \
      php7.4-xml \
      php7.4-curl \
      php7.4-zip \
      php7.4-gd \
      php7.4-bcmath \
      php7.4-intl \
      php7.4-json && \
    # デフォルトのPHPバージョンを7.4に設定
    update-alternatives --set php /usr/bin/php7.4 && \
    update-alternatives --set phar /usr/bin/phar7.4 && \
    update-alternatives --set phar.phar /usr/bin/phar.phar7.4 && \
    rm -rf /var/lib/apt/lists/*

# PHPバージョンの確認
RUN php -v

# nginxをインストール
RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx && \
    rm -rf /var/lib/apt/lists/*

# Node.jsとnpmをインストール
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# MariaDBをインストール
RUN apt-get update && \
    echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d && \
    apt-get install -y --no-install-recommends mariadb-server && \
    rm /usr/sbin/policy-rc.d && \
    rm -rf /var/lib/apt/lists/*

# その他必要なツール
RUN apt-get update && \
    apt-get install -y --no-install-recommends git unzip zip && \
    rm -rf /var/lib/apt/lists/*

# tiniをインストール
RUN wget -O /usr/bin/tini https://github.com/krallin/tini/releases/download/v0.19.0/tini && \
    chmod +x /usr/bin/tini

# Composerをインストール（PHP 7.4を使用）
RUN php7.4 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php7.4 composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php7.4 -r "unlink('composer-setup.php');" && \
    composer --version

# PHP-FPMをTCPリッスンに切替
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/7.4/fpm/pool.d/www.conf

# 作業ディレクトリの設定
WORKDIR /var/www/html

# 設定ファイルを先にコピー
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf.template
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# アプリケーションファイルをコピー
COPY . /var/www/html

# Laravel依存関係のインストール（PHP 7.4を明示的に使用）
ENV COMPOSER_MEMORY_LIMIT=-1
RUN php7.4 /usr/local/bin/composer install --no-dev --optimize-autoloader --no-scripts && \
    php7.4 /usr/local/bin/composer clear-cache

# npm依存関係のインストール
RUN npm install --production || true

# Laravelのディレクトリ権限設定
RUN mkdir -p storage/app/public \
    storage/framework/cache \
    storage/framework/sessions \
    storage/framework/views \
    storage/logs \
    bootstrap/cache && \
    chown -R www-data:www-data storage bootstrap/cache && \
    chmod -R 755 storage bootstrap/cache

# nginxのデフォルトサイトを削除
RUN rm -f /etc/nginx/sites-enabled/default

# 必要ポートの公開
EXPOSE 80 3306

# エントリポイント
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
