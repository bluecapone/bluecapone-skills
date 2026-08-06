# nlm-research

Multi-source research pipeline skill for AI coding agents — smart source
selection, parallel gathering across web search, Context7, Firecrawl,
Fabric, and Grok/X, aggregated into NotebookLM, queried iteratively for
source-grounded synthesis. All local — no external workflow engine.

## Install

```bash
npx skills add <owner>/nlm-research
```

## Skill

- [`skills/nlm-research/SKILL.md`](skills/nlm-research/SKILL.md) — the skill definition
- [`skills/nlm-research/scripts/nlm-query.sh`](skills/nlm-research/scripts/nlm-query.sh) — NotebookLM CLI wrapper used by the pipeline

## Requirements

- [`nlm`](https://github.com/) CLI installed and authenticated (`nlm login`) for the NotebookLM aggregation phase
- A `web-search` skill (or equivalent URL-discovery tool) installed alongside this one — `nlm-research` delegates URL discovery to it rather than duplicating it
