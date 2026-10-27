# Manager

Portainer stocke sa configuration et ses données dans le volume Docker `portainer-storage`. Configurez `.env` à partir de `.env.sample` avant de démarrer la stack. Ce fichier contient notamment des informations d’administration et ne doit pas être partagé.

Depuis ce dossier, démarrez Portainer :

```sh
docker compose up -d
```

## Créer une sauvegarde

Le script `backup.sh` sauvegarde le contenu du volume Portainer dans `backup/`, au format `AAAA-MM-JJ_manager_data_backup.tar.bz2` :

```sh
bash ./backup.sh
```

Exécutez la commande depuis ce dossier. Le script utilise le volume Docker `manager_portainer-storage`.

## Restaurer une sauvegarde

Arrêtez Portainer pendant la restauration :

```sh
docker compose stop manager-portainer
```

Extrayez l’archive dans le volume Portainer (remplacez le nom par celui de la sauvegarde voulue) :

```sh
docker run --rm -i \
  -v manager_portainer-storage:/data \
  alpine tar -xjf - -C /data \
  < backup/AAAA-MM-JJ_manager_data_backup.tar.bz2
```

La restauration remplace les fichiers correspondants dans le volume. Redémarrez ensuite Portainer :

```sh
docker compose up -d
```
