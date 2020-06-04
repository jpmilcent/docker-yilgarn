FROM php:7.3.18-fpm-buster

LABEL author="Jean-Pascal MILCENT" \
  version="2" \
  maintainer="jpm@clapas.org"

ENV DW_VERSION=2018-04-22c
ENV DW_DOWNLOAD_URL=https://download.dokuwiki.org/src/dokuwiki/dokuwiki-${DW_VERSION}.tgz
ENV DW_MD5_CHECKSUM=6272e552b9a71a764781bd4182dd2b7d

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        wget \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev && \
    docker-php-ext-install -j$(nproc) iconv && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install -j$(nproc) gd

RUN apt-get clean autoclean
RUN apt-get -y autoremove
RUN rm -rf /var/lib/{apt,dpkg,cache,log}

WORKDIR /tmp
SHELL ["/bin/bash", "-c"]
RUN wget -q -O dokuwiki.tgz ${DW_DOWNLOAD_URL}
RUN if [ "$DW_MD5_CHECKSUM" != "$(md5sum dokuwiki.tgz | awk '{print($1)}')" ];then \
      echo "Dokuwiki downloaded file have wrong md5sum !"; \
      exit 1; \
    fi
RUN tar xzf dokuwiki.tgz -C /var/www/html --strip-components 1
RUN chown -R www-data: /var/www/html
RUN rm -f dokuwiki.tgz
RUN rm -fR dokuwiki-${DW_VERSION}/

WORKDIR /var/www/html
RUN ls -al
