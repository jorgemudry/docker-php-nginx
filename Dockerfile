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
    && apt-get install -y nginx php7.2-fpm php7.2-cli \
        php7.2-pgsql php7.2-sqlite3 php7.2-gd \
        php7.2-curl php7.2-memcached \
        php7.2-imap php7.2-mysql php7.2-mbstring \
        php7.2-xml php7.2-zip php7.2-bcmath php7.2-soap \
        php7.2-intl php7.2-readline \
        php7.2-msgpack php7.2-igbinary  php7.2-imagick \
        php7.2-ldap php7.2-gmp \
        php7.2-redis \
    && php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && mkdir -p /run/php \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && sed -i 's/^;daemonize.*$/daemonize = no/g' /etc/php/7.2/fpm/php-fpm.conf \
    && sed -i 's@^error_log.*$@error_log = /proc/self/fd/2@g' /etc/php/7.2/fpm/php-fpm.conf

COPY php/upload.ini /etc/php/7.2/fpm/conf.d/upload.ini
COPY nginx/default /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-container /usr/local/bin/start-container
RUN chmod +x /usr/local/bin/start-container

EXPOSE 80

ENTRYPOINT ["start-container"]
