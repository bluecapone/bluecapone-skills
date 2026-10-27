---
name: what-skill
description: Recommend which agent skill to use for a task and give the exact command to install it. Use when the user asks "which skill should I use", "is there a skill for X", wants to compare skill packs (Matt Pocock skills, Addy Osmani agent-skills, pstack, gstack, superpowers), or wants install instructions for a skill.
---

# what-skill

Match a task to the agent skill that fits it best, then give the exact command to install that skill.

`$SKILL_DIR` is the directory containing this `SKILL.md`. It ships two references:

- `$SKILL_DIR/references/catalog.md`: every publicly installable skill the catalog script found, grouped by category, with pack, a one-line description and the install command.
- `$SKILL_DIR/references/packs.md`: a cited comparison of the big packs (Pocock, Osmani, pstack, gstack, superpowers): what each believes in, verbatim install commands, what the comparison videos found, and an overlap map (section 6).

## Workflow

1. Restate the user's job in one line and map it to one catalog category (for example `Planning & requirements`, `Debugging`, `Testing & verification`).
2. Check the **Pack picker** below and the overlap map (section 6) in `$SKILL_DIR/references/packs.md`.
3. Search the catalog for the job's keywords (shell `grep` or your agent's search tool), starting with the mapped `## <Category>` section:

   ```bash
   grep -i -E 'tdd|test-driven' "$SKILL_DIR/references/catalog.md"
   ```

4. Check what is already installed: run `npx skills list` (project) and `npx skills ls -g` (global), and look in `.claude/skills/`, `.agents/skills/` and `~/.claude/skills/`. If a suitable skill is already installed, say so and do not suggest installing it again.
5. Answer with one primary pick and at most two alternatives. For each, give:
   - the skill name and its pack,
   - one line on why it fits (cite the video or README from `packs.md` when the reason comes from there),
   - the install command from its catalog row. Add `-g` to install globally. If the pack has a Claude Code marketplace, also give its `/plugin` commands from `packs.md`.
6. Do not run install commands unless the user explicitly asks you to. When they do, run the exact command you showed.

## Pack picker

| Situation | Pick | Source |
|---|---|---|
| Big, vague feature with time to research first | Pocock `wayfinder` → `to-spec` → `to-tickets` | V2 (The Gray Cat) |
| Everyday feature work; build shared vocabulary as you go | Pocock `grill-with-docs`, `tdd`, `diagnosing-bugs` | V2, V3 |
| Predictable full lifecycle with review and ship gates | Osmani `/spec` `/plan` `/build` `/test` `/review` `/ship` | V2 |
| Hard bug, perf work, deep single-agent rigor (Cursor or Claude Code) | pstack `/poteto-mode` | V5 (Ray Fernando), pstack README |
| Role-based "virtual team" sprint (CEO/eng/design/QA/ship) | gstack | gstack README |
| Fast plan-then-subagent execution | superpowers | V3 |

Video IDs (V1–V5) and README sources are listed in `packs.md` section 1.

## Rules

- Pick one pack per concern. Overlapping packs (for example Pocock `tdd` and Osmani `test-driven-development`) fight over the same triggers. Pocock's README says "Pick one".
- Do not install every skill. V1 calls running every skill on every project "overkill".
- Whatever the pack, the user still has to check the app by hand (V2, V3).
- The per-job verdict of V1 is unverified because it has no transcript. Never quote it as fact.
- gstack and superpowers install as whole packs (gstack via `git clone` + `./setup`, superpowers via `/plugin install`). The catalog shows that pack command on each of their rows.

## Refreshing the catalog

```bash
python3 "$SKILL_DIR/scripts/build-catalog.py" --root <dir with your clones>
```

`--root` is the directory that holds your skill repo clones (it can also come from the `SKILLS_ROOT` environment variable). The script rescans it for `SKILL.md` files and rewrites `references/catalog.md`. It keeps only skills it can trace to a public GitHub repo. It needs network access to confirm each source is public, and it exits with code 2 rather than write a partial catalog. It is only useful on a machine that has the clones. If the date on the catalog's `Generated … on` line is more than 30 days old and the root exists, offer to rerun it.
