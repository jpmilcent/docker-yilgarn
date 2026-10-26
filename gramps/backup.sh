#!/usr/bin/env bash
set -euo pipefail
set -E

RETENTION_DAYS=2

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "${SCRIPT_DIR}/../shared/backup.lib.sh"

function main() {
  initBackupScript "${SCRIPT_DIR}/${0##*/}"
  parseBackupArgs "$@"
  checkBackupVariables
  registerBackupTraps
  logInfo "Script ${SCRIPT_NAME} started at ${STARTED_AT}"

  createDailyDataBackup
  createDailyVolumeBackup
  removeOldBackups "*_${STACK}_backup.tar.gz" "${STACK^}"
  removeOldBackups "*_users_backup.tar.bz2" "Users"
}

function createDailyDataBackup() {
  local current_date
  local backup_file
  local temporary_file

  current_date=$(date +%F)
  backup_file="${BACKUP_DIR}/${current_date}_${STACK}_backup.tar.gz"
  temporary_file=$(mktemp "${backup_file}.XXXXXX")
  TEMP_FILE="$temporary_file"

  logInfo "Creating daily ${current_date} backup"
  tar -czf "$temporary_file" -C "${SCRIPT_DIR}/data" .
  mv -f -- "$temporary_file" "$backup_file"
  TEMP_FILE=""

  logSuccess "Backup created: ${backup_file}"
}

function createDailyVolumeBackup() {
  local current_date
  local backup_file
  local temporary_file

  current_date=$(date +%F)
  backup_file="${BACKUP_DIR}/${current_date}_users_backup.tar.bz2"
  temporary_file=$(mktemp "${backup_file}.XXXXXX")
  TEMP_FILE="$temporary_file"

  logInfo "Creating daily ${current_date} backup"

  docker compose exec -T -u 0 grampsweb \
    tar -cjf - -C / app/users > "$temporary_file"
  mv -f -- "$temporary_file" "$backup_file"
  TEMP_FILE=""

  logSuccess "Backup created: ${backup_file}"
}

main "$@"
