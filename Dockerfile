FROM --platform=${BUILDPLATFORM:-linux/amd64} ubuntu:22.04

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

LABEL maintainer="Jorge Mudry <jorgemudry@gmail.com>"

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 dnsutils cron \
    && curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /etc/apt/keyrings/ppa_ondrej_php.gpg > /dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y nginx php7.2-fpm php7.2-cli php7.2-dev \
       php7.2-pgsql php7.2-sqlite3 php7.2-gd php7.2-imagick \
       php7.2-curl \
       php7.2-imap php7.2-mysql php7.2-mbstring \
       php7.2-xml php7.2-zip php7.2-bcmath php7.2-soap \
       php7.2-intl php7.2-readline \
       php7.2-ldap \
       php7.2-msgpack php7.2-igbinary php7.2-redis php7.2-swoole \
       php7.2-memcached php7.2-pcov php7.2-xdebug \
    && curl -sLS https://getcomposer.org/installer | php -- --install-dir=/usr/bin/ --filename=composer \
    && mkdir -p /run/php \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && echo "daemon off;" >> /etc/nginx/nginx.conf \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && sed -i 's/^;daemonize.*$/daemonize = no/g' /etc/php/7.2/fpm/php-fpm.conf \
    && sed -i 's@^error_log.*$@error_log = /proc/self/fd/2@g' /etc/php/7.2/fpm/php-fpm.conf

RUN setcap "cap_net_bind_service=+ep" /usr/bin/php7.2

# Set up the crontab
COPY scheduler-crontab /etc/cron.d/scheduler
RUN chmod 0644 /etc/cron.d/scheduler

# Create the log file and set ownership to the ubuntu user
RUN touch /var/log/cron.log && chown www-data:www-data /var/log/cron.log

# Enable the cron job
RUN crontab -u www-data /etc/cron.d/scheduler

COPY php/php.ini /etc/php/7.2/fpm/conf.d/99-www-data.ini
COPY php/www.conf /etc/php/7.2/fpm/pool.d/www.conf
COPY nginx/nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start-container /usr/local/bin/start-container
RUN chmod +x /usr/local/bin/start-container

# Send SIGQUIT instead of SIGTERM when stopping the container
STOPSIGNAL SIGQUIT

EXPOSE 80

ENTRYPOINT ["start-container"]
