#!/usr/bin/env bash
# install.sh - install the hybrid Pocock + pstack skill set into the current repo.
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

BLUECAPONE=(hybrid-dev-skills using-hybrid-dev)

add() {
  local source="$1"; shift
  local args=()
  for n in "$@"; do args+=(--skill "$n"); done
  "${SKILLS[@]}" add "$source" -a codex --copy -y "${args[@]}"
}

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

node - "${#PSTACK[@]}" <<'EOF'
const fs = require("fs");
const want = Number(process.argv[2]);
const lock = JSON.parse(fs.readFileSync("skills-lock.json", "utf8")).skills;
const pstack = Object.values(lock).filter((s) => s.source === "cursor/plugins").length;
const tdd = lock.tdd && lock.tdd.source;
const teach = fs.existsSync(".agents/skills/teach");
console.log(`pstack skills: ${pstack} (want ${want})`);
console.log(`tdd source: ${tdd}`);
console.log(`teach installed: ${teach}`);
if (pstack !== want || tdd !== "mattpocock/skills" || teach) process.exit(1);
EOF
echo "OK. Next: run /setup-matt-pocock-skills once, then /using-hybrid-dev."
