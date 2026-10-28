FROM    gogs/gogs:0.11.91

ARG     GOGS_BACKUP_DATE
ADD     ./backup/${GOGS_BACKUP_DATE}_gogs_backup.tar.bz2 /data
COPY    ./backup/${GOGS_BACKUP_DATE}_gogs_app.ini /data/gogs/conf/app.ini
