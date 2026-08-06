---
name: nlm-research
description: Runs multi-source research (web, Context7, Fabric, Grok) into NotebookLM for grounded synthesis. Use when the user says "research this", "deep dive", or types /nlm-research.
---

# Research :: Deep Dive

Trigger this skill when the user says: "research this", "investigate", "compare options", "deep dive", "what are the best options for", or types `/nlm-research "topic"`.

## How It Works

This skill orchestrates a 5-phase local research pipeline using Claude Code's MCP tools and CLI commands. No external workflow engine required — everything runs locally.

## Prerequisites

- **agy** (Antigravity CLI), authenticated — powers the ensemble URL discovery below.
- **Firecrawl CLI** (`firecrawl`), `FIRECRAWL_API_KEY` set (`firecrawl config` or `FIRECRAWL_API_KEY` env var) — URL discovery + Phase 2 Batch B deep scrapes.
- **jq** — used by `scripts/merge-results.sh` to dedupe/merge search results.
- **NotebookLM CLI** (`nlm`, package `notebooklm-mcp-cli`), authenticated via `nlm login` — Phase 3/4 aggregation and query.
- **Fabric** (`fabric-ai`) — YouTube/article wisdom extraction. Skipped gracefully if missing.
- **Context7** MCP plugin, **Grok** skill/tool — both optional, skipped gracefully if unreachable.

See the README's Setup section for install commands.

## Tool Inventory

| Tool | Type | Invocation |
|------|------|------------|
| **Web search (ensemble)** | Inlined recipe (agy + Firecrawl, parallel) | See "Ensemble web search recipe" below — runs agy + Firecrawl in parallel, dedupes by canonical URL via `scripts/merge-results.sh`, tags provenance `[via agy]`/`[via Firecrawl]`/`[via both]`. No external skill call. |
| NotebookLM | CLI (`nlm`, package `notebooklm-mcp-cli`) | `nlm notebook create` / `nlm source add` / `nlm notebook query` via Bash — authenticated via `nlm login` (stored per-profile; check with `nlm login --check`). The `nlm` binary is on PATH. |
| Context7 | Plugin (MCP) | `mcp__plugin_context7_context7__resolve-library-id`, `query-docs` |
| Grok | Skill | `Skill(skill='grok:ask', args='...')` |
| Firecrawl (scrape) | CLI | `firecrawl search "query" --scrape --limit N -o path --json` via Bash — used only for deep content scraping of selected URLs (Phase 2 Batch B); URL discovery goes through the inlined ensemble recipe |
| Fabric | CLI | `fabric-ai -y "URL" --pattern extract_wisdom` via Bash |

## Ensemble web search recipe

Formerly delegated to a separate `web-search` sibling skill; inlined here so
`nlm-research` has no hard external-skill dependency. Run BOTH commands **in
parallel** (single message, two Bash tool calls), unique `$PID` suffix to
avoid file collisions:

```bash
# Call A — agy (Antigravity CLI, Gemini-backed). Pin a FAST model, cap with agy's
# NATIVE --print-timeout, fall back to an empty array so a slow agy never blocks
# the pipeline (Firecrawl is the baseline).
agy -p "List 8-12 ranked URLs for: '$QUERY'. For each, return JSON with fields: title, url, snippet, date_published (if known). Return as JSON array. Do NOT synthesize, do NOT add commentary. Output ONLY the JSON array, no markdown fences." \
  --model "Gemini 3.5 Flash (Low)" --print-timeout 90s > /tmp/ws-$$-agy.json 2>/dev/null || echo "[]" > /tmp/ws-$$-agy.json

# Call B — Firecrawl (curated AI index + scrape)
firecrawl search "$QUERY" --limit 10 -o /tmp/ws-$$-firecrawl.json --json
```

