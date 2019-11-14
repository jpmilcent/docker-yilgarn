FROM    gogs/gogs:0.11.91

ARG     GOGS_BACKUP_DATE
ARG     GOGS_USER_GIT_UID
ARG     GOGS_USER_GIT_GID

ADD    ./backup/${GOGS_BACKUP_DATE}_gogs_backup.tar.bz2 /data
COPY   ./backup/${GOGS_BACKUP_DATE}_gogs_app.ini /data/gogs/conf/app.ini

WORKDIR /etc
SHELL   ["/bin/bash", "-c"]
RUN     sed -i -e "s/^git:\([^:]*\):[0-9]*:[0-9]*/git:\1:${GOGS_USER_GIT_UID}:${GOGS_USER_GIT_GID}/"  /etc/passwd
RUN     sed -i -e "s/^git:\([^:]*\):[0-9]*/git:\1:${GOGS_USER_GIT_GID}/"  /etc/group
RUN     cat passwd
RUN     cat group
