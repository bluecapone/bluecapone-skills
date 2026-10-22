#!/bin/bash
# nlm-query.sh — Query or manage NotebookLM notebooks via nlm CLI
# Wraps nlm CLI for use in research pipelines where MCP may not be available
#
# Usage:
#   nlm-query.sh list                              # list notebooks
#   nlm-query.sh query NOTEBOOK_ID "question"      # query a notebook
#   nlm-query.sh add NOTEBOOK_ID --text "content" --title "Title"  # add source
#   nlm-query.sh create "Notebook Name"            # create notebook
#   nlm-query.sh sources NOTEBOOK_ID               # list sources
#
# Requires: nlm CLI installed and authenticated (nlm login)

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: nlm-query.sh {list|query|add|create|sources} [args...]" >&2
  exit 1
fi

CMD="$1"
shift

case "$CMD" in
  list)
    nlm notebook list --json 2>/dev/null || nlm notebook list
    ;;
  query)
    if [ $# -lt 2 ]; then
      echo "Usage: nlm-query.sh query NOTEBOOK_ID \"question\"" >&2; exit 1
    fi
    NOTEBOOK="$1"
    QUESTION="$2"
    nlm notebook query "$NOTEBOOK" "$QUESTION" 2>/dev/null | jq -r '.answer // .value.answer // .' 2>/dev/null || nlm notebook query "$NOTEBOOK" "$QUESTION"
    ;;
  add)
    if [ $# -lt 1 ]; then
      echo "Usage: nlm-query.sh add NOTEBOOK_ID --text \"content\" --title \"Title\"" >&2; exit 1
    fi
    NOTEBOOK="$1"
    shift
    nlm source add "$NOTEBOOK" "$@"
    ;;
  create)
    if [ $# -lt 1 ]; then
      echo "Usage: nlm-query.sh create \"Notebook Name\"" >&2; exit 1
    fi
    nlm notebook create "$1"
    ;;
  sources)
    if [ $# -lt 1 ]; then
      echo "Usage: nlm-query.sh sources NOTEBOOK_ID" >&2; exit 1
    fi
    nlm source list "$1"
    ;;
  *)
    echo "Unknown command: $CMD" >&2
    echo "Commands: list, query, add, create, sources" >&2
    exit 1
    ;;
esac
