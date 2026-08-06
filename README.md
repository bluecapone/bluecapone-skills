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
2. **Firecrawl CLI** (deep-content scraping, Phase 2 Batch B):
   ```bash
   npm install -g firecrawl-cli   # or: npx firecrawl <command> per-invocation
   firecrawl config               # set FIRECRAWL_API_KEY
   ```
3. **Fabric** (`fabric-ai`, YouTube/article wisdom extraction):
   ```bash
   go install github.com/danielmiessler/fabric/cmd/fabric@latest
   fabric --setup   # configure an LLM vendor + API key
   ```
   `go install` names the binary `fabric`; this skill calls it as
   `fabric-ai` (to avoid clashing with other tools named `fabric` on
   `PATH`) — alias or symlink it: `ln -s "$(command -v fabric)" ~/go/bin/fabric-ai`.
4. **Context7** — MCP server/plugin providing
   `mcp__*context7__resolve-library-id` / `query-docs`. Configure per your
   agent's MCP setup; this skill assumes it's already reachable and skips
   it (not an error) if the tools aren't present.
5. **Grok** — a `grok:ask` skill/tool your agent exposes for X/current-events
   queries. Optional; skipped if unavailable.

## Known limitation: sibling skill dependencies aren't published yet

This skill composes three sibling skills as building blocks — **`web-search`**
(required, the URL-discovery backbone for Phase 2), **`quick-search`** and
**`reasoned-search`** (both optional). None of the three are published to a
public repo yet, so `npx skills add` can't fetch them for you. Until they
are, `nlm-research` will fail on any step that invokes
`Skill(skill='web-search', ...)` unless you separately install an
equivalent URL-discovery skill under that name, or patch Phase 2 in
`skills/nlm-research/SKILL.md` to call whatever web-search tool your agent
already has.

## Skill

- [`skills/nlm-research/SKILL.md`](skills/nlm-research/SKILL.md) — the skill definition
- [`skills/nlm-research/scripts/nlm-query.sh`](skills/nlm-research/scripts/nlm-query.sh) — `nlm` CLI wrapper used by the pipeline
