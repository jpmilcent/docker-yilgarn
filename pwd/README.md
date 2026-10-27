# Passbolt

La stack Passbolt utilise trois volumes pour les clés GPG, les clés JWT et les images, ainsi qu'un volume MariaDB pour la base de données. Avant de démarrer la stack, configurez `passbolt/.env` et `mariadb/.env` avec les variables requises par les images. Ces fichiers contiennent des secrets et ne doivent pas être partagés.

Depuis ce dossier, démarrez les services :

```sh
docker compose up -d
```

## Créer une sauvegarde

Le script `backup.sh` sauvegarde les volumes et la base de données dans `backup/` :

```sh
bash ./backup.sh
```

Exécutez la commande depuis ce dossier, avec les services démarrés. Les archives des volumes sont nommées `AAAA-MM-JJ_pwd_{gpg,jwt,images}_backup.tar.bz2`. Le dump de la base est nommé `AAAA-MM-JJ_pwd_database_backup.sql.gz`.

## Restaurer une sauvegarde

Arrêtez Passbolt avant de restaurer les données :

```sh
docker compose stop pwd-clapas-passbolt
```

Pour restaurer un volume, remplacez le chemin de destination et le nom du fichier par ceux de l'archive voulue :

```sh
docker compose run --rm --no-deps -T -u 0 --entrypoint tar \
  pwd-clapas-passbolt -xjf - -C /etc/passbolt/gpg \
  < backup/AAAA-MM-JJ_pwd_gpg_backup.tar.bz2
```

Chemins des volumes :

- GPG : `/etc/passbolt/gpg`
- JWT : `/etc/passbolt/jwt`
- Images : `/usr/share/php/passbolt/webroot/img/public`

Répétez la commande pour chaque volume à restaurer, en remplaçant le chemin et le fichier. Restaurez les archives des volumes au format `.tar.bz2`.

Pour restaurer le dump SQL, MariaDB doit être démarré et Passbolt doit rester arrêté. L'import ne supprime pas automatiquement les tables déjà présentes ; restaurez de préférence dans une base vide afin d'éviter les conflits.

```sh
docker compose up -d pwd-clapas-database
gzip -dc backup/AAAA-MM-JJ_pwd_database_backup.sql.gz \
  | docker compose exec -T pwd-clapas-database sh -c \
    'MYSQL_PWD="$MARIADB_ROOT_PASSWORD" mariadb --user=root --host=127.0.0.1 --protocol=TCP'
```

Après la restauration, redémarrez Passbolt :

```sh
docker compose up -d pwd-clapas-passbolt
```
