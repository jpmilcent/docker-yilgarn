# Checks a call's arity before positional parameters are accessed.
# Parameters: function name (text), expected count (integer), actual count (integer).
function checkArgumentCount() {
  if [[ $# -ne 3 ]]; then
    printf 'ERREUR: checkArgumentCount expects 3 arguments, received %d.\n' "$#" >&2
    return 2
  fi

  local function_name="$1"
  local expected="$2"
  local actual="$3"

  if [[ ! "$expected" =~ ^[0-9]+$ || ! "$actual" =~ ^[0-9]+$ ]]; then
    printf 'ERREUR: expected and actual argument counts must be integers.\n' >&2
    return 2
  fi

  if [[ "$actual" -ne "$expected" ]]; then
    printf 'ERREUR: %s expects %s argument(s), received %s.\n' \
      "$function_name" "$expected" "$actual" >&2
    return 2
  fi
}

# Initializes global variables and colors for the backup script.
# Parameters: path to the calling script (file path).
function initBackupScript() {
  checkArgumentCount "${FUNCNAME[0]}" 1 "$#" || return 2
  local script_path="$1"

  STARTED_AT=$(date '+%Y-%m-%d %H:%M:%S')
  SECONDS=0
  VERBOSE=0
  CONFIG_FILE=""
  SCRIPT_NAME="${script_path##*/}"
  SCRIPT_NAME="${SCRIPT_NAME%.sh}"
  STACK="$(basename "$(dirname "$script_path")")"
  TEMP_FILE=""
  BACKUP_DIR="${BACKUP_DIR:-backup}"
  RETENTION_DAYS="${RETENTION_DAYS:-5}"

  readonly COLOR_RESET="\033[0m"
  readonly COLOR_INFO="\033[36m"
  readonly COLOR_SUCCESS="\033[32m"
  readonly COLOR_ERROR="\033[31m"
  readonly COLOR_DEBUG="\033[35m"
}

# Validates the global RETENTION_DAYS and BACKUP_DIR variables.
# Parameters: none.
function checkBackupVariables() {
  if [[ ! "$RETENTION_DAYS" =~ ^[1-9][0-9]*$ ]]; then
    logError "RETENTION_DAYS must be a positive integer."
    return 1
  fi
  if [[ ! -d "$BACKUP_DIR" ]]; then
    logError "BACKUP_DIR must be an existing directory."
    return 1
  fi
}

# Displays an informational message.
# Parameters: message to display (text; printf escape sequences are accepted).
function logInfo() {
  checkArgumentCount "${FUNCNAME[0]}" 1 "$#" || return 2
  printf '%b\n' "${COLOR_INFO}[INFO]${COLOR_RESET} $1";
}

# Displays a success message.
# Parameters: message to display (text; printf escape sequences are accepted).
function logSuccess() {
  checkArgumentCount "${FUNCNAME[0]}" 1 "$#" || return 2
  printf '%b\n' "${COLOR_SUCCESS}[SUCCÈS]${COLOR_RESET} $1";
}

# Displays an error message on standard error.
# Parameters: message to display (text; printf escape sequences are accepted).
function logError() {
  checkArgumentCount "${FUNCNAME[0]}" 1 "$#" || return 2
  printf '%b\n' "${COLOR_ERROR}[ERREUR]${COLOR_RESET} $1" >&2;
}

# Displays a diagnostic message when VERBOSE is set to 1.
# Parameters: message to display (text; printf escape sequences are accepted).
function logVerbose() {
  checkArgumentCount "${FUNCNAME[0]}" 1 "$#" || return 2
  if [[ "$VERBOSE" -eq 1 ]]; then
    printf '%b\n' "${COLOR_DEBUG}[VERB]${COLOR_RESET} $1"
  fi
}

# Displays the final status and duration, then removes any temporary file.
# Parameters: none; uses the current exit code and global variables.
function cleanup() {
  local exit_code=$?

  if [[ $exit_code -eq 130 ]]; then
    logError "Script ${SCRIPT_NAME} stopped by user (Ctrl+C)."
  elif [[ $exit_code -ne 0 ]]; then
    logError "Script ${SCRIPT_NAME} terminated with an error (code: $exit_code)."
  else
    logSuccess "Script ${SCRIPT_NAME} executed successfully."
  fi

  displayDuration
  cleanTemporaryFile
}

# Calculates and displays the time elapsed since the script started.
# Parameters: none; uses the Bash SECONDS variable.
function displayDuration() {
  local duration_seconds=$SECONDS
  local duration_hours=$((duration_seconds / 3600))
  local duration_minutes=$(((duration_seconds % 3600) / 60))
  local remaining_seconds=$((duration_seconds % 60))
  local formatted_duration

  printf -v formatted_duration '%02d:%02d:%02d' \
    "$duration_hours" "$duration_minutes" "$remaining_seconds"
  logInfo "Execution duration: ${formatted_duration}"
}

# Removes the temporary file referenced by TEMP_FILE, if it exists.
# Parameters: none; uses the global TEMP_FILE and VERBOSE variables.
function cleanTemporaryFile() {
  if [[ -n "${TEMP_FILE:-}" && -f "$TEMP_FILE" ]]; then
    rm -f "$TEMP_FILE"
    logVerbose "Cleaned temporary file: $TEMP_FILE"
  fi
}

# Reports a failed command and the line where it failed.
# Parameters: line number (integer), failed command (text).
function handle_error() {
  checkArgumentCount "${FUNCNAME[0]}" 2 "$#" || return 2
  local line_no=$1
  local command="$2"
  logError "Critical error at line $line_no: command '$command' failed."
}

# Registers the script's exit, interrupt, and error handlers.
# Parameters: none.
function registerBackupTraps() {
  trap cleanup EXIT
  trap 'exit 130' INT
  trap 'handle_error "$LINENO" "$BASH_COMMAND"' ERR
}

# Displays the script's help, identified by SCRIPT_NAME.
# Parameters: none; requires initBackupScript to have initialized SCRIPT_NAME.
function backupUsage() {
  cat <<EOF
Usage: ${SCRIPT_NAME}.sh [options]

Options:
  -c, --config FILE   Path to a configuration file
  -v, --verbose       Enable verbose output
  -x, --debug         Enable Bash debug mode
  -h, --help          Show this help
EOF
}

# Parses command-line options and updates global variables.
# Parameters: zero or more options; --config/-c requires a following file path.
function parseBackupArgs() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        backupUsage
        exit 0
        ;;
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -x|--debug)
        VERBOSE=1
        set -x
        shift
        ;;
      -c|--config)
        if [[ -n "${2:-}" ]]; then
          CONFIG_FILE="$2"
          logVerbose "Config file detected: ${CONFIG_FILE}"
          shift 2
        else
          logError "Option $1 requires an argument."
          return 1
        fi
        ;;
      -*|--*)
        logError "Unknown option: $1"
        return 1
        ;;
      *)
        logError "Unexpected argument: $1"
        return 1
        ;;
    esac
  done
}

# Deletes old backups matching the pattern, except for the most recent one.
# Parameters: find -name pattern (string with wildcards), backup type description (text).
function removeOldBackups() {
  checkArgumentCount "${FUNCNAME[0]}" 2 "$#" || return 2
  local filename_pattern="$1"
  local backup_description="$2"
  local age_minutes=$((RETENTION_DAYS * 1440))
  local latest_backup

  logInfo "Removing ${backup_description} backups older than ${RETENTION_DAYS} day(s)"

  latest_backup=$(find "$BACKUP_DIR" -maxdepth 1 -type f \
    -name "$filename_pattern" -printf '%f\n' | sort -r | sed -n '1p')

  if [[ -z "$latest_backup" ]]; then
    return 0
  fi

  find "$BACKUP_DIR" -maxdepth 1 -type f \
    -name "$filename_pattern" \
    ! -name "$latest_backup" \
    -mmin "+${age_minutes}" \
    -print -delete
}
