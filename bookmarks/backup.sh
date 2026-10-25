#!/usr/bin/env bash
set -euo pipefail
set -E

function defineGlobalVariables() {
  # Global configuration variables
  STARTED_AT=$(date '+%Y-%m-%d %H:%M:%S')
  SECONDS=0
  VERBOSE=0
  CONFIG_FILE=""
  POSITIONAL_ARGS=()

  SCRIPT_NAME="${BASH_SOURCE[0]##*/}"
  SCRIPT_NAME="${SCRIPT_NAME%.sh}"
  STACK="${PWD##*/}"
  TEMP_FILE=""

  # Script specific global configuration variables
  BACKUP_DIR="${BACKUP_DIR:-'backup'}"
  RETENTION_DAYS="${RETENTION_DAYS:-5}"
  checkScriptGlobalVariables

  # ANSI color codes
  readonly COLOR_RESET="\033[0m"
  readonly COLOR_INFO="\033[36m"
  readonly COLOR_SUCCESS="\033[32m"
  readonly COLOR_ERROR="\033[31m"
  readonly COLOR_DEBUG="\033[35m"
}

function checkScriptGlobalVariables() {
  if [[ ! "$RETENTION_DAYS" =~ ^[1-9][0-9]*$ ]]; then
    logError "RETENTION_DAYS must be a positive integer."
    return 1
  fi
  if [[ ! -d "${BACKUP_DIR}" ]]; then
    logError "BACKUP_DIR must be an existing directory."
  fi
}

# Log functions
function logInfo() { echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $1"; }
function logSuccess() { echo -e "${COLOR_SUCCESS}[SUCCÈS]${COLOR_RESET} $1"; }
function logError() { echo -e "${COLOR_ERROR}[ERREUR]${COLOR_RESET} $1" >&2; }
function logVerbose() {
  if [[ "$VERBOSE" -eq 1 ]]; then
    echo -e "${COLOR_DEBUG}[VERB]${COLOR_RESET} $1";
  fi
}

function cleanup() {
  local exit_code=$?

  # Code 130: Ctrl+C (SIGINT)
  if [[ $exit_code -eq 130 ]]; then
    logError "⚠️ Script ${SCRIPT_NAME} stopped by user (Ctrl+C)."
  elif [[ $exit_code -ne 0 ]]; then
    logError "❌ Script ${SCRIPT_NAME} terminated with an error (code : $exit_code)."
  else
    logSuccess "✅ Script ${SCRIPT_NAME} executed with success."
  fi

  displayDuration
  cleanTemporaryFile
}

function displayDuration() {
  local duration_seconds=$SECONDS
  local duration_hours=$((duration_seconds / 3600))
  local duration_minutes=$(((duration_seconds % 3600) / 60))
  local remaining_seconds=$((duration_seconds % 60))

  printf -v formatted_duration '%02d:%02d:%02d' \
      "$duration_hours" "$duration_minutes" "$remaining_seconds"
  logInfo "Execution duration: ${formatted_duration}"
}

function cleanTemporaryFile() {
  if [[ -n "${TEMP_FILE:-}" && -f "$TEMP_FILE" ]]; then
    rm -f "$TEMP_FILE"
    logVerbose "Cleaned : $TEMP_FILE temporary file deleted." >&2
  fi
}

function handle_error() {
  local line_no=$1
  local command="$2"
  logError "❌ Erreur critique à la ligne $line_no : la commande '$command' a échoué."
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'handle_error ${LINENO} "${BASH_COMMAND}"' ERR

function usage() {
  cat << EOF
Usage: $(basename "$0") [options] argument1

Options:
  -c, --config FILE   Chemin vers le fichier de configuration
  -v, --verbose       Mode verbeux
  -x, --debug         Active le mode debogage Bash
  -h, --help          Affiche cette aide
EOF
  exit 0
}

function parseScriptArgs() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        usage
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -x|--debug)
        logVerbose "Debug mode activated !"
        set -x
        shift
        ;;
      -c|--config)
        if [[ -n "${2:-}" ]]; then
          CONFIG_FILE="${2}"
          logVerbose "Config file detected : ${CONFIG_FILE}"
          shift 2
        else
          logError "Option $1 require an argument." >&2
          exit 1
        fi
          ;;
      -*|--*)
        logError "Option unknown $1" >&2
        exit 1
        ;;
      *)
        # Storage of positional arguments
        POSITIONAL_ARGS+=("$1")
        shift
        ;;
    esac
  done

  # Validation directe des arguments positionnels requis
  if [[ ${#POSITIONAL_ARGS[@]} -eq 0 ]]; then
    logError "Missing positional argument." >&2
    echo "Use --help for more information." >&2
    exit 1
  fi
}

function main() {
  defineGlobalVariables
  parseScriptArgs "$@"
  logInfo "Script ${SCRIPT_NAME} started at ${STARTED_AT}"
  cd "$(dirname "$0")"

  createDailyBackup
  removeOldBackups

  return 0
}

function createDailyBackup() {
  local current_date=$(date +%F)
  local backup_dir="${BACKUP_DIR}"
  local backup_file="${backup_dir}/${current_date}_shaarli_data_backup.tar.bz2"
  local temporary_file="$(mktemp "${backup_file}.XXXXXX")"
  TEMP_FILE="$temporary_file"

  logInfo "Creating dayly ${current_date} backup"

  docker compose exec -T -u 0 bookmarks-shaarli \
    tar -cjf - -C / var/www/shaarli/data > "$temporary_file"
  mv "$temporary_file" "$backup_file"

  logSuccess 'Backup created : %s\n' "$backup_file"
}

function removeOldBackups() {
  local retention_days="${RETENTION_DAYS}"
  local backup_dir="${BACKUP_DIR}"
  local age_minutes

  age_minutes=$((retention_days * 1440))
  logInfo "Removing Shaarli backups older than ${retention_days} day(s)"

  local latest_backup
  latest_backup=$(find "$backup_dir" -maxdepth 1 -type f \
    -name '*_shaarli_data_backup.tar.bz2' \
    -printf '%f\n' | sort -r | sed -n '1p')

  if [[ -z "$latest_backup" ]]; then
    return 0
  fi

  find "$backup_dir" -maxdepth 1 -type f \
    -name '*_shaarli_data_backup.tar.bz2' \
    ! -name "$latest_backup" \
    -mmin "+${age_minutes}" \
    -print -delete
}

main "$@"; exit