Key gotchas (verified live on agy v1.0.6): no `-o json` flag on agy — the
JSON comes from the prompt, strip stray markdown fences before parsing;
read-only search/grounding tools auto-run in agy print mode, no approval
prompt; use agy's native `--print-timeout` (default 5m) instead of an
external `timeout` wrapper, keeping the command starting with `agy -p` so it
matches the `Bash(agy -p:*)` permission rule.

Merge the two outputs with the bundled script (dedupe by canonical URL,
`[via both]`/`[via agy]`/`[via Firecrawl]` provenance tags, corroborated
results ranked first):

```bash
bash "$SKILL_DIR/scripts/merge-results.sh" /tmp/ws-$$-agy.json /tmp/ws-$$-firecrawl.json
```

**Error handling:** both providers fail → stop, report clearly, do NOT
fabricate URLs. One provider fails → continue with the survivor, prefix
output with a one-line warning (e.g. `> Note: agy failed (reason); results
from Firecrawl only.`). Empty results from both → report "no results", no
fabrication.


## Workflow

### Phase 1: Topic Classification (Smart Source Selection)

Before hitting any source, classify the query to decide which sources are relevant. This avoids wasting API calls and tokens.

**Classification heuristic:**

| Signal in query | Sources to activate |
|---|---|
| Names a library/framework/SDK | Context7 + web-search |
| Current events / "latest" / news | web-search + Grok |
| Social/community sentiment / "what are people saying" | Grok (X/Twitter) + web-search |
| YouTube URLs or video/talk/conference references | Fabric (extract_wisdom) + web-search |
| Technical comparison / "best options for" | web-search + Context7 |
| Security/threat topic | Grok + web-search |
| General research (default) | web-search |

**Rules:**
- Always run the "Ensemble web search recipe" (above) as the URL-discovery backbone — it runs agy + Firecrawl in parallel and returns ranked URLs with provenance tags.
- Use Firecrawl scrape (Phase 2 Batch B) only for deep-content extraction of URLs the ensemble recipe surfaced, when the query needs full page bodies (not just snippets).
- Tell the user which sources were selected and why before proceeding.
- If the user passed specific sources in args (e.g., `/nlm-research "topic" sources=web-search,grok`), honor that override.

### Phase 2: Parallel Source Gathering

Use **background agents** for independent source gathering. This runs sources truly in parallel while the skill orchestrates.

**Step 1 — Spawn parallel agents (one message, multiple Agent calls):**

Launch up to 3 background agents, each responsible for a group of sources:

```
Agent(
  name="research-web",
  description="Web research gathering via inlined ensemble recipe",
  run_in_background=true,
  prompt="Research '{topic}'. Run the ensemble web search recipe on '{topic}': agy + Firecrawl in parallel (see the parent skill's 'Ensemble web search recipe' section for the exact commands), dedupe by canonical URL via scripts/merge-results.sh, tag provenance [via agy]/[via Firecrawl]/[via both].
    Return: the full ranked URL list with titles, snippets, dates, and provenance tags. Do NOT synthesize."
)

Agent(
  name="research-scrape",
  description="Web scraping + YouTube",
  run_in_background=true,
  prompt="Research '{topic}'. Use these tools:
    1. firecrawl search '{topic}' --limit 10 --scrape -o .firecrawl/search-SLUG-scraped.json --json
    2. For each YouTube URL found (max 4): fabric-ai -y URL --transcript-with-timestamps --pattern extract_wisdom -o ~/fabric-output/DATE-extract_wisdom-SLUG.md
    3. For key articles found (max 3): fabric-ai -u URL --pattern extract_wisdom
    Skip any source that fails. Return: firecrawl results summary, fabric wisdom outputs, all URLs found."
)

Agent(
  name="research-specialized",
  description="Specialized source gathering",
  run_in_background=true,
  prompt="Research '{topic}'. Use ONLY the sources relevant to this query:
    - If library/framework: mcp__plugin_context7_context7__resolve-library-id + query-docs
    - If social/current: Skill(skill='grok:ask', args='{topic}')
    - If neither applies: skip with a note saying 'no specialized sources needed'
    Return: Context7 docs and/or Grok results, or skip explanation."
)
```

