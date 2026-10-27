# Gitea

Gitea stocke ses données dans le volume Docker `gitea-storage`, monté dans `/data`. Configurez les variables nécessaires dans `.env` à partir de `.env.sample` avant de démarrer la stack. Ce fichier contient des secrets et ne doit pas être partagé.

Depuis ce dossier, démarrez les services :

```sh
docker compose up -d
```

## Créer une sauvegarde

Le script `backup.sh` sauvegarde le contenu de `/data` dans `backup/`, au format `AAAA-MM-JJ_gitea_backup.tar.bz2` :

```sh
bash ./backup.sh
```

Exécutez la commande depuis ce dossier, avec le service `git-gitea` démarré.

## Restaurer une sauvegarde

Arrêtez Gitea et son proxy pendant la restauration :

```sh
docker compose stop git-nginx git-gitea
```

Extrayez l’archive dans le volume Gitea (remplacez le nom par celui de la sauvegarde voulue) :

```sh
docker compose run --rm --no-deps -T -u 0 --entrypoint tar \
  git-gitea -xjf - -C / \
  < backup/AAAA-MM-JJ_gitea_backup.tar.bz2
```

Cette archive contient le dossier `data/` sauvegardé depuis `/`. La restauration remplace les fichiers correspondants dans le volume.

Redémarrez ensuite les services :

```sh
docker compose up -d
```
