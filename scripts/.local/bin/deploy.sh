#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
: "${LOG_MESSAGE_PATH:=}"

if [[ -f "$SCRIPT_DIR/log-message.sh" ]]; then
    source "$SCRIPT_DIR/log-message.sh"
elif [[ -n "$LOG_MESSAGE_PATH" && -f "$LOG_MESSAGE_PATH" ]]; then
    source "$LOG_MESSAGE_PATH"
elif [[ -f "$HOME/.dotfiles/scripts/.local/bin/log-message.sh" ]]; then
    source "$HOME/.dotfiles/scripts/.local/bin/log-message.sh"
elif [[ -f "$HOME/.local/bin/log-message.sh" ]]; then
    source "$HOME/.local/bin/log-message.sh"
else
    # Fallback message printer with ANSI colors
    print_message() {
        local level="$1"
        shift
        local msg="$*"
        local RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m' BLUE='\033[0;34m' NC='\033[0m'
        case "$level" in
            info)    printf "${BLUE}%-9s${NC}   %s\n" "INFO:" "$msg" ;;
            success) printf "${GREEN}%-9s${NC}   %s\n" "SUCCESS:" "$msg" ;;
            warning) printf "${YELLOW}%-9s${NC}   %s\n" "WARNING:" "$msg" ;;
            error)   printf "${RED}%-9s${NC}   %s\n" "ERROR:" "$msg" >&2 ;;
            *)       printf "%-9s   %s\n" "$level:" "$msg" ;;
        esac
    }
fi

usage() {
    cat <<'EOF'
Usage: deploy.sh -f <file> [-d <remote-dir>] [-p <port>] [--protocol=ftp|ftps]

Uploads a single local file to a remote server over FTP.

Required environment variables:
  FTP_HOST      FTP server hostname
  FTP_USER      FTP username
  FTP_PASS      FTP password

Optional environment variables:
  FTP_FILE      Local file to upload (default value for -f)
  FTP_PORT      FTP port (default: 21, overridden by -p)
  FTP_PROTOCOL  Transfer protocol: ftp or ftps (default: ftp, overridden by --protocol)

Options:
  -f, --file <path>          Local file to upload (required)
  -d, --dir <remote-dir>     Remote folder to upload into (default: FTP root)
  -p, --port <port>          FTP port (default: 21)
      --protocol <ftp|ftps>  Transfer protocol (default: ftp)
  -s, --secure                Use explicit FTPS (AUTH TLS) — same as --protocol=ftps
  -h, --help                  Show this help

Every flag also accepts --flag=value form, e.g. --protocol=ftp, --file=dist/app.zip
EOF
}

FILE="${FTP_FILE:-}"
REMOTE_DIR=""
PORT="${FTP_PORT:-21}"
PROTOCOL="${FTP_PROTOCOL:-ftp}"
SECURE=0

while [[ $# -gt 0 ]]; do
    # Normalize --flag=value into --flag value so the case below handles both forms
    case "$1" in
        --*=*) key="${1%%=*}"; val="${1#*=}"; set -- "$key" "$val" "${@:2}" ;;
    esac

    case "$1" in
        -f|--file)      FILE="${2:-}"; shift 2 ;;
        -d|--dir)       REMOTE_DIR="${2:-}"; shift 2 ;;
        -p|--port)      PORT="${2:-}"; shift 2 ;;
        --protocol)     PROTOCOL="${2:-}"; shift 2 ;;
        -s|--secure)    SECURE=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              print_message error "Unknown option: $1"; usage; exit 1 ;;
    esac
done

case "$PROTOCOL" in
    ftp)  ;;
    ftps) SECURE=1 ;;
    *)    print_message error "Unsupported protocol: $PROTOCOL (expected ftp or ftps)"; exit 1 ;;
esac

command -v curl >/dev/null 2>&1 || { print_message error "curl is required but not installed"; exit 1; }

[[ -n "$FILE" ]] || { print_message error "Missing required -f/--file"; usage; exit 1; }
[[ -f "$FILE" ]] || { print_message error "File not found: $FILE"; exit 1; }

: "${FTP_HOST:?FTP_HOST is not set}"
: "${FTP_USER:?FTP_USER is not set}"
: "${FTP_PASS:?FTP_PASS is not set}"

FILENAME="$(basename -- "$FILE")"
REMOTE_TARGET="$FILENAME"
if [[ -n "$REMOTE_DIR" ]]; then
    REMOTE_TARGET="${REMOTE_DIR%/}/$FILENAME"
fi

TARGET_URL="ftp://${FTP_HOST}:${PORT}/${REMOTE_TARGET}"

CURL_OPTS=(-sS --ftp-create-dirs -T "$FILE" --user "${FTP_USER}:${FTP_PASS}")
[[ "$SECURE" -eq 1 ]] && CURL_OPTS+=(--ssl-reqd)

print_message info "Uploading $FILE -> $TARGET_URL"

if curl "${CURL_OPTS[@]}" "$TARGET_URL"; then
    print_message success "Deployed $FILENAME"
else
    print_message error "Deploy failed for $FILENAME"
    exit 1
fi
