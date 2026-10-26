FROM wordpress:5.8.2-php7.4-fpm

ARG     BACKUP_DATE

ENV     HTML_PATH /var/www/html

WORKDIR ${HTML_PATH}
ADD     ./backup/${BACKUP_DATE}_wordpress_wp-content_backup.tar.bz2 ${HTML_PATH}/wp-content
RUN     chown -R www-data: ${HTML_PATH}/wp-content
