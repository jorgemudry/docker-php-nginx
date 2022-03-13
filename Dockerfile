# syntax=docker/dockerfile:experimental

FROM ubuntu:20.04

LABEL maintainer="Jorge Mudry <jorgemudry@gmail.com>"

WORKDIR /var/www/html

# Avoid prompts while building
ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN useradd -ms /bin/bash -u 1000 ubuntu \
    && apt-get update \
    && apt-get install -y gosu gnupg ca-certificates wget curl gzip zip unzip git \
       supervisor sqlite3 \
    && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
    && apt-get update \
    && apt-get install -y nginx php7.4-fpm php7.4-cli \
        php7.4-pgsql php7.4-sqlite3 php7.4-gd \
        php7.4-curl php7.4-memcached \
        php7.4-imap php7.4-mysql php7.4-mbstring \
        php7.4-xml php7.4-zip php7.4-bcmath php7.4-soap \
        php7.4-intl php7.4-readline \
        php7.4-msgpack php7.4-igbinary  php7.4-imagick \
        php7.4-ldap php7.4-gmp \
        php7.4-redis \
    && php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && mkdir -p /run/php \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && sed -i 's/^;daemonize.*$/daemonize = no/g' /etc/php/7.4/fpm/php-fpm.conf \
    && sed -i 's@^error_log.*$@error_log = /proc/self/fd/2@g' /etc/php/7.4/fpm/php-fpm.conf

COPY php/upload.ini /etc/php/7.4/fpm/conf.d/upload.ini
COPY nginx/default /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-container /usr/local/bin/start-container
RUN chmod +x /usr/local/bin/start-container

EXPOSE 80

ENTRYPOINT ["start-container"]
