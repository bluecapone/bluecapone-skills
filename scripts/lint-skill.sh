#!/usr/bin/env bash
# lint-skill.sh — validate SKILL.md frontmatter against the personal
# skill-quality checklist (see wayfinder map "Skill authoring quality"):
#   1. name: 1-64 chars, lowercase alphanumeric + hyphens, matches parent dir.
#   2. description: non-empty, <=1024 chars.
#
# Usage: scripts/lint-skill.sh [path/to/SKILL.md ...]
# Defaults to every skills/*/SKILL.md in the repo. Exits non-zero on any violation.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILES=("$@")
if [ ${#FILES[@]} -eq 0 ]; then
  mapfile -t FILES < <(find "$REPO_ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md)
fi

fail=0

for f in "${FILES[@]}"; do
  dir_name="$(basename "$(dirname "$f")")"
  name="$(sed -n 's/^name: *//p' "$f" | head -1)"
  # description may be a single line after "description:"
  description="$(sed -n 's/^description: *//p' "$f" | head -1)"

  echo "== $f =="

  if [ -z "$name" ]; then
    echo "  FAIL: no 'name' field"
    fail=1
  else
    if [ "$name" != "$dir_name" ]; then
      echo "  FAIL: name '$name' does not match parent directory '$dir_name'"
      fail=1
    fi
    if ! [[ "$name" =~ ^[a-z0-9-]{1,64}$ ]]; then
      echo "  FAIL: name '$name' must be 1-64 chars, lowercase alphanumeric + hyphens only"
      fail=1
    fi
  fi

  if [ -z "$description" ]; then
    echo "  FAIL: no 'description' field"
    fail=1
  else
    len=${#description}
    if [ "$len" -gt 1024 ]; then
      echo "  FAIL: description is $len chars, exceeds 1024-char spec limit"
      fail=1
    else
      echo "  OK: description $len chars"
    fi
  fi

  if [ "$fail" -eq 0 ]; then
    echo "  OK: name '$name' matches dir, valid charset"
  fi
done

exit $fail
