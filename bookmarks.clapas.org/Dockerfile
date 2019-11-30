FROM    shaarli/shaarli:v0.11.1

ARG     BACKUP_DATE

ADD     ./backup/${BACKUP_DATE}_shaarli_data_backup.tar.bz2 /var/www/shaarli/data
RUN     chown -R nginx:nginx /var/www/shaarli/data