**Step 2 — Collect results as agents complete:**

You will be notified as each agent finishes. Collect their outputs — do NOT poll or sleep.
Continue to Phase 3 once all agents have returned (or after 3 minutes, proceeding with whatever has completed).

**Step 3 — Direct MCP calls (if agents are overkill):**

For simpler queries where spawning agents is overhead, fall back to direct tool calls in the main conversation:

Batch A (sibling skills + MCP, all in one message):
- Run the "Ensemble web search recipe" above (agy + Firecrawl in parallel + `merge-results.sh`) for URL discovery and snippets — replaces ad-hoc WebSearch/Firecrawl calls, no external skill invocation
- `mcp__plugin_context7_context7__resolve-library-id` + `query-docs` — if library detected
- `Skill(skill='grok:ask')` — if social/current signal

Batch B (CLI tools + Fabric, after Batch A returns URLs):
- `firecrawl search "QUERY" --limit 10 --scrape -o .firecrawl/search-SLUG-scraped.json --json` — OPTIONAL, scrape top URLs returned by the ensemble recipe for deep content. Skip if the ensemble recipe's snippets already cover the topic.
- `fabric-ai -y "URL" --pattern extract_wisdom` per YouTube URL (max 4, skip on failure)
- `fabric-ai -u "URL" --pattern extract_wisdom` per key article (max 3)

**Decision: agents vs direct calls:**
- 3+ sources activated → use background agents (true parallelism)
- 1-2 sources → use direct calls (less overhead)

**Failure handling:** Each source is independent. If any fails:
- Ensemble web search recipe: if the agy call fails (auth/rate-limit), it falls back to Firecrawl-only and warns. If both agy AND Firecrawl fail, the pipeline continues with whatever else was activated (Fabric/Context7/Grok); note the degradation in the final report.
- Fabric: no captions → skip with log. Try `--transcript` (no timestamps) once as fallback.
- Context7: empty result → skip.
- Grok: API error or missing → skip with warning.
- Firecrawl scrape (Batch B): timeout → skip.
- Agent doesn't return within 3 min → proceed without it.
- The pipeline NEVER halts on a single source failure.

### Phase 3: NotebookLM Aggregation

After gathering, create a single NotebookLM notebook and load all results via the `nlm` CLI (`notebooklm-mcp-cli` package, authenticated via `nlm login`). All calls run through Bash.

1. **Create notebook** (capture the ID from JSON output):
   ```bash
   NB_ID=$(nlm notebook create "Research: {topic} - {YYYY-MM-DD}" --json | python3 -c "import sys,json; print(json.load(sys.stdin)['notebook']['id'])")
   ```

2. **Add URL sources** — `source add` takes the notebook ID positionally and one or more `--url` flags (repeatable, so batch what you can into one call):
   ```bash
   nlm source add "$NB_ID" --url "$url1" --url "$url2" --url "$url3" --wait
   ```
   Prioritize: ensemble-recipe top-ranked URLs (look for [via both] tags first — those are corroborated by agy AND Firecrawl), documentation URLs, repo URLs.
   Skip: X/Twitter post URLs (NLM cannot crawl them), duplicate URLs.

3. **Add text sources** — one call per gathered text blob:
   ```bash
   nlm source add "$NB_ID" --text "{text blob}" --title "[Source] Topic - Date" --wait
   ```

   **Source naming convention:**
   - `[Grok/X] {topic} - {date}`
   - `[Context7] {topic} - {date}`
   - `[Fabric-YT] {video title} - {date}`
   - `[Firecrawl-scrape] {topic} - {date}` (only for Batch B deep scrapes)
   - `[web-search] {topic} - {date}` (URL discovery output, summarized)

4. **Indexing** — `--wait` on `source add` itself blocks until that call's source(s) finish processing (default timeout 600s via `--wait-timeout`); there is no separate poll/wait subcommand. Run the `source add` calls in a background agent so the main conversation can continue while they block.

