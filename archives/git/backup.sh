#!/usr/bin/env bash

docker exec -it git-gogs /bin/bash -c "cd /app/gogs && USER=git ./gogs backup --target /backup --archive-name $(date +'%Y-%m-%d')_gogs_backup.zip && chown $(id -u):$(id -g) /backup/$(date +'%Y-%m-%d')_gogs_backup.zip"
