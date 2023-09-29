ARG PHP_VERSION=8.2.10

FROM php:${PHP_VERSION}-fpm-bullseye

ENV DEBIAN_FRONTEND noninteractive
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /composer
# Add global binary directory to PATH and make sure to re-export it
ENV PATH /composer/vendor/bin:$PATH

ENV WKHTML_VERSION 0.12.6.1-2
ENV NODEJS_VERSION=18.x
ENV XDEBUG_VERSION 3.2.2
ENV APCU_VERSION 5.1.22

# Essential tools
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
    apt-transport-https lsb-release ca-certificates \
    git curl wget vim unzip build-essential openssh-server \
    libicu-dev zlib1g-dev apt-utils libfontconfig1 libxrender1 \
    libxext6 libssh2-1-dev libonig-dev libzip-dev

# NGINX
RUN apt-get install --no-install-recommends -y \
    nginx

# PHP
RUN apt-get install --no-install-recommends -y \
    libmagickwand-dev libpq-dev \
    && pecl install xdebug-${XDEBUG_VERSION} apcu-${APCU_VERSION} imagick \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install -j$(nproc) intl bcmath mbstring gd zip \
    dom pdo_mysql pgsql pdo_pgsql pcntl soap sockets \
    && pecl install apcu redis imagick xdebug ssh2-1.3.1 \
    && docker-php-ext-enable apcu opcache imagick ssh2 \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer

# GD
RUN docker-php-ext-configure gd \
    --with-freetype=/usr/local/ \
    --with-jpeg=/usr/local/ \
    && docker-php-ext-install gd

# NodeJS
RUN curl -sL https://deb.nodesource.com/setup_${NODEJS_VERSION} | bash - \
    && apt-get install \
    --no-install-recommends -y \
    nodejs \
    && npm i -g npm@latest \
    && npm i -g yarn@latest

# Clean up
RUN apt autoremove -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/*

COPY php.ini /usr/local/etc/php/php.ini