# Genea

Cette stack utilise le dossier `data/` présent sur l'hôte pour stocker ses données.

## Restaurer une sauvegarde

Les archives sont créées dans `backup/` au format `AAAA-MM-JJ_genea_backup.tar.gz`. Pour restaurer une archive dans le volume de données :

```sh
tar -xzf backup/AAAA-MM-JJ_genea_backup.tar.gz -C data/
```

Cette restauration remplace les fichiers correspondants dans `data/`.

## Créer une sauvegarde

Le script `backup.sh` archive le contenu de `data/` dans `backup/`. Les sauvegardes de plus de 2 jours sont supprimées, sauf la plus récente :

```sh
bash ./backup.sh
```
