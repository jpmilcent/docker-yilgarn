#!/usr/bin/env bash
set -euo pipefail
set -E

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "${SCRIPT_DIR}/../shared/backup.lib.sh"

function main() {
  local -a volume_names=(gpg jwt images)
  local -a volume_paths=(
    /etc/passbolt/gpg
    /etc/passbolt/jwt
    /usr/share/php/passbolt/webroot/img/public
  )
  local volume_index

  initBackupScript "${SCRIPT_DIR}/${0##*/}"
  parseBackupArgs "$@"
  checkBackupVariables
  registerBackupTraps
  logInfo "Script ${SCRIPT_NAME} started at ${STARTED_AT}"

  for volume_index in "${!volume_names[@]}"; do
    createDailyBackup "${volume_names[$volume_index]}" "${volume_paths[$volume_index]}"
    removeOldBackups \
      "*_${STACK}_${volume_names[$volume_index]}_backup.tar.bz2" \
      "${volume_names[$volume_index]^}"
  done

  createDatabaseBackup
  removeOldBackups "*_${STACK}_database_backup.sql.gz" "Database"

  return 0
}

function createDailyBackup() {
  checkArgumentCount "${FUNCNAME[0]}" 2 "$#" || return 2
  local volume_name="$1"
  local volume_path="$2"
  local current_date
  local backup_file
  local temporary_file

  current_date=$(date +%F)
  backup_file="${BACKUP_DIR}/${current_date}_${STACK}_${volume_name}_backup.tar.bz2"
  temporary_file=$(mktemp "${backup_file}.XXXXXX")
  TEMP_FILE="$temporary_file"

  logInfo "Creating daily ${current_date} ${volume_name} volume backup"

  local -a tar_options=(--one-file-system)

  docker compose exec -T -u 0 pwd-clapas-passbolt \
    tar -cf - "${tar_options[@]}" -C "$volume_path" . \
    | bzip2 -c > "$temporary_file"
  mv -f -- "$temporary_file" "$backup_file"
  TEMP_FILE=""

  logSuccess "Backup created: ${backup_file}"
}

function createDatabaseBackup() {
  local current_date
  local backup_file
  local temporary_file

  current_date=$(date +%F)
  backup_file="${BACKUP_DIR}/${current_date}_${STACK}_database_backup.sql.gz"
  temporary_file=$(mktemp "${backup_file}.XXXXXX")
  TEMP_FILE="$temporary_file"

  logInfo "Creating daily ${current_date} database backup"

  docker compose exec -T pwd-clapas-database sh -c '
    set -eu
    : "${MARIADB_ROOT_PASSWORD:?MARIADB_ROOT_PASSWORD is not set}"
    : "${MARIADB_DATABASE:?MARIADB_DATABASE is not set}"
    MYSQL_PWD="$MARIADB_ROOT_PASSWORD" exec mariadb-dump \
      --user=root \
      --host=127.0.0.1 \
      --protocol=TCP \
      --skip-ssl-verify-server-cert \
      --single-transaction \
      --routines \
      --events \
      --triggers \
      --databases "$MARIADB_DATABASE"
  ' | gzip -c > "$temporary_file"
  mv -f -- "$temporary_file" "$backup_file"
  TEMP_FILE=""

  logSuccess "Database backup created: ${backup_file}"
}

main "$@"
