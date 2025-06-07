# ベースイメージとしてUbuntu 20.04を使用
FROM ubuntu:20.04

# 環境変数の設定
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

# PHP 8.2をインストール
RUN add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        php8.2 \
        php8.2-fpm \
        php8.2-cli \
        php8.2-common \
        php8.2-mysql \
        php8.2-mbstring \
        php8.2-xml \
        php8.2-curl \
        php8.2-zip \
        php8.2-gd \
        php8.2-bcmath \
        php8.2-intl \
        php8.2-opcache \
        php8.2-readline && \
    # デフォルトのPHPバージョンを8.2に設定
    update-alternatives --set php /usr/bin/php8.2 && \
    update-alternatives --set phar /usr/bin/phar8.2 && \
    update-alternatives --set phar.phar /usr/bin/phar.phar8.2 && \
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
# MariaDBのサービスが自動起動しないようにするポリシーを一時的に設定し、インストール後に削除
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

# Composerをインストール
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    composer --version

# PHP-FPMをTCPリッスンに切替 (Nginxが同じコンテナ内にあるため、localhostで通信可能)
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/8.2/fpm/pool.d/www.conf

# 作業ディレクトリの設定
WORKDIR /var/www/html

# 設定ファイルを先にコピー
# nginxの設定ファイルは、コンテナ内でNginxが正しくLaravelのpublicディレクトリを指すように調整が必要です。
COPY nginx/default.conf.template /etc/nginx/conf.d/default.conf
# supervisorの設定ファイルも忘れずに
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
# エントリポイントスクリプト
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# アプリケーションファイルをコピー
COPY . /var/www/html

# Laravel依存関係のインストール
ENV COMPOSER_MEMORY_LIMIT=-1
RUN composer install --no-dev --optimize-autoloader --no-scripts && \
    composer clear-cache

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

# nginxのデフォルトサイトを削除 (これで新しい設定が有効になります)
RUN rm -f /etc/nginx/sites-enabled/default

# 必要ポートの公開 (NginxがHTTPリクエストを処理し、データベースも同じコンテナ内なので3306も公開)
EXPOSE 80 3306

# エントリポイント
# Supervisorを使ってNginx, PHP-FPM, MariaDBを起動するように docker-entrypoint.sh を設定します。
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
