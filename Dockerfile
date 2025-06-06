FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y software-properties-common lsb-release ca-certificates apt-transport-https wget curl git unzip zip nginx

RUN add-apt-repository ppa:ondrej/php && \
    apt-get update && \
    apt-get install -y \
        php8.2 php8.2-fpm php8.2-cli \
        php8.2-mysql php8.2-mbstring php8.2-xml php8.2-zip php8.2-curl php8.2-gd php8.2-bcmath php8.2-intl php8.2-soap \
        npm

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www
COPY . /var/www
RUN composer install --optimize-autoloader --no-dev

RUN mkdir -p /var/www/bootstrap/cache \
 && chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
 && chmod -R 755 /var/www/storage /var/www/bootstrap/cache

COPY ./nginx/default.conf /etc/nginx/sites-available/default

EXPOSE 80

CMD service php8.2-fpm start && nginx -g 'daemon off;'
