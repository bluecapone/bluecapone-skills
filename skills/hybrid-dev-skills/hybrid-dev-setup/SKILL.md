---
name: hybrid-dev-setup
description: Install and explain the hybrid Pocock + pstack development setup (pack hybrid-dev-skills) - Matt Pocock skills own ideas, spec and tickets; the pstack Claude Code plugin builds (/pstack:poteto-mode) and reviews (/pstack:interrogate); /implement-spec builds a spec's tickets in parallel through poteto-mode. Use when setting up a repo for this flow, or asking which skill owns a stage.
---

# Hybrid dev skills

One owner for each stage, taken from two upstream packs:

- **Matt Pocock** (`mattpocock/skills`): ideas, spec and tickets.
- **pstack** (`cursor/plugins`, Claude Code plugin `pstack@cursor-plugins`): building, debugging and review.
- **`/implement-spec`** (this pack): runs a spec's tickets, one `/pstack:poteto-mode` implementer per ready ticket, in parallel.

`$SKILL_DIR` is the directory that contains this `SKILL.md`.

## Install

Run this from the root of the target repo:

```bash
bash "$SKILL_DIR/scripts/install.sh"
```

It needs `node`/`npx`, the `claude` CLI and GitHub access. The script:

1. Removes the skills that overlap or are not used, if present:
   - Osmani: `test-driven-development`, `code-review-and-quality`, `debugging-and-error-recovery`, `spec-driven-development`, `planning-and-task-breakdown`, `incremental-implementation`, `using-agent-skills`.
   - Pocock: `code-review`, `diagnosing-bugs`, `implement`, `improve-codebase-architecture`, `pr`, `retro`, `tdd`, `teach`, `triage`, `handoff`, `to-questionnaire`, `writing-for-agents`, `wait-what`, `wizard`.
   - `using-hybrid-dev`, and every skill in `skills-lock.json` from `cursor/plugins` (old npx copies of pstack).
2. Installs 12 Pocock skills (`ask-matt`, `setup-matt-pocock-skills`, `wayfinder`, `grill-with-docs`, `grill-me`, `grilling`, `domain-modeling`, `codebase-design`, `to-spec`, `to-tickets`, `research`, `prototype`) plus `hybrid-dev-setup` and `implement-spec`, with `npx skills add -a claude-code`.
3. Installs and enables the pstack plugin at project scope (`claude plugin install pstack@cursor-plugins -s project`), adding the `cursor/plugins` marketplace first if needed.
4. Overwrites `~/.claude/rules/pstack-models.md`: every pstack role runs on `opus medium` or `sonnet medium`. This file is global and affects every repo.
5. Checks the skill sources, that no removed skill is left, and that `.claude/settings.json` enables the plugin.

Then run `/setup-matt-pocock-skills` once, so the repo has an issue tracker config.

## Update

```bash
bash "$SKILL_DIR/scripts/install.sh" --update
```

It runs `npx skills update -p -y` (each Pocock and bluecapone skill from the repo in `skills-lock.json`), `claude plugin update pstack@cursor-plugins -s project`, rewrites the model rule, then runs the same check. A `wrong source:` line means a lock entry points at another repo: remove that skill, then run the script with no argument.

`update` refreshes only installed skills. When the set changes, first update this skill (`npx skills update hybrid-dev-setup`), then run `install.sh` with no argument.

## Stage owners

| Stage | Skill |
|---|---|
| Huge or unclear effort | Pocock `/wayfinder` |
| Sharpen an idea | Pocock `/grill-with-docs` (in a repo), `/grill-me` (no repo) |
| Answer by running code / by reading | Pocock `/prototype` / `/research` |
| Spec, then tickets | Pocock `/to-spec`, then `/to-tickets` |
| One ticket, or one slice not split into tickets | `/pstack:poteto-mode <ticket>` |
| Spec with two or more tickets | `/implement-spec <spec>` (parallel poteto-mode per ready ticket) |
| Something broken | `/pstack:poteto-mode` (Bug fix playbook) |
| Review | `/pstack:interrogate` |
| Proof against the real surface | `/pstack:create-verification-skill` |

## Known gaps

- Implementers are subagents and Claude Code gives subagents no Agent tool, so poteto-mode's delegates (swarm, arena, poteto-agent) run inline in each implementer. Parallelism is per ticket only.
- The model panels are opus and sonnet only, so arena has no cross-vendor judge.
- poteto-mode names `/deslop` and `control-cli` from `cursor-team-kit`, which is not installed.
- `/ask-matt` may recommend skills this set removes (`/implement`, `/tdd`, `/code-review`, `/diagnosing-bugs`, `/triage`, `/handoff`, `/improve-codebase-architecture`). Use `/implement-spec`, `/pstack:poteto-mode` and `/pstack:interrogate` in their place.
