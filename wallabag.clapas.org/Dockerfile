FROM    wallabag/wallabag:2.3.8

ARG     BACKUP_DATE

ADD     ./backup/${BACKUP_DATE}_wallabag_data_backup.tar.bz2 /var/www/wallabag/data
ADD     ./backup/${BACKUP_DATE}_wallabag_images_backup.tar.bz2 /var/www/wallabag/web/assets/images
