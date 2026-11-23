---
name: hybrid-dev-setup
description: Install and explain the hybrid Pocock + pstack development skill set (pack hybrid-dev-skills) - Matt Pocock skills own decisions, spec, tickets, TDD, debugging and review; pstack /poteto-mode owns how each ticket is built. Use when setting up a repo for this flow, or asking which pack owns a stage. For the next step in a repo that already has the set, run /using-hybrid-dev.
---

# Hybrid dev skills

One owner for each stage, taken from two upstream packs:

- **Matt Pocock** (`mattpocock/skills`): decisions, spec, tickets, TDD, debugging and review.
- **pstack** (`cursor/plugins`, folder `pstack/`): `/poteto-mode` and the skills it calls, to build one ticket at a time.

`$SKILL_DIR` is the directory that contains this `SKILL.md`.

## Install

Run this from the root of the target repo:

```bash
bash "$SKILL_DIR/scripts/install.sh"
```

The script:

1. Removes the skills that overlap or are not used, if they are present:
   - Osmani: `test-driven-development`, `code-review-and-quality`, `debugging-and-error-recovery`, `spec-driven-development`, `planning-and-task-breakdown`, `incremental-implementation`, `using-agent-skills`.
   - Pocock: `implement`, `improve-codebase-architecture`, `triage`, `pr`, `teach`, `handoff`, `to-questionnaire`, `writing-for-agents`.
2. Installs 19 Pocock skills and 40 pstack skills, plus `using-hybrid-dev` and this skill, into `.agents/skills/` with `--copy`.
3. Checks that every skill comes from its original repo: Pocock skills from `mattpocock/skills`, pstack skills from `cursor/plugins`, and the two hybrid skills from `bluecapone/bluecapone-skills`. pstack `tdd` and `teach` have the same names as the Pocock skills, and installing them overwrites the Pocock versions without any warning, so the script never installs them.

Then run `/setup-matt-pocock-skills` once, so the repo has an issue tracker config.

## Update

`npx skills update` fetches each skill from the repo recorded for it in `skills-lock.json` (`source` and `skillPath`). Pocock skills update from `mattpocock/skills` and pstack skills from `cursor/plugins`. This repo holds no copies of them. Run the update through the script, so the sources are checked afterwards:

```bash
bash "$SKILL_DIR/scripts/install.sh" --update
```

It runs `npx skills update -p -y`, then the same source check as the install. A `wrong source:` line means a lock entry points at another repo. Remove that skill, then run the script with no argument.

`update` refreshes only the skills that are already installed. When upstream adds or renames a skill in the set, first update this skill (`npx skills update hybrid-dev-setup`) to get the new lists, then run `install.sh` with no argument.

## Stage owners

| Stage | Skill |
|---|---|
| Huge or unclear effort | Pocock `/wayfinder` |
| Sharpen an idea | Pocock `/grill-with-docs` (in a repo), `/grill-me` (no repo) |
| Answer by running code / by reading | Pocock `/prototype` / `/research` |
| Spec, then tickets | Pocock `/to-spec`, then `/to-tickets` |
| One ticket, or one slice not split into tickets | pstack `/poteto-mode <ticket>` |
| Spec with two or more tickets, even a chain where only one ticket is ready at a time | Pocock `/implement-spec`, each implementer started with `/poteto-mode` (see below) |
| Tests | Pocock `/tdd` |
| Something broken | Pocock `/diagnosing-bugs` |
| Review | Pocock `/code-review` on every change; pstack `interrogate` only for auth, sandbox or secret handling |
| Proof against the real surface | pstack `create-verification-skill` |
| Look back after a build | Pocock `/retro` |

## Implementer kickoff for `/implement-spec`

Tell `/implement-spec` to start every implementer prompt with this text. pstack `worker.md` honours an override only when the prompt states it in so many words.

```text
/poteto-mode <ticket ref>
Overrides (explicit, per worker.md):
- Do not open a PR. Merge the integration branch tip into your branch and report.
- A spec-level `code-review` follows this ticket; that is the operator's bar.
- Use Pocock `tdd` for tests: failing test before each unit.
- Cursor-only items do not exist here (poteto-agent, pstack-models.mdc, /deslop, control-cli); use this harness's task agents and model roles.
```

## Known gaps

- `/poteto-mode` asks for things that only exist in Cursor: `subagent_type: poteto-agent`, Cursor model slugs, `~/.cursor/rules/pstack-models.mdc`, and `/deslop` and `control-cli` from `cursor-team-kit`. In other harnesses the agent must use what that harness has instead.
- The kept Pocock skills `ask-matt` and `retro` still name skills this set removes (`/implement`, `/triage`, `/handoff`, `/improve-codebase-architecture`, `writing-for-agents`). Use `/using-hybrid-dev` instead of `/ask-matt`.
