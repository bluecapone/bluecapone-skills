---
name: nlm-research
description: Multi-source research pipeline (personal, NotebookLM-backed) — smart source selection, parallel gathering via the `web-search` skill (agy+Firecrawl ensemble) + Context7 + Fabric + Grok, aggregates into NotebookLM, queries iteratively for source-grounded synthesis. Optional `quick-search` for mid-pipeline fact lookups and `reasoned-search` for end-pipeline chain-of-thought follow-ups. Use when the user says "research this", "investigate", "compare options", "deep dive", "what are the best options for", "quais são as melhores opções para", or types `/nlm-research "topic"`. Triggers on requests for multi-source investigation, technology comparisons, or in-depth analysis beyond a single search. Distinct from matt-pocock-skills' `research` skill (AFK wayfinder ticket resolver).
---

# Research :: Deep Dive

Trigger this skill when the user says: "research this", "investigate", "compare options", "deep dive", "what are the best options for", or types `/nlm-research "topic"`.

## How It Works

This skill orchestrates a 5-phase local research pipeline using Claude Code's MCP tools and CLI commands. No external workflow engine required — everything runs locally.

## Tool Inventory

| Tool | Type | Invocation |
|------|------|------------|
| **web-search** skill | Sibling skill | `Skill(skill='web-search', args='topic')` — agy+Firecrawl ensemble, dedup, [via X] provenance tags. Replaces direct WebSearch/Firecrawl URL-discovery calls. |
| NotebookLM | CLI (`nlm`, package `notebooklm-mcp-cli`) | `nlm notebook create` / `nlm source add` / `nlm notebook query` via Bash — authenticated via `nlm login` (stored per-profile; check with `nlm login --check`). The `nlm` binary is on PATH. |
| Context7 | Plugin (MCP) | `mcp__plugin_context7_context7__resolve-library-id`, `query-docs` |
| Grok | Skill | `Skill(skill='grok:ask', args='...')` |
| Firecrawl (scrape) | CLI | `firecrawl search "query" --scrape --limit N -o path --json` via Bash — used only for deep content scraping of selected URLs (Phase 2 Batch B); URL discovery goes through `web-search` skill |
| Fabric | CLI | `fabric-ai -y "URL" --pattern extract_wisdom` via Bash |
| **quick-search** skill | Sibling skill (optional) | `Skill(skill='quick-search', args='specific factual question')` — mid-pipeline fact gap fill |
| **reasoned-search** skill | Sibling skill (optional) | `Skill(skill='reasoned-search', args='reasoning question grounded in sources')` — Phase 4 CoT follow-up |

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
- Always invoke the `web-search` skill as the URL-discovery backbone (it runs agy + Firecrawl in parallel internally and returns ranked URLs with provenance tags).
- Use Firecrawl scrape (Phase 2 Batch B) only for deep-content extraction of URLs surfaced by `web-search`, when the query needs full page bodies (not just snippets).
- Tell the user which sources were selected and why before proceeding.
- If the user passed specific sources in args (e.g., `/nlm-research "topic" sources=web-search,grok`), honor that override.

### Phase 2: Parallel Source Gathering

Use **background agents** for independent source gathering. This runs sources truly in parallel while the skill orchestrates.

**Step 1 — Spawn parallel agents (one message, multiple Agent calls):**

Launch up to 3 background agents, each responsible for a group of sources:

