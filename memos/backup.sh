#!/usr/bin/env bash
set -euo pipefail
set -E

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
source "${SCRIPT_DIR}/../shared/backup.lib.sh"

function main() {
  local -a volume_names=(data plugins conf tpl)
  local -a volume_paths=(
    /var/www/html/data
    /var/www/html/lib/plugins
    /var/www/html/conf
    /var/www/html/lib/tpl
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

  if [[ "$volume_name" == "data" ]]; then
    tar_options+=(--exclude='./media/wiki/backup')
  fi

  docker compose exec -T -u 0 memos-clapas-dokuwiki \
    tar -cjf - "${tar_options[@]}" -C "$volume_path" . > "$temporary_file"
  mv -f -- "$temporary_file" "$backup_file"
  TEMP_FILE=""

  logSuccess "Backup created: ${backup_file}"
}

main "$@"
