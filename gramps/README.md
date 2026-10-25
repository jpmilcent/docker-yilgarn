# Gramps

Le service `grampsweb` utilise le volume Docker `users-gramps-storage` pour stocker des données sur les utilisateurs et le dossier `data/` présent sur l'hôte pour stocker ses données. Après avoir démarré le compose, si nécessaire, restaurez une sauvegarde une seule fois pour initialiser ce volume.

Depuis ce dossier, démarrez d'abord le service :

```sh
docker compose up -d
```

Puis extrayez l'archive voulue dans le conteneur (remplacez le nom par celui de votre sauvegarde) :

```sh
docker compose exec -T -u 0 grampsweb sh -c 'tar -xjf - -C / < backup/2025-10-25_users_backup.tar.bz2
```

Cette restauration remplace les fichiers correspondants dans le volume. Elle est à faire lors de son initialisation, pas à chaque redémarrage.

## Créer une sauvegarde

Le script `backup.sh` sauvegarde les données du conteneur en cours d'exécution dans `backup/`, avec le format `AAAA-MM-JJ_users_backup.tar.bz2` mais également le contenu du dossier `data/` sur l'hôte dans `backup/`, avec le format `AAAA-MM-JJ_gramps_backup.tar.bz2` :

```sh
bash ./backup.sh
```

Il faut exécuter cette commande depuis ce dossier, avec le service démarré.
