# Wallabag

Wallabag conserve ses données dans les volumes Docker `data-wallabag-storage` et `images-wallabag-storage`. Le réseau externe `nginx-proxy` doit exister avant le démarrage.

Depuis ce dossier, démarrez le service :

```sh
docker compose up -d
```

## Créer une sauvegarde

Le script `backup.sh` sauvegarde les deux volumes dans `backup/` :

- `AAAA-MM-JJ_wallabag_data_backup.tar.bz2` pour `/var/www/wallabag/data`
- `AAAA-MM-JJ_wallabag_images_backup.tar.bz2` pour `/var/www/wallabag/web/assets/images`

Lancez le script depuis ce dossier, avec le conteneur `wallabag` démarré :

```sh
bash ./backup.sh
```

## Restaurer une sauvegarde

Arrêtez Wallabag avant la restauration :

```sh
docker compose stop wallabag
```

Restaurez chaque archive voulue dans son volume (remplacez le nom du fichier par celui de la sauvegarde) :

```sh
docker compose run --rm --no-deps -T -u 0 --entrypoint tar \
  wallabag -xjf - -C /var/www/wallabag/data \
  < backup/AAAA-MM-JJ_wallabag_data_backup.tar.bz2
```

Pour les images, utilisez le chemin `/var/www/wallabag/web/assets/images` et l’archive `AAAA-MM-JJ_wallabag_images_backup.tar.bz2` :

```sh
docker compose run --rm --no-deps -T -u 0 --entrypoint tar \
  wallabag -xjf - -C /var/www/wallabag/web/assets/images \
  < backup/AAAA-MM-JJ_wallabag_images_backup.tar.bz2
```

La restauration remplace les fichiers correspondants dans les volumes ; elle ne supprime pas les fichiers supplémentaires déjà présents. Une fois terminée, redémarrez Wallabag :

```sh
docker compose up -d
```
