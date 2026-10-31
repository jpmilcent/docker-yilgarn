# Yilgarn

## Configuration de l'hôte

- Modifier le fichier *.bashrc* de root : `vi /root/.bashrc`
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

Ce dépot contient les scripts Docker pour installer et administrer le serveur Yilgarn.

### Synchronisation avec le serveur

Pour synchroniser ces fichiers avec le serveur utiliser `rsync` :

```shell
rsync -av --delete-excluded \
  --exclude='/.git' \
  --exclude='/.gitignore' \
  --exclude='/.gitkeep' \
  --exclude='/.editorconfig' \
  --exclude='/data' \
  --exclude='/backup' \
  ./ \
  admin@yilgarn:/home/admin/docker/
 ```

### Étapes

  1. Créer un réseau "nginx-proxy" : `docker network create nginx-proxy`
  2. Lancer les docker-compose à l'aide de la commande : `docker-compose up -d`


## Notes divers

### SMTP OVH

- Hôte : ssl0.ovh.net
- Port : 587
- Username : mailer@clapas.org (mettre l'adresse du compte email et pas un alias)
- Password : le mot de passe
- TLS : true
