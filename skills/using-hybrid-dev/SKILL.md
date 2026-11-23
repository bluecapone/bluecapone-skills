---
name: using-hybrid-dev
description: Say which skill to run next in the hybrid Pocock + pstack development flow, from the repo's current state. A router like /ask-matt, for repos set up with hybrid-dev-skills.
disable-model-invocation: true
---

# Using hybrid dev

Every run ends with exactly one next command for the user. Do not run that command yourself, and do not change any file.

Before you name a skill, check that `.agents/skills/<name>/SKILL.md` or `.claude/skills/<name>/SKILL.md` exists. If it does not, the next command is the `hybrid-dev-skills` install script: `bash <path to hybrid-dev-skills>/scripts/install.sh`.

## 1. Read the state

Read only what decides the row in step 2:

- The text the user wrote after `/using-hybrid-dev`. This is the goal.
- Whether `docs/agents/issue-tracker.md` exists, and the tracker it names.
- Open issues on that tracker: a wayfinder map with open decision tickets, a spec, tickets and their blocking links, and which tickets are ready (no open blockers).
- `git status --short` and the current branch. An `implement-spec` integration branch shows that a build is in progress.

## 2. Pick the first row that matches

| # | State | Next |
|---|---|---|
| 1 | No `docs/agents/issue-tracker.md` | `/setup-matt-pocock-skills` |
| 2 | The user reports something broken | `/diagnosing-bugs` |
| 3 | A huge or unclear effort, or a map with open decision tickets | `/wayfinder` |
| 4 | The idea is not sharp yet | `/grill-with-docs` (in a repo) or `/grill-me` (no repo) |
| 5 | An open question needs code to answer, or needs reading to answer | `/prototype` or `/research` |
| 6 | Decisions are settled, and there is no spec | `/to-spec` |
| 7 | A spec exists, and there are no tickets | `/to-tickets` |
| 8 | One ticket, or one slice not split into tickets, is ready | `/poteto-mode <ticket>` |
| 9 | A spec has two or more open tickets, even a chain where only one is ready | `/implement-spec <spec>` with the kickoff below |
| 10 | Code is done but not reviewed | `/code-review` |
| 11 | A build just finished or went wrong | `/retro` |
| 12 | The next step needs a human (credentials, dashboards, secrets) | `/wizard` |
| 13 | The user did not understand the last message | `/wait-what` |

These run inside rows 8 and 9, not as separate steps:
- Pocock `/tdd` for tests.
- pstack `interrogate` after `/code-review`, only for work on auth, sandboxes or secrets.
- pstack `create-verification-skill` once the project has a CLI or an app to drive.

Kickoff for row 9. Tell `/implement-spec` to start every implementer prompt with this text:

```text
/poteto-mode <ticket ref>
Overrides (explicit, per worker.md):
- Do not open a PR. Merge the integration branch tip into your branch and report.
- A spec-level `code-review` follows this ticket; that is the operator's bar.
- Use Pocock `tdd` for tests: failing test before each unit.
- Cursor-only items do not exist here (poteto-agent, pstack-models.mdc, /deslop, control-cli); use this harness's task agents and model roles.
```

## 3. Reply

Use exactly this shape:

```text
Next: /<skill> <arguments>
Why: <the state fact that picked this row>
After that: /<skill that usually follows>
```

Add a `Missing:` line only when a skill needed for the next step is not installed.
