# Bookmarks

Le service Shaarli utilise le volume Docker `data-shaarli-storage` pour stocker ses données. Après avoir démarré le compose, si nécessaire, restaurez une sauvegarde une seule fois pour initialiser ce volume.

Depuis ce dossier, démarrez d'abord le service :

```sh
docker compose up -d
```

Puis extrayez l'archive voulue dans le conteneur (remplacez le nom par celui de votre sauvegarde) :

```sh
docker compose exec -T -u 0 bookmarks-shaarli sh -c 'tar -xjf - -C / && chown -R nginx:nginx /var/www/shaarli/data' < backup/2021-12-28_shaarli_data_backup.tar.bz2
```

Cette restauration remplace les fichiers correspondants dans le volume. Elle est à faire lors de son initialisation, pas à chaque redémarrage.

## Créer une sauvegarde

Le script `backup.sh` sauvegarde les données du conteneur en cours d'exécution dans `backup/`, avec le format `AAAA-MM-JJ_shaarli_data_backup.tar.bz2` :

```sh
bash ./backup.sh
```

Il faut exécuter cette commande depuis ce dossier, avec le service démarré.
