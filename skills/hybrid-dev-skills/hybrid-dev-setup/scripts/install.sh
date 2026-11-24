#!/usr/bin/env bash
# install.sh - install or update the hybrid Pocock + pstack setup in the current repo.
# Usage: install.sh            remove old skills, add Pocock + bluecapone skills, install the
#                              pstack Claude Code plugin (project scope), write the model rule, check
#        install.sh --update   npx skills update -p -y, claude plugin update, write the rule, check
# Run from the target repo root. Needs node/npx, the claude CLI and network access to GitHub.
# Always overwrites ~/.claude/rules/pstack-models.md (global: affects every repo).
set -euo pipefail

SKILLS=(npx -y skills@latest)
PLUGIN=pstack@cursor-plugins
RULE="$HOME/.claude/rules/pstack-models.md"

REMOVE=(
  test-driven-development code-review-and-quality debugging-and-error-recovery
  spec-driven-development planning-and-task-breakdown incremental-implementation
  using-agent-skills
  code-review diagnosing-bugs implement improve-codebase-architecture pr retro tdd
  teach triage handoff to-questionnaire writing-for-agents wait-what wizard
  using-hybrid-dev
)

POCOCK=(
  ask-matt setup-matt-pocock-skills wayfinder grill-with-docs grill-me grilling
  domain-modeling codebase-design to-spec to-tickets research prototype
)

BLUECAPONE=(hybrid-dev-setup implement-spec)

add() {
  local source="$1"; shift
  local args=()
  for n in "$@"; do args+=(--skill "$n"); done
  "${SKILLS[@]}" add "$source" -a claude-code -y "${args[@]}"
}

remove_old() {
  local present=()
  for n in "${REMOVE[@]}"; do
    if [ -e ".agents/skills/$n" ] || [ -e ".claude/skills/$n" ] || [ -L ".claude/skills/$n" ]; then
      present+=("$n")
    fi
  done
  # Old npx copies of pstack skills: every lock entry from cursor/plugins.
  if [ -f skills-lock.json ]; then
    while IFS= read -r n; do [ -n "$n" ] && present+=("$n"); done < <(node -e '
      const l = JSON.parse(require("fs").readFileSync("skills-lock.json", "utf8")).skills || {};
      for (const [n, e] of Object.entries(l)) if (e.source === "cursor/plugins") console.log(n);')
  fi
  if [ "${#present[@]}" -gt 0 ]; then
    echo "Removing: ${present[*]}"
    "${SKILLS[@]}" remove "${present[@]}" -y
  fi
}

pstack_plugin() {
  if ! claude plugin marketplace list --json | node -e '
    const m = JSON.parse(require("fs").readFileSync(0, "utf8"));
    process.exit(m.some((x) => x.name === "cursor-plugins") ? 0 : 1);'; then
    claude plugin marketplace add cursor/plugins
  fi
  local state
  state=$(claude plugin list --json | PLUGIN="$PLUGIN" node -e '
    const p = JSON.parse(require("fs").readFileSync(0, "utf8")).find((x) =>
      x.id === process.env.PLUGIN && x.scope === "project" && x.projectPath === process.cwd());
    console.log(!p ? "missing" : p.enabled ? "enabled" : "disabled");')
  case "$state" in
    missing) claude plugin install "$PLUGIN" -s project ;;
    disabled) claude plugin enable "$PLUGIN" -s project ;;
  esac
}

write_rule() {
  mkdir -p "$(dirname "$RULE")"
  cat > "$RULE" <<'EOF'
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit Task `model` and spawn `generalPurpose`). Alias entries in a panel list still count toward its fan-out.
# defaults: 3
# budget: small (medium)
feature, refactoring: opus medium
bug-fix: opus medium
perf-issue: opus medium
hillclimb: opus medium
judgment and prose: opus medium
arena runners: opus medium, sonnet medium
arena cross-judge pool: opus medium, sonnet medium
swarm workers: sonnet medium
interrogate reviewers: opus medium, sonnet medium
EOF
  echo "wrote $RULE"
}

check() {
  PLUGIN="$PLUGIN" node - "${POCOCK[*]}" "${BLUECAPONE[*]}" "${REMOVE[*]}" <<'EOF'
const fs = require("fs");
const [pocock, bluecapone, remove] = process.argv.slice(2).map((s) => s.split(" "));
const lock = JSON.parse(fs.readFileSync("skills-lock.json", "utf8")).skills;
let bad = false;
for (const [source, names] of [["mattpocock/skills", pocock], ["bluecapone/bluecapone-skills", bluecapone]]) {
  const wrong = names.filter((n) => !lock[n] || lock[n].source !== source);
  console.log(`${source}: ${names.length - wrong.length}/${names.length}`);
  for (const n of wrong) {
    console.log(`  wrong source: ${n} -> ${lock[n] ? lock[n].source : "not in skills-lock.json"}`);
    bad = true;
  }
}
const old = Object.keys(lock).filter((n) => lock[n].source === "cursor/plugins");
console.log(`npx pstack copies: ${old.length ? old.join(" ") : "none"}`);
const left = remove.filter((n) => [".agents/skills/", ".claude/skills/"].some((d) => fs.existsSync(d + n)));
console.log(`removed skills left: ${left.length ? left.join(" ") : "none"}`);
let enabled = false;
try { enabled = JSON.parse(fs.readFileSync(".claude/settings.json", "utf8")).enabledPlugins?.[process.env.PLUGIN] === true; } catch {}
console.log(`${process.env.PLUGIN} enabled in .claude/settings.json: ${enabled}`);
if (bad || old.length || left.length || !enabled) process.exit(1);
EOF
}

case "${1:-}" in
  "")
    remove_old
    add mattpocock/skills "${POCOCK[@]}"
    add bluecapone/bluecapone-skills "${BLUECAPONE[@]}"
    pstack_plugin
    write_rule
    check
    echo "OK. Next: run /setup-matt-pocock-skills once, then /wayfinder or /to-spec."
    ;;
  --update)
    "${SKILLS[@]}" update -p -y
    claude plugin update "$PLUGIN" -s project
    write_rule
    check
    echo "OK. Updated from the original repos."
    ;;
  *)
    echo "usage: install.sh [--update]" >&2
    exit 2
    ;;
esac
