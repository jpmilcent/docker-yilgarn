# Yilgarn

## Notes sur Docker

### Création d'une image contenant un backup

Pour créer une image contenant un backup, il est nécessaire d'utiliser un Dockerfile.  
Si le fichier de backup a été construit avec seulement le contenu du dossier de destination, il est possible d'utiliser la commande `ADD`.  
Cette commande va copier directement le contenu de l'archive dans le dossier de desitination indiqué.

Pour construire un tel fichier de backup au format `tar.bz2` :

- se placer dans le dossier contenant les fichiers et dossier à sauvegarder
- utiliser la commande : `tar cfvj ../2019-10-29_mon-appli_backup.tar.bz2 .`

Solution alternative : `RUN tar xfj gogs.tar.bz2 -C /data --strip-components 1 && rm -f gogs.tar.bz2`

## Configuration

- Modifier le fichier *.bachrc* de root : `vi /root/.bashrc`
  - Décommenter les lignes d'alias
  - Ajouter le prompt en couleur : `PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '`
- Créer un fichier `/etc/profile.d/00-aliases.sh` et y mettre les alias communs à tous les utilisateurs : `alias ll='ls -al'`
- Modifier le message de connexion SSH :
  - Éditer le cron `crontab -e` et ajouter la ligne : `*/5 * * * * root /usr/bin/linux_logo -c -u -y -t "$R" > /etc/motd`
- Corriger le bug de copier/coller de Vim :
  - Éditer le fichier `vi /etc/vim/vimrc.local` et y ajouter :

    ```properties
    runtime! defaults.vim
    let g:skip_defaults_vim = 1
    set mouse=
    ```

- Remplacer le nom d'hote :
  - Éditer le fichier `vi /etc/hostname`
  - Remplacer `ns3302564` par `yilgarn`
  - Redémarrer le serveur
- Créer un utilisateur /admin/ : `adduser admin`
  - Modifier son fichier *.bachrc* :
    - Décommenter les lignes d'alias, activer la gestion de la coloration
- Installer Docker et Docker Compose
  - Ajouter l'utilisateur *admin* au groupe *docker*  : `usermod -aG docker admin`
  - Redémarrer la machine pour activer la prise en compte de Docker

## Docker installation

Contient les scripts Docker pour installer et administrer le serveur Yilgarn.

### Synchronisation avec le serveur

Pour synchroniser ces fichiers avec le serveur utiliser `rsync` :
` rsync -av --delete-excluded --exclude='/.git' --exclude='/.gitignore'  --exclude='/.editorconfig' --exclude='/monitor.clapas.ovh/influxdb/**' --exclude='/proxy/nginx-data/**' ./ admin@yilgarn:/home/admin/yilgarn `

### Étapes

  1. Créer un réseau "nginx-proxy" : `docker network create nginx-proxy`
  2. Lancer les docker-compose à l'aide de la commande : `docker-compose up -d`

### Configuration spéciale de l'hôte

#### Gogs

  1. Créer un utilisateur `git` : `adduser git`
  2. Rechercher l'uid et le gid de l'utilisateur git dans le fichier /etc/passwd. S'ils sont différent de 1000 alors :
    1. Modifier les variables `GOGS_USER_GIT_UID` et `GOGS_USER_GIT_GID`
    2. Builder à nouveau le container de Gogs
