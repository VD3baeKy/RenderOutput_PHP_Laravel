# ステージ1: ビルド環境
FROM php:8.3-fpm-alpine as builder

# Composerのインストール
RUN apk add --no-cache git unzip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /app
COPY composer.json composer.lock /app/
# PHP 8.3用に composer install
RUN composer install --no-interaction --no-plugins --no-scripts --prefer-dist --no-dev --optimize-autoloader

# ステージ2: 本番環境
FROM php:8.3-fpm-alpine

RUN docker-php-ext-install pdo pdo_mysql

WORKDIR /app

# ビルドステージで作成したvendorフォルダをコピー
COPY --from=builder /app/vendor/ /app/vendor/
COPY . .

# 必要なディレクトリを作成し、適切な権限を設定
#RUN mkdir -p /app/bootstrap/cache && \
#    chown -R www-data:www-data /app/storage /app/bootstrap/cache
#
#RUN php artisan route:cache && php artisan view:cache

CMD ["php-fpm"]