### Phase 4: Iterative NotebookLM Q&A

Query NotebookLM for source-grounded, citation-backed synthesis. Max 5 rounds.

```bash
nlm notebook query "$NB_ID" "..." --json
```

Each call is independent unless you pass `--conversation-id`/`-c` to continue a specific prior conversation — there is no "continues by default" or `--new` behavior; the CLI has no implicit conversation memory. `--json` returns the answer plus the source references behind each `[n]` citation.

**Confidence-based loop:**

1. **Round 1:** Ask the main research question — `nlm notebook query "$NB_ID" "Provide a comprehensive answer to: {original query}" --json`, capture the `conversation_id` from the JSON response.
2. **Evaluate:** Is the answer comprehensive? Are there gaps, uncovered angles, contradictions between sources?
3. **Rounds 2-5:** Target specific gaps identified in the previous round — pass the captured `conversation_id` via `-c` on each follow-up call to keep it in the same thread: `nlm notebook query "$NB_ID" "..." -c "$CONV_ID" --json`.
4. **Stop early** if the answer is comprehensive (self-assessed) or max rounds reached.

### Phase 4b: Fallback (if NotebookLM fails)

If notebook creation or source addition fails entirely, synthesize directly from the gathered raw text (ensemble-recipe ranked URLs + Firecrawl scraped content + Fabric wisdom outputs provide grounded raw data). Note the degradation in the report.

### Phase 5: Deliver Report

Present findings in this structure:

```markdown
## Executive Summary
{Source-grounded answer from NotebookLM Q&A rounds, or synthesized from raw data if NLM failed}

## Key Findings
{Detailed findings organized by theme, with [Source] citations}

## Sources Used
| Source | Status | Key Contribution |
|--------|--------|-----------------|
| web-search (agy+Firecrawl ensemble) | success/degraded/skipped | {N URLs, {M} [via both] corroborated} |
| Context7 ({library}) | success/skipped | {contribution or why skipped} |
| Grok/X | success/skipped | {contribution} |
| Firecrawl scrape ({N} pages) | success/skipped | {deep content from selected URLs, if Batch B ran} |
| Fabric ({N} videos/articles) | partial/success/skipped | {contribution} |

## URLs Discovered
- [{title}]({url}) (from {source})

## Confidence
{High/Medium/Low} — based on source agreement, coverage breadth, and NLM Q&A depth

## NotebookLM
Notebook: "{name}" (ID: `{notebook_id}`)
Query further with: `nlm notebook query {notebook_id} "your question"`
```

## Background Mode

If the user says "run in background", "continue as agent", "finish this autonomously", or "do this in background":

1. **Summarize current state** — what's been gathered so far, which phases are complete
2. **Spawn a background agent** with all context:
   ```
   Agent(
     subagent_type="research-assistant",
     run_in_background=true,
     prompt="Continue this research on '{topic}'.
       State so far: {summary of gathered data}
       NotebookLM notebook ID: {NB_ID or 'not created yet'}
       Remaining phases: {list of phases left}
       Deliver the final structured report when done."
   )
   ```
3. **Tell the user**: "Research handed off to background agent. You'll be notified when it's done. Notebook ID: {NB_ID}"
4. The user can continue working on other tasks immediately.

## Notes

- All orchestration runs locally — no external workflow engine needed.
- Web search (URL discovery, Phase 2) is **inlined** directly in this skill (agy+Firecrawl ensemble, see "Ensemble web search recipe") — no external skill dependency.
- NotebookLM aggregation provides source-grounded citations that raw synthesis cannot match.
- Fabric outputs are also saved locally to `~/fabric-output/` for future reference.
- Firecrawl scrape outputs are saved to `.firecrawl/` in the current working directory.
- If the user asks for a subset of sources, honor their selection.
- Context7 works best for well-known libraries (React, Next.js, etc.) — may return empty for niche tools.
