#!/usr/bin/env bash
set -euo pipefail
set -E

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "${SCRIPT_DIR}/../shared/backup.lib.sh"

function main() {
  initBackupScript "$0"
  parseBackupArgs "$@"
  checkBackupVariables
  registerBackupTraps
  logInfo "Script ${SCRIPT_NAME} started at ${STARTED_AT}"

  createDailyBackup
  removeOldBackups '*_shaarli_data_backup.tar.bz2' "Shaarli"

  return 0
}

function createDailyBackup() {
  local current_date
  local backup_file
  local temporary_file

  current_date=$(date +%F)
  backup_file="${BACKUP_DIR}/${current_date}_shaarli_data_backup.tar.bz2"
  temporary_file=$(mktemp "${backup_file}.XXXXXX")
  TEMP_FILE="$temporary_file"

  logInfo "Creating daily ${current_date} backup"

  docker compose exec -T -u 0 bookmarks-shaarli \
    tar -cjf - -C / var/www/shaarli/data > "$temporary_file"
  mv -f -- "$temporary_file" "$backup_file"
  TEMP_FILE=""

  logSuccess "Backup created: ${backup_file}"
}

main "$@"
