# nlm-research

Multi-source research pipeline skill for AI coding agents — smart source
selection, parallel gathering across web search, Context7, Firecrawl,
Fabric, and Grok/X, aggregated into NotebookLM, queried iteratively for
source-grounded synthesis. All local — no external workflow engine.

## Install

```bash
npx skills add bluecapone/nlm-research
```

`npx skills` only copies/symlinks the skill's files (`SKILL.md` + scripts)
into your agent's skill directory — it has **no** postinstall/setup hook or
dependency resolver. Everything below is manual, one-time, per machine.

## Setup

Run these after `npx skills add`, before first use:

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

## No external skill dependencies

`web-search` (URL discovery) is **inlined directly** into
`skills/nlm-research/SKILL.md` (agy + Firecrawl ensemble via
`scripts/merge-results.sh`) — no external skill call for it. This pipeline
has no sibling-skill dependencies of any kind.

## Skill

- [`skills/nlm-research/SKILL.md`](skills/nlm-research/SKILL.md) — the skill definition
- [`skills/nlm-research/scripts/nlm-query.sh`](skills/nlm-research/scripts/nlm-query.sh) — `nlm` CLI wrapper used by the pipeline
- [`skills/nlm-research/scripts/merge-results.sh`](skills/nlm-research/scripts/merge-results.sh) — dedupes/merges the inlined ensemble web-search results

## Quality checks

```bash
scripts/lint-skill.sh   # validates SKILL.md frontmatter (name/description) against the spec
```

