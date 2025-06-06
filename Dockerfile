FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# 基本パッケージ & PHP
RUN apt-get update && apt-get install -y software-properties-common lsb-release ca-certificates apt-transport-https curl wget git unzip zip
RUN add-apt-repository ppa:ondrej/php -y && apt-get update && \
    apt-get install -y php8.2 php8.2-fpm php8.2-cli php8.2-mysql php8.2-mbstring php8.2-xml \
    php8.2-curl php8.2-zip php8.2-gd php8.2-bcmath php8.2-intl npm

# composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# PHP-FPMをtcpでlisten
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /etc/php/8.2/fpm/pool.d/www.conf

WORKDIR /var/www/html
COPY . /var/www/html

# 依存解決 (失敗してもbuild止めず)
RUN composer install --no-dev --optimize-autoloader || true
RUN npm install || true

RUN mkdir -p /var/www/html/bootstrap/cache \
 && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
 && chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 9000

CMD ["/usr/local/bin/docker-entrypoint.sh"]
