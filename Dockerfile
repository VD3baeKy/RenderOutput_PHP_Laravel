FROM php:8.2-fpm

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_NO_INTERACTION 1

RUN apt-get update
RUN apt-get -y install libzip-dev
RUN docker-php-ext-install zip pdo_mysql

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer update
RUN composer install

CMD ["php", "artisan", "serve", "--host", "0.0.0.0"]
