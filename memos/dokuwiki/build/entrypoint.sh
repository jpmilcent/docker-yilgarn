#!/bin/bash
set -e

# ==============================================================================
# Initialisation de la configuration SMTP (msmtp) via le gabarit
if [ -n "$SMTP_HOST" ] && [ -n "$SMTP_USER" ]; then
  echo "==> Génération de /etc/msmtprc à partir du template..."

  # Définition des valeurs de repli (fallback) pour les variables optionnelles
  export SMTP_PORT="${SMTP_PORT:-587}"
  export SMTP_AUTH="${SMTP_AUTH:-login}"
  export SMTP_FROM="${SMTP_FROM:-$SMTP_USER}"
  export SMTP_HOST
  export SMTP_USER
  export SMTP_PASSWORD

  # Substitution ciblée des variables
  envsubst '${SMTP_HOST} ${SMTP_PORT} ${SMTP_AUTH} ${SMTP_USER} ${SMTP_PASSWORD} ${SMTP_FROM}' \
    < /etc/msmtprc.template > /etc/msmtprc

  # Sécurisation des permissions requise par msmtp
  chmod 600 /etc/msmtprc
  chown www-data:www-data /etc/msmtprc

  # Initialisation du fichier de journalisation
  touch /var/log/msmtp.log
  chown www-data:www-data /var/log/msmtp.log
else
  echo "==> Avertissement : Variables SMTP absentes, configuration /etc/msmtprc ignorée."
fi

# ==============================================================================
# Gestion des volumes et mise à jour de DokuWiki
SOURCE_DIR="/usr/src/dokuwiki"
TARGET_DIR="/var/www/html"

CURRENT_VERSION=""
if [ -f "$TARGET_DIR/VERSION" ]; then
  CURRENT_VERSION=$(cat "$TARGET_DIR/VERSION")
fi

NEW_VERSION=""
if [ -f "$SOURCE_DIR/VERSION" ]; then
  NEW_VERSION=$(cat "$SOURCE_DIR/VERSION")
fi

# 1. Premier déploiement si le dossier cible est vide
if [ ! -f "$TARGET_DIR/doku.php" ]; then
  echo "==> Initialisation initiale de DokuWiki ($NEW_VERSION)..."
  cp -a "$SOURCE_DIR/." "$TARGET_DIR/"
  chown -R www-data:www-data "$TARGET_DIR"

# 2. Mise à jour si la version de l'image est différente du volume
elif [ "$CURRENT_VERSION" != "$NEW_VERSION" ]; then
  echo "==> Mise à jour de DokuWiki : ${CURRENT_VERSION:-inconnue} -> $NEW_VERSION"

  # Synchronisation de l'ensemble des fichiers système (bin, inc, vendor, conf, lib)
  # L'archive officielle ne contient pas local.php ni users.auth.php, vos identifiants restent intacts
  shopt -s dotglob nullglob
  for item in "$SOURCE_DIR"/*; do
    base=$(basename "$item")
    if [ "$base" = "data" ]; then
      continue
    fi
    if [ -d "$item" ]; then
      mkdir -p "$TARGET_DIR/$base"
      cp -a "$item/." "$TARGET_DIR/$base/"
    else
      cp -a "$item" "$TARGET_DIR/"
    fi
  done
  shopt -u dotglob nullglob

  # Copie précautionneuse du dossier data (nouveaux fichiers uniquement, sans écraser les pages existantes)
  cp -rn "$SOURCE_DIR/data/." "$TARGET_DIR/data/" 2>/dev/null || true
  cp -f "$SOURCE_DIR/data/deleted.files" "$TARGET_DIR/data/deleted.files" 2>/dev/null || true

  # Nettoyage des fichiers obsolètes recommandés par la mise à jour DokuWiki
  if [ -f "$TARGET_DIR/data/deleted.files" ]; then
    echo "==> Suppression des fichiers obsolètes..."
    while IFS= read -r file || [ -n "$file" ]; do
      case "$file" in
        \#*|"") continue ;;
        *)
          clean_file=$(echo "$file" | tr -d '\r')
          if [ -n "$clean_file" ] && [ -e "$TARGET_DIR/$clean_file" ]; then
            rm -rf "${TARGET_DIR:?}/$clean_file"
          fi
          ;;
      esac
    done < "$TARGET_DIR/data/deleted.files"
  fi

  # Sécurité : suppression d'install.php si le wiki est déjà configuré
  if [ -f "$TARGET_DIR/conf/local.php" ] && [ -f "$TARGET_DIR/install.php" ]; then
    rm -f "$TARGET_DIR/install.php"
  fi

  # Rétablissement des droits pour php-fpm
  chown -R www-data:www-data "$TARGET_DIR"
  echo "==> Mise à jour vers DokuWiki $NEW_VERSION terminée."

else
  echo "==> DokuWiki est déjà à jour ($CURRENT_VERSION)."
fi

exec "$@"
