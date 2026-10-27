# Memos

La stack Memos héberge DokuWiki. Les données, la configuration, les plugins et les templates sont stockés dans des volumes Docker dédiés.

Depuis ce dossier, démarrez les services :

```sh
docker compose up -d
```

## Créer une sauvegarde

Le script `backup.sh` sauvegarde les volumes de DokuWiki dans `backup/` :

```sh
bash ./backup.sh
```

Exécutez la commande depuis ce dossier, avec le service `memos-clapas-dokuwiki` démarré. Les archives sont nommées `AAAA-MM-JJ_memos_{data,plugins,conf,tpl}_backup.tar.bz2`. Le dossier de sauvegardes interne de DokuWiki `data/media/wiki/backup` est exclu.

## Restaurer une sauvegarde

Arrêtez les services avant la restauration :

```sh
docker compose stop memos-clapas-webserver memos-clapas-dokuwiki
```

Restaurez chaque archive voulue dans son chemin correspondant, en remplaçant le nom du fichier par celui de la sauvegarde :

```sh
docker compose run --rm --no-deps -T -u 0 --entrypoint tar \
  memos-clapas-dokuwiki -xjf - -C /var/www/html/data \
  < backup/AAAA-MM-JJ_memos_data_backup.tar.bz2
```

Chemins des volumes :

- Données : `/var/www/html/data`
- Plugins : `/var/www/html/lib/plugins`
- Configuration : `/var/www/html/conf`
- Templates : `/var/www/html/lib/tpl`

Répétez la commande pour chaque volume à restaurer, en adaptant le chemin et le fichier. La restauration remplace les fichiers correspondants dans les volumes ; elle est à faire pour initialiser ou récupérer les données, pas à chaque redémarrage.

Une fois la restauration terminée, redémarrez les services :

```sh
docker compose up -d
```
