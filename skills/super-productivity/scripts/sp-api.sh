#!/usr/bin/env bash
# sp-api.sh — call the Super Productivity Local REST API (http://127.0.0.1:3876).
# Usage: sp-api.sh METHOD PATH [JSON_BODY]
#   sp-api.sh GET /tasks
#   sp-api.sh POST /tasks '{"title":"Buy milk","projectId":"INBOX_PROJECT"}'
# Reads the per-device token file; override its path with SP_TOKEN_FILE.
# The token reaches curl as a header read from stdin (`-H @-`, written by the
# printf builtin), so it never appears in argv (`ps`). Process substitution is
# not used: macOS /usr/bin/curl 8.7.1 fails to read `-H @/dev/fd/N`.
# --noproxy stops a configured proxy from receiving the token.
set -euo pipefail

method=${1:?usage: sp-api.sh METHOD PATH [JSON_BODY]}
path=${2:?usage: sp-api.sh METHOD PATH [JSON_BODY]}
body=${3-}

if [ -z "${SP_TOKEN_FILE:-}" ]; then
  case "$(uname -s)" in
    Darwin) SP_TOKEN_FILE="$HOME/Library/Application Support/superProductivity/local-rest-api-token" ;;
    *) SP_TOKEN_FILE="$HOME/.config/superProductivity/local-rest-api-token" ;;
  esac
fi
if [ ! -r "$SP_TOKEN_FILE" ]; then
  echo "sp-api.sh: token file not readable: $SP_TOKEN_FILE (enable Settings -> Misc -> Enable local REST API in the desktop app)" >&2
  exit 2
fi

args=(-sS --noproxy 127.0.0.1 -X "$method" -H @-)
if [ -n "$body" ]; then
  args+=(-H 'Content-Type: application/json' --data-binary "$body")
fi
printf 'Authorization: Bearer %s\n' "$(tr -d '\r\n' < "$SP_TOKEN_FILE")" |
  curl "${args[@]}" "http://127.0.0.1:3876$path"
echo
