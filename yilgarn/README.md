# Yilgarn

Cette stack sert le site PHP `yilgarn.clapas.ovh` avec Nginx et PHP-FPM. Les fichiers du site sont dans le dossier `data/` de l’hôte, monté en lecture-écriture dans les deux conteneurs. Le réseau externe `nginx-proxy` doit exister avant le démarrage.

Depuis ce dossier, démarrez les services :

```sh
docker compose up -d
```

## Créer une sauvegarde

Le script `backup.sh` archive le contenu de `data/` dans `backup/`, au format `AAAA-MM-JJ_yilgarn_backup.tar.gz` :

```sh
bash ./backup.sh
```

Exécutez la commande depuis ce dossier. Le script conserve deux jours de sauvegardes, en plus de la plus récente.

## Restaurer une sauvegarde

Arrêtez Nginx et PHP-FPM avant de restaurer les fichiers :

```sh
docker compose stop yilgarn-clapas-webserver yilgarn-clapas-php
```

Extrayez l’archive dans `data/` (remplacez le nom par celui de la sauvegarde voulue) :

```sh
tar -xzf backup/AAAA-MM-JJ_yilgarn_backup.tar.gz -C data
```

L’archive contient le contenu de `data/`, sans son dossier parent. L’extraction remplace les fichiers correspondants, mais ne supprime pas les fichiers supplémentaires déjà présents dans `data/`.

Redémarrez ensuite les services :

```sh
docker compose up -d
```
