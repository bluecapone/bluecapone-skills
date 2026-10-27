# bluecapone-skills

Agent skills by bluecapone. This repo is both a Claude Code plugin
marketplace (one plugin per skill) and an `npx skills` source.

## Install

**npx skills** (any supported agent):

```bash
npx skills add bluecapone/bluecapone-skills                        # all skills
npx skills add bluecapone/bluecapone-skills -s nlm-research        # one skill
npx skills add bluecapone/bluecapone-skills -s super-productivity
npx skills add bluecapone/bluecapone-skills -s what-skill
```

`npx skills` only copies/symlinks each skill's files (`SKILL.md` + scripts)
into your agent's skill directory. It has **no** postinstall/setup hook or
dependency resolver; per-skill setup below is manual, one-time, per machine.

**Claude Code** plugin marketplace:

```text
/plugin marketplace add bluecapone/bluecapone-skills
/plugin install nlm-research@bluecapone-skills
/plugin install super-productivity@bluecapone-skills
/plugin install what-skill@bluecapone-skills
```

## Skills

### nlm-research

Multi-source research pipeline: smart source selection, parallel gathering
across web search, Context7, Firecrawl, Fabric, and Grok/X, aggregated into
NotebookLM, queried iteratively for source-grounded synthesis. All local, no
external workflow engine.

- [`skills/nlm-research/SKILL.md`](skills/nlm-research/SKILL.md): the skill definition
- [`skills/nlm-research/scripts/nlm-query.sh`](skills/nlm-research/scripts/nlm-query.sh): `nlm` CLI wrapper used by the pipeline
- [`skills/nlm-research/scripts/merge-results.sh`](skills/nlm-research/scripts/merge-results.sh): dedupes/merges the inlined ensemble web-search results

#### Setup

Run these after installing, before first use:

1. **NotebookLM CLI** (`nlm`, aggregation phase — Phase 3/4):
   ```bash
   uv tool install notebooklm-mcp-cli   # or: pipx install notebooklm-mcp-cli
   nlm login                            # opens a browser-based Google auth flow
   nlm login --check                    # verify auth landed
   ```
2. **agy** (Antigravity CLI, ensemble web-search URL discovery — Phase 2), authenticated:
   ```bash
   # install per https://antigravity.google/ — verify with:
   agy -p "test" --model "Gemini 3.5 Flash (Low)" --print-timeout 30s
   ```
3. **Firecrawl CLI** (paired with agy for ensemble URL discovery, plus deep-content scraping in Phase 2 Batch B):
   ```bash
   npm install -g firecrawl-cli   # or: npx firecrawl <command> per-invocation
   firecrawl config               # set FIRECRAWL_API_KEY
   ```
4. **Fabric** (`fabric-ai`, YouTube/article wisdom extraction):
   ```bash
   go install github.com/danielmiessler/fabric/cmd/fabric@latest
   fabric --setup   # configure an LLM vendor + API key
   ```
   `go install` names the binary `fabric`; this skill calls it as
   `fabric-ai` (to avoid clashing with other tools named `fabric` on
   `PATH`) — alias or symlink it: `ln -s "$(command -v fabric)" ~/go/bin/fabric-ai`.
5. **Context7** — MCP server/plugin providing
   `mcp__*context7__resolve-library-id` / `query-docs`. Configure per your
   agent's MCP setup; this skill assumes it's already reachable and skips
   it (not an error) if the tools aren't present.
6. **Grok** — a `grok:ask` skill/tool your agent exposes for X/current-events
   queries. Optional; skipped if unavailable.

#### No external skill dependencies

`web-search` (URL discovery) is **inlined directly** into
`skills/nlm-research/SKILL.md` (agy + Firecrawl ensemble via
`scripts/merge-results.sh`) — no external skill call for it. This pipeline
has no sibling-skill dependencies of any kind.

### super-productivity

Read and control a running [Super Productivity](https://super-productivity.com/)
desktop app through its Local REST API on `127.0.0.1:3876`: tasks, current
task, Focus Mode state, projects, and tags.

Requirements:

- Super Productivity desktop (Electron) app, running.
- **Settings → Misc → Enable local REST API** turned on. The app writes the
  per-device token to `local-rest-api-token` in its user data folder; the
  bundled helper reads it from there.
- `bash` and `curl` ≥ 7.55.

See [`skills/super-productivity/SKILL.md`](skills/super-productivity/SKILL.md)
and [`skills/super-productivity/scripts/sp-api.sh`](skills/super-productivity/scripts/sp-api.sh).

### what-skill

Recommends which agent skill to use for a task and gives the exact install
command. It reads a generated catalog of public skills plus a cited comparison
of the Pocock, Osmani, pstack, gstack and superpowers packs.

- [`skills/what-skill/SKILL.md`](skills/what-skill/SKILL.md): the skill definition
- [`skills/what-skill/scripts/build-catalog.py`](skills/what-skill/scripts/build-catalog.py): regenerates the catalog from local clones
- [`skills/what-skill/references/`](skills/what-skill/references/): `catalog.md` (generated) and `packs.md` (pack comparison)

Setup: none to use it. Refreshing the catalog needs `python3`, the local
clones, and network access (each source is checked to be public on GitHub).

## Quality checks

```bash
scripts/lint-skill.sh   # validates SKILL.md frontmatter (name/description) against the spec
```