```
Agent(
  name="research-web",
  description="Web research gathering via web-search skill",
  run_in_background=true,
  prompt="Research '{topic}'. Invoke the `web-search` skill on '{topic}' — the skill internally runs agy + Firecrawl in parallel, dedupes by canonical URL, and returns ranked URLs tagged with [via agy], [via Firecrawl], or [via both]. The skill recipe lives at plugins/web-search/skills/web-search/SKILL.md.
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
- `Skill(skill='web-search', args='topic')` — agy+Firecrawl ensemble for URL discovery and snippets (replaces ad-hoc WebSearch/Firecrawl calls; `web-search` does both internally)
- `mcp__plugin_context7_context7__resolve-library-id` + `query-docs` — if library detected
- `Skill(skill='grok:ask')` — if social/current signal
- `Skill(skill='quick-search', args='specific factual question')` — OPTIONAL, only if a small factual gap is identified mid-pipeline (e.g. "what year did X launch", "who is the current CEO of Y"). Skip if not applicable.

Batch B (CLI tools + Fabric, after Batch A returns URLs):
- `firecrawl search "QUERY" --limit 10 --scrape -o .firecrawl/search-SLUG-scraped.json --json` — OPTIONAL, scrape top URLs returned by `web-search` for deep content. Skip if `web-search` snippets already cover the topic.
- `fabric-ai -y "URL" --pattern extract_wisdom` per YouTube URL (max 4, skip on failure)
- `fabric-ai -u "URL" --pattern extract_wisdom` per key article (max 3)

**Decision: agents vs direct calls:**
- 3+ sources activated → use background agents (true parallelism)
- 1-2 sources → use direct calls (less overhead)

**Failure handling:** Each source is independent. If any fails:
- `web-search` skill: if its internal agy call fails (auth/rate-limit), the skill falls back to Firecrawl-only and warns. If both agy AND Firecrawl fail inside `web-search`, the pipeline continues with whatever else was activated (Fabric/Context7/Grok); note the degradation in the final report.
- Fabric: no captions → skip with log. Try `--transcript` (no timestamps) once as fallback.
- Context7: empty result → skip.
- Grok: API error or missing → skip with warning.
- Firecrawl scrape (Batch B): timeout → skip.
- `quick-search` skill: if its agy call fails → skip the optional fact-lookup; the missing fact gets flagged in the report's "manual verification needed" section.
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
   Prioritize: `web-search` top-ranked URLs (look for [via both] tags first — those are corroborated by agy AND Firecrawl), documentation URLs, repo URLs.
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
   - `[quick-search] {fact-question} - {date}` (if used)

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

### Phase 4b: Optional CoT follow-up via reasoned-search

After the NotebookLM rounds, if a reasoning question emerges that needs **explicit chain-of-thought** rather than corpus synthesis (math/logic/comparison), invoke:

```
Skill(skill='reasoned-search', args='reasoning question grounded in the gathered sources')
```

The `reasoned-search` skill returns a step-by-step CoT with conclusion, assumptions, manual-verification list, and citations. Use when:

- NotebookLM answered correctly but the **reasoning path** matters (e.g. "show the math behind X").
- Multiple sources disagree and you want a structured comparison with explicit weighing.
- The deliverable needs visible logic (e.g. user is preparing an argument or a memo).

**Budget:** 1–2 `reasoned-search` invocations per pipeline. It's the most expensive step (Codex o3 — $0.04+ and 15-60s latency).

### Phase 4c: Fallback (if NotebookLM fails)

If notebook creation or source addition fails entirely, synthesize directly from the gathered raw text (`web-search` ranked URLs + Firecrawl scraped content + Fabric wisdom outputs provide grounded raw data). Note the degradation in the report.

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
| quick-search ({N} lookups) | success/skipped | {fact gaps filled, if any} |
| reasoned-search ({N} invocations) | success/skipped | {CoT follow-ups, if any} |

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
- This skill **composes** three sibling skills as building blocks: `web-search` (URL discovery backbone, Phase 2), `quick-search` (optional mid-pipeline fact lookups, Phase 2), `reasoned-search` (optional CoT follow-ups, Phase 4b). Improvements to those siblings propagate automatically.
- **Agent-agnostic composition:** the `Skill(skill='X', args='...')` syntax works in Claude Code natively; in agy (Antigravity CLI) the equivalent skill invocation is used; in Codex the recipe is followed manually via `codex exec` (see each sibling skill's SKILL.md "Cross-agent usage" section).
- NotebookLM aggregation provides source-grounded citations that raw synthesis cannot match.
- Fabric outputs are also saved locally to `~/fabric-output/` for future reference.
- Firecrawl scrape outputs are saved to `.firecrawl/` in the current working directory.
- If the user asks for a subset of sources, honor their selection.
- Context7 works best for well-known libraries (React, Next.js, etc.) — may return empty for niche tools.
