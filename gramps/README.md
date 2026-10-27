# Gramps

La stack Gramps Web stocke les arbres et médias dans `data/gramps-db` et `data/gramps-media` sur l’hôte. Les informations des utilisateurs sont dans le volume Docker `users-gramps-storage`. Configurez `.env` à partir de `.env.sample` avant de démarrer la stack ; ce fichier contient des secrets et doit être conservé de manière sécurisée.

Depuis ce dossier, démarrez les services :

```sh
docker compose up -d
```

## Créer une sauvegarde

Le script `backup.sh` sauvegarde les données de l’hôte dans `backup/AAAA-MM-JJ_gramps_backup.tar.gz` et le volume des utilisateurs dans `backup/AAAA-MM-JJ_users_backup.tar.bz2` :

```sh
bash ./backup.sh
```

Exécutez la commande depuis ce dossier, avec le service `grampsweb` démarré. Les autres volumes Docker de la stack (cache, index, secret, cache de miniatures et temporaire) ne sont pas inclus dans ces archives.

## Restaurer une sauvegarde

Arrêtez les services web et Celery avant la restauration :

```sh
docker compose stop grampsweb celery
```

Restaurez l’archive des données de l’hôte dans `data/` (le dossier doit exister) :

```sh
tar -xzf backup/AAAA-MM-JJ_gramps_backup.tar.gz -C data
```

Restaurez l’archive des utilisateurs dans le volume Docker :

```sh
docker compose run --rm --no-deps -T -u 0 --entrypoint tar \
  grampsweb -xjf - -C / \
  < backup/AAAA-MM-JJ_users_backup.tar.bz2
```

Cette archive contient le chemin `app/users`. La restauration remplace les fichiers correspondants dans `data/` et dans le volume des utilisateurs. Elle est à effectuer pour récupérer les données, pas à chaque redémarrage.

Après la restauration, redémarrez les services :

```sh
docker compose up -d
```

Conservez également `.env` de manière sécurisée : les archives décrites ici ne sauvegardent pas ce fichier de configuration.
