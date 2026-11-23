#!/usr/bin/env bash
# install.sh - install or update the hybrid Pocock + pstack skill set in the current repo.
# Usage: install.sh            install (remove overlapping skills, add the set, check sources)
#        install.sh --update   npx skills update -p -y, then check sources
# Run from the target repo root. Needs node/npx and network access to GitHub.
set -euo pipefail

SKILLS=(npx -y skills@latest)

REMOVE=(
  test-driven-development code-review-and-quality debugging-and-error-recovery
  spec-driven-development planning-and-task-breakdown incremental-implementation
  using-agent-skills
  implement improve-codebase-architecture triage pr teach handoff to-questionnaire
  writing-for-agents
)

POCOCK=(
  ask-matt code-review codebase-design diagnosing-bugs domain-modeling grill-me
  grill-with-docs grilling implement-spec prototype research retro
  setup-matt-pocock-skills tdd to-spec to-tickets wait-what wayfinder wizard
)

PSTACK=(
  poteto-mode architect arena benchmark-checklist figure-it-out how why interrogate
  ketchup no-comments show-me-your-work swarm technical-writing unslop
  create-verification-skill typescript-best-practices
  principle-attack-the-premise principle-boundary-discipline principle-build-the-lever
  principle-encode-lessons-in-structure principle-exhaust-the-design-space
  principle-experience-first principle-explain-the-number principle-fix-root-causes
  principle-foundational-thinking principle-guard-the-context-window
  principle-laziness-protocol principle-make-operations-idempotent
  principle-migrate-callers-then-delete-legacy-apis principle-minimize-reader-load
  principle-model-the-domain principle-never-block-on-the-human
  principle-outcome-oriented-execution principle-prove-it-works
  principle-redesign-from-first-principles
  principle-separate-before-serializing-shared-state
  principle-sequence-verifiable-units principle-subtract-before-you-add
  principle-test-behavior-not-implementation principle-type-system-discipline
)

BLUECAPONE=(hybrid-dev-setup using-hybrid-dev)

add() {
  local source="$1"; shift
  local args=()
  for n in "$@"; do args+=(--skill "$n"); done
  "${SKILLS[@]}" add "$source" -a codex --copy -y "${args[@]}"
}

check_sources() {
  node - "${POCOCK[*]}" "${PSTACK[*]}" "${BLUECAPONE[*]}" <<'EOF'
const fs = require("fs");
const [pocock, pstack, bluecapone] = process.argv.slice(2).map((s) => s.split(" "));
const lock = JSON.parse(fs.readFileSync("skills-lock.json", "utf8")).skills;
const want = [
  ["mattpocock/skills", pocock],
  ["cursor/plugins", pstack],
  ["bluecapone/bluecapone-skills", bluecapone],
];
let bad = false;
for (const [source, names] of want) {
  const wrong = names.filter((n) => !lock[n] || lock[n].source !== source);
  console.log(`${source}: ${names.length - wrong.length}/${names.length}`);
  for (const n of wrong) {
    console.log(`  wrong source: ${n} -> ${lock[n] ? lock[n].source : "not in skills-lock.json"}`);
    bad = true;
  }
}
const teach = fs.existsSync(".agents/skills/teach");
console.log(`teach installed: ${teach}`);
if (bad || teach) process.exit(1);
EOF
}

case "${1:-}" in
  "")
    present=()
    for n in "${REMOVE[@]}"; do
      if [ -e ".agents/skills/$n" ] || [ -L ".claude/skills/$n" ]; then
        present+=("$n")
      fi
    done
    if [ "${#present[@]}" -gt 0 ]; then
      echo "Removing: ${present[*]}"
      "${SKILLS[@]}" remove "${present[@]}" -y
    fi
    add mattpocock/skills "${POCOCK[@]}"
    add cursor/plugins "${PSTACK[@]}"
    add bluecapone/bluecapone-skills "${BLUECAPONE[@]}"
    check_sources
    echo "OK. Next: run /setup-matt-pocock-skills once, then /using-hybrid-dev."
    ;;
  --update)
    "${SKILLS[@]}" update -p -y
    check_sources
    echo "OK. Updated from the original repos."
    ;;
  *)
    echo "usage: install.sh [--update]" >&2
    exit 2
    ;;
esac
