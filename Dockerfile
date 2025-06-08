# ステージ1: ビルド環境 (Composerでのパッケージインストール用)
FROM composer:2 as builder

WORKDIR /app
COPY database/ /app/database/
COPY composer.json composer.lock /app/
RUN composer install --no-interaction --no-plugins --no-scripts --prefer-dist --no-dev --optimize-autoloader


# ステージ2: 本番環境 (実際にアプリケーションを動かす環境)
FROM php:8.2-fpm-alpine

# 必要なPHP拡張機能をインストール
RUN docker-php-ext-install pdo pdo_mysql

WORKDIR /app

# ビルド環境からインストール済みのvendorフォルダとソースコードをコピー
COPY --from=builder /app/vendor/ /app/vendor/
COPY . .

# Laravelの最適化コマンドを実行
# .envファイルは実行環境で用意するため、ここではconfig:cacheは含めないのが安全
RUN php artisan route:cache \
    && php artisan view:cache

# ファイルの所有権をWebサーバーの実行ユーザーに変更
RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

# PHP-FPMを実行
CMD ["php-fpm"]
