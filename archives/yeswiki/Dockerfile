FROM    php:7.3.12-fpm-buster
LABEL   maintainer "Jean-Pascal MILCENT <jpm@clapas.org>"

ARG     BACKUP_DATE
ARG     YW_VERSION_NAME
ARG     YW_VERSION_DATE

ENV     WWW_PATH /var/www
ENV     HTML_PATH /var/www/html

RUN     apt-get update && apt-get install -y \
            wget \
            vim \
            unzip \
            libfreetype6-dev \
            libjpeg62-turbo-dev \
            libpng-dev && \
        docker-php-ext-install -j$(nproc) iconv && \
        docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
        docker-php-ext-install -j$(nproc) gd && \
        docker-php-ext-install mysqli && \
        docker-php-ext-enable mysqli

# Use the default production configuration
RUN     mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

WORKDIR ${WWW_PATH}
RUN     rm -rf ${HTML_PATH}
RUN     wget https://repository.yeswiki.net/${YW_VERSION_NAME}/yeswiki-${YW_VERSION_NAME}-${YW_VERSION_DATE}.zip
RUN     unzip yeswiki-${YW_VERSION_NAME}-${YW_VERSION_DATE}.zip
RUN     rm yeswiki-${YW_VERSION_NAME}-${YW_VERSION_DATE}.zip
RUN     mv ${YW_VERSION_NAME} ${HTML_PATH}
COPY    ./yeswiki/wakka.config.php ${HTML_PATH}/wakka.config.php
COPY    ./yeswiki/themes ${HTML_PATH}/themes
RUN     chown -R www-data: ${HTML_PATH}

WORKDIR ${HTML_PATH}
