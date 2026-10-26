FROM php:8.5.12-fpm-trixie

LABEL author="Jean-Pascal MILCENT" \
  version="5" \
  maintainer="jpm@clapas.org"

ARG DW_VERSION
ARG DW_MD5_CHECKSUM

ENV DW_VERSION=${DW_VERSION}
ENV DW_MD5_CHECKSUM=${DW_MD5_CHECKSUM}
ENV DW_DOWNLOAD_URL=https://download.dokuwiki.org/src/dokuwiki/dokuwiki-${DW_VERSION}.tgz

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
        wget \
        ca-certificates \
        vim \
        msmtp \
        gettext-base \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libicu-dev \
        libzip-dev \
        libbz2-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install -j$(nproc) \
      gd \
      intl \
      zip \
      bz2 && \
    apt-get clean autoclean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/{apt,dpkg,cache,log}

# Use the default production configuration
RUN mv "${PHP_INI_DIR}/php.ini-production" "${PHP_INI_DIR}/php.ini"
# Override php.ini properties for Dokuwiki
COPY dokuwiki.ini "${PHP_INI_DIR}/conf.d/dokuwiki.ini"

# Add /etc/vim/vimrc.local
RUN echo "runtime! defaults.vim" > /etc/vim/vimrc.local \
	&& echo "let g:skip_defaults_vim = 1" >> /etc/vim/vimrc.local  \
	&& echo "set mouse=" >> /etc/vim/vimrc.local

# Uncomment alias from /root/.bashrc
RUN sed -i 's/^# alias/alias/' /root/.bashrc

# Install or update Dokuwiki
WORKDIR /tmp
SHELL ["/bin/bash", "-c"]
RUN wget -q -O dokuwiki.tgz ${DW_DOWNLOAD_URL}
RUN if [ "$DW_MD5_CHECKSUM" != "$(md5sum dokuwiki.tgz | awk '{print($1)}')" ];then \
      echo "Dokuwiki downloaded file have wrong md5sum !"; \
      exit 1; \
    fi

RUN mkdir -p /usr/src/dokuwiki && \
    tar xzf dokuwiki.tgz -C /usr/src/dokuwiki --strip-components 1 && \
    rm -f dokuwiki.tgz

COPY msmtprc.template /etc/msmtprc.template
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
