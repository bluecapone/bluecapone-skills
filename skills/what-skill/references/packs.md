# Skill packs: Pocock vs Pstack vs Osmani (+ gstack, superpowers)

Date: 2026-10-27. Reference for the `what-skill` skill: which skill pack to use for a task and how to install it.

Legend: **VERIFIED** = read from the cited primary source this session. **UNVERIFIED** = not read, or only a secondary summary. `LC/<dir>` = a local clone of the named GitHub repo; paths after it are repo-relative.

## 1. Sources

| ID | Source | Status |
|---|---|---|
| V1 | https://www.youtube.com/watch?v=sU9MW8Ycq2M (page + noembed) | read; **no transcript**, description truncated at chapters |
| V2 | https://www.youtube.com/watch?v=IDQs0VBL5UY | read incl. manual-subtitle transcript |
| V3 | https://www.youtube.com/watch?v=d8lxLTQhmPo | read incl. manual-subtitle transcript |
| V4 | https://www.youtube.com/watch?v=gAt_rRweR7Q (MINDUNG, pstack, Korean) | read; no transcript; description only |
| V5 | https://www.youtube.com/watch?v=ed4EHIMxuqA (Ray Fernando, poteto-mode) | read incl. transcript |
| P1 | `LC/skills` = mattpocock/skills (README, `.claude-plugin/*`) | local clone, read |
| P2 | `LC/agent-skills` = addyosmani/agent-skills (README, `.claude-plugin/*`) | local clone, read |
| P3 | `LC/plugins/pstack` + `LC/plugins/.cursor-plugin/marketplace.json` = cursor/plugins | local clone, read |
| P4 | https://github.com/garrytan/gstack (README via GitHub API, lines 1-424; later re-read from a fresh clone) | read |
| P5 | https://github.com/vercel-labs/skills (README, docs/commands.md, AGENTS.md, src/local-lock.ts via raw.githubusercontent.com) | read |
| P6 | https://github.com/obra/superpowers (README, fresh clone) | read |
| L1 | A local project's `skills-lock.json` (vercel `skills` lock format) | local, read |
| S1 | Two `web_search` runs ("Pocock vs Pstack vs Osmani", "Pocock vs gstack vs Osmani skills") | Search backend fell back to Gemini synthesis (Perplexity failed). Output is **secondary and UNVERIFIED**. Cited pages (claudeskills.xyz/compare/matt-pocock-vs-addy-osmani, medium.com/@martin.jordanovski/..., skills.addy.ie/compare/, skilldev.pro/en/skills/pstack-skill/, flaviocopes.com/pstack/, mindstudio.ai pstack post, svenroth.ai which-agent-skills-framework-for-which-job) were **not fetched**. |

## 2. Videos

### V1: "Pocock vs Pstack vs Osmani: Which Skill Pack Wins?"
- Channel: Rob Shocks - Switch Dimension. Uploaded 2026-10-07. 12:54. 130K views. URL https://www.youtube.com/watch?v=sU9MW8Ycq2M. (page + https://noembed.com/embed?url=https://youtu.be/sU9MW8Ycq2M)
- **Transcript: UNVERIFIED (none available).** Claims below come from the description only.
- Description claims (VERIFIED as description text):
  - Osmani agent-skills passed 100K GitHub stars; video breaks down Osmani's Define -> Plan -> Build -> Verify -> Review -> Ship lifecycle in Claude Code, Cursor, Codex.
  - Compares it with pstack and Matt Pocock's skills "to show when to use each one".
  - "why running every skill on every project is overkill". Goal: "learn the engineering practices behind these skills and build your own".
  - Links: addyosmani/agent-skills, mattpocock/skills, and **pstack = https://github.com/cursor/plugins/tree/main/pstack**. This resolves the P in the title (section 3).
  - Chapters visible only to `00:00 Intro`, `00:45 Who is Addy Osmani`; remainder truncated -> UNVERIFIED.
- Per-job verdict (which pack for which job): **UNVERIFIED**. Do not attribute S1's "choose Pocock if fuzzy requirements / pstack if subtle bugs / Osmani if production discipline" to this video; S1 cites it but the text matches third-party articles.

### V2: "Matt Pocock vs Addy Osmani: I Tested Both Skill Packs"
- Channel: The Gray Cat. Uploaded 2026-08-27. 14:33. 28K views. https://www.youtube.com/watch?v=IDQs0VBL5UY (https://noembed.com/embed?url=https://youtu.be/IDQs0VBL5UY). Transcript: manual subtitles, VERIFIED.
- Method: same feature (script-free cleanup in his app "The Gray Cut"), one frozen commit, Claude Opus 5 medium effort, Beads as issue tracker, orchestrator + subagents for build in both.
- Pocock arm used **Wayfinder** (heaviest route) -> `to-spec` -> `to-tickets` -> implement. 102 min and 34.9M tokens before implementation; run button stayed disabled (expected a script); 2 of 8 tickets unreachable in production; promised inline editing missing. Total 107.7M tokens, 290 min.
- Osmani arm: `/spec`, `/plan`, build (66 min parallel), test step was a no-op (build already wrote tests), review looped 3 rejects before approval, `/ship` ran 3 subagents. Verification ~45M tokens vs build ~42M; total 93.8M tokens, 108 min. Review queue rendered empty on screen.
- Cost as stated in V2: $87.25 (Pocock) vs $86.46 (Osmani). **Corrected in V3**: both $96.01 (output tokens missed).
- Recommendations:
  - Pocock **Wayfinder only for big, vague features** with time to research; then `grill-me` + verify each phase. For daily work he uses **`grill-with-docs`** plus adversarial Codex review.
  - Osmani: "more predictable lifecycle"; review/ship "found and fixed quite a few defects".
  - Other praised skills: Pocock `improve-codebase-architecture` (top-5 findings as HTML report); Osmani `doubt-driven-development` and `security-and-hardening`.
  - Both packs: "you still have to verify the app manually"; unit tests and planning missed dead UI path. Suggests smaller phases with verification between each. "We don't necessarily have to choose between these two."
- Caveat: one feature, one run per arm; not pstack/gstack.

### V3: "I Tested Superpowers v6 vs Grill Me: The Results Are Shocking"
- Channel: The Gray Cat. Uploaded 2026-09-08. 9:47. 59K views. https://www.youtube.com/watch?v=d8lxLTQhmPo (https://noembed.com/embed?url=https://youtu.be/d8lxLTQhmPo). Transcript VERIFIED.
- Scope: **Superpowers v6 vs Pocock `grill-with-docs` route**, not Pstack/Osmani. Relevant because it re-scores the Pocock/Osmani numbers.
- Results: Superpowers 78 active min, 55.9M tokens, $34.04 API-equivalent, no visible UI defect. Pocock retry 148 min, 119.7M tokens, $91.53 (~$94.05 incl. repair); built more (861 vs 236 prod lines, editable saved script, vocabulary hints) but player/timeline missing until repair.
- Method flaw he admits: only 3 of 8 Pocock workers received full `implement` skill (it has `disable-model-invocation`; others got plain-text invocation), so Pocock result "limits what this run can tell us about the skills themselves". Pocock plugin had 32 new commits at same version number.
- Corrected totals: Wayfinder ~290 active min, Osmani 198, Pocock 148, Superpowers 78; the three non-Superpowers runs 94-120M tokens and $91.53-$96.01.
- Verdict: for this test he'd choose Superpowers; keeps using Grill with Docs; "does not prove a universal winner".

### More videos found while resolving Pstack (not asked for, relevant)
- V4: "실제 Cursor 개발에 쓰이는 고품질 코딩 스킬, /Pstack 사용법", MINDUNG, 2026-10-15, 5:07, https://www.youtube.com/watch?v=gAt_rRweR7Q. No transcript -> claims UNVERIFIED beyond description. Description: pstack is Lauren Tan's skill bundle; lists how/why, architect/arena, no-comments, run-to-verify, interrogate, poteto-mode, swarm, overnight. Install block in description: Cursor `/add-plugin pstack` then `/setup-pstack` then `/poteto-mode <task>`; Claude Code (community port) `/plugin marketplace add michael-denyer/pstack-claude`, `/plugin install pstack@pstack-claude`, `/pstack:setup-pstack`; Codex community port line truncated. **Conflict:** description calls her a "SpaceX principal engineer"; pstack README says Meta/Netflix/Cursor/React core (P3 README:3). Trust README.
- V5: "One Command Runs My Whole Crew of AI Helpers", Ray Fernando, 2026-10-24, 7:34, https://www.youtube.com/watch?v=ed4EHIMxuqA. Transcript VERIFIED. Says pstack = Lauren's Cursor plugin; single entry `/poteto-mode`; run `/setup-pstack` first; "53 skills"; heavy token use, meant for hard tasks only; `/poteto-mode` fans out to subagents/models.
- No other video found that compares Pocock vs gstack vs Osmani. S1 second query produced only a Gemini synthesis citing written articles. **UNVERIFIED**: no video for the gstack variant.

## 3. What "Pstack" is

**Answer: pstack = `cursor/plugins` -> `pstack` by Lauren Tan (@poteto). It is not garrytan/gstack.** Confidence high.

Evidence:
1. V1's own description links pstack to `https://github.com/cursor/plugins/tree/main/pstack` (https://www.youtube.com/watch?v=sU9MW8Ycq2M).
2. Local README `LC/plugins/pstack/README.md:3,5-7`: "i'm poteto ... Meta, Netflix, and Cursor ... pstack is my answer". `LC/plugins/pstack/plugin.json:2-7`: name `pstack`, author "Lauren Tan", homepage `https://github.com/cursor/plugins/tree/main/pstack`.
3. Registered in Cursor marketplace: `LC/plugins/.cursor-plugin/marketplace.json:77-79` (`"name": "pstack", "source": "pstack"`).
4. V4 and V5 both name it pstack/Lauren Tan/poteto-mode on cursor/plugins.
5. A local project's `skills-lock.json` (L1) already records `unslop` from `cursor/plugins` at `harness/pstack/claude-code/skills/unslop/SKILL.md`.
6. gstack is a different project: https://github.com/garrytan/gstack, Garry Tan (YC CEO), "23 opinionated tools that serve as CEO, Designer, Eng Manager, Release Manager, Doc Engineer, and QA" (README intro); 137,884 stars at read time. Its slash commands are `/office-hours`, `/review`, `/qa`, `/ship` etc. Nothing links it to the video title.
7. Name-collision risk: S1 (second query) assumed gstack as the middle pack in a "Pocock vs gstack vs Osmani" comparison (UNVERIFIED secondary). Treat gstack as an optional fourth pack, not the video's "Pstack".

## 4. Pack profiles

### 4.1 mattpocock/skills (Pocock)
- Philosophy: small, composable skills "to do real engineering - not vibe coding"; reject process-owning frameworks (GSD, BMAD, Spec-Kit). `LC/skills/README.md:15-19`. Four failure modes -> fixes: alignment (grill), verbosity (shared language `CONTEXT.md`), broken code (tdd, diagnosing-bugs), ball of mud (to-spec, improve-codebase-architecture). README:84-178.
- Skills by the pack's own categories (README:188-231):
  - **Engineering, user-invoked**: ask-matt, grill-with-docs, triage, improve-codebase-architecture, setup-matt-pocock-skills, to-spec, to-tickets, implement, wayfinder.
  - **Engineering, model-invoked**: prototype, diagnosing-bugs, research, tdd, domain-modeling, codebase-design, code-review, resolving-merge-conflicts, wizard.
  - **Productivity, user-invoked**: grill-me, handoff, teach, to-questionnaire, wait-what.
  - **Productivity, model-invoked**: grilling, writing-for-agents.
  - Local clone also has `skills/in-progress/` (writing-shape, writing-fragments, writing-beats, setup-ts-deep-modules, retro, loop-me, implement-spec, claude-handoff), `skills/misc/` (setup-pre-commit, scaffold-exercises, migrate-to-shoehorn, git-guardrails-claude-code) and `skills/deprecated/` (glob of `LC/skills`); README does not list them. Not in plugin.json.
- Install (verbatim, `LC/skills/README.md:27-72`):
  - Rule: "Pick one: installing both leaves you with every skill twice." (README:27)
  - Claude Code plugin (README:34-44):
    ```bash
    claude plugins install mattpocock-skills
    ```
    ```
    /plugin install mattpocock-skills
    ```
    "It's in Claude Code's official marketplace, so there's nothing to add first, and updates arrive automatically."
  - Codex and other agents (README:51-55):
    ```bash
    npx skills@latest add mattpocock/skills
    ```
    "**The installer lets you choose which skills to take, so make sure `setup-matt-pocock-skills` is one of them.**"
  - Tinkerers / manual files (README:64-70): same `npx skills@latest add mattpocock/skills`; "pull my latest changes when you want them with `npx skills update`".
  - Then run `/setup-matt-pocock-skills` once per repo (README:74-80): asks issue tracker, triage labels, docs location.
  - Native Codex plugin: roadmap only (README:57, `.agents/adr/0002-ship-as-a-claude-code-plugin.md`).
- Manifests: `LC/skills/.claude-plugin/plugin.json` (name `mattpocock-skills`, version 1.2.3, skills list lines 21-47) and `LC/skills/.claude-plugin/marketplace.json` (marketplace name `mattpocock`, plugin `mattpocock-skills`, `source: "./"`, lines 2,10-11). A self-hosted `/plugin marketplace add mattpocock/skills` would follow from this but the README does **not** document it (UNVERIFIED).

### 4.2 addyosmani/agent-skills (Osmani)
- Philosophy: "Production-grade engineering skills for AI coding agents" encoding senior-engineer workflows, quality gates; lifecycle DEFINE -> PLAN -> BUILD -> VERIFY -> REVIEW -> SHIP with slash commands. `LC/agent-skills/README.md:3-18`. Each skill has steps, verification gates and anti-rationalization tables (README:226).
- 9 commands (README:24-36): `/spec /plan /build /test /constraints /review /webperf /code-simplify /ship`; `/build auto` runs the approved plan autonomously (README:40). In Claude Code use `/agent-skills:review` where built-in name clashes (README:38).
- 25 skills (README:224-286), by category:
  - Meta: using-agent-skills.
  - Define: interview-me, idea-refine, spec-driven-development, constraint-driven-development.
  - Plan: planning-and-task-breakdown.
  - Build: incremental-implementation, test-driven-development, context-engineering, source-driven-development, doubt-driven-development, frontend-ui-engineering, api-and-interface-design.
  - Verify: browser-testing-with-devtools, debugging-and-error-recovery.
  - Review: code-review-and-quality, code-simplification, security-and-hardening, performance-optimization.
  - Ship: git-workflow-and-versioning, ci-cd-and-automation, deprecation-and-migration, documentation-and-adrs, observability-and-instrumentation, shipping-and-launch.
  - Agent personas (README:290-299): code-reviewer, test-engineer, security-auditor, web-performance-auditor.
- Install (verbatim, `LC/agent-skills/README.md`):
  - Any agent, skills CLI (lines 50-53):
    ```bash
    npx skills add addyosmani/agent-skills            # install all 25 skills
    npx skills add addyosmani/agent-skills --list     # browse before installing
    ```
  - Single skills (lines 57-61):
    ```bash
    npx skills add addyosmani/agent-skills --skill code-review-and-quality   # five-axis review before merge
    npx skills add addyosmani/agent-skills --skill interview-me              # requirements interrogation, one question at a time
    npx skills add addyosmani/agent-skills --skill test-driven-development   # red-green-refactor, enforced
    ```
    Caveat (README:63-68): per-skill install copies only `skills/<name>/`, not repo-level `references/`; tracked in issue #361.
  - Claude Code marketplace (lines 77-80):
    ```
    /plugin marketplace add addyosmani/agent-skills
    /plugin install agent-skills@addy-agent-skills
    ```
    HTTPS fallback (lines 83-91): `/plugin marketplace add https://github.com/addyosmani/agent-skills.git`; `git config --global url."https://github.com/".insteadOf git@github.com:`.
  - Claude Code local/dev (lines 96-97): `git clone https://github.com/addyosmani/agent-skills.git` then `claude --plugin-dir /path/to/agent-skills`.
  - Codex (lines 184-185): `codex plugin marketplace add addyosmani/agent-skills` then `codex plugin add agent-skills@agent-skills`.
  - Gemini CLI (line 137): `gemini skills install https://github.com/addyosmani/agent-skills.git --path skills`.
  - Antigravity (line 117): `agy plugin install https://github.com/addyosmani/agent-skills.git`.
  - Command Code (lines 198-200): `cmd skills add addyosmani/agent-skills` (`--global`, `-s <skill>`).
  - Cursor: manual copy, "Put workflow skills under `.cursor/skills/` (sync from `agent-skills/skills/`)" (line 105; docs/cursor-setup.md). OpenCode: copy to `.opencode/skills/` (line 158). Copilot/Windsurf/Kiro: instruction-file or `.kiro/skills/` (lines 151,167,175).
- Manifests: `LC/agent-skills/.claude-plugin/marketplace.json` (marketplace `addy-agent-skills` line 3; plugin `agent-skills` v0.6.13, source github `addyosmani/agent-skills` lines 11-16) and `.claude-plugin/plugin.json` (`commands: ["./.claude/commands","./commands"]`, `skills: "./skills"`, lines 11-12). Codex manifest `.codex-plugin/plugin.json` is referenced at README:188 (not read).

### 4.3 pstack (cursor/plugins, Lauren Tan / poteto)
- Philosophy: "if you want to go fast, go deep first"; write less, higher-quality code; "fearless parallelism" via one rigorous agent per task; multi-model workflows. `LC/plugins/pstack/README.md:5-11`. Deliberately **no planning skills**: "i don't believe in planning. the best spec is code" (README:269-271; uses Cursor plan mode instead).
- Shape: one router `/poteto-mode` picks one of **23 playbooks** (investigation, bug fix, perf, hillclimb, runtime/trace forensics, feature, refactoring, prototype, visual parity, authoring a skill, eval, babysit, shipping, autonomous run, orchestrate, autopilot-full/stack, session pickup, pause safely, multi-phase plan, worktree cleanup, opening a pr) (README:53-94) and **24 principle skills** (README:223-257). Standalone skills (README:125-160): poteto-help, in-your-own-words, sharpen, how, why, recall, ketchup, ketchup-video, blast-radius, architect, arena, swarm, interrogate, automate-me, make-bot-ui, setup-pstack, reflect, correct, teach, tdd, benchmark-checklist, no-comments, typescript-best-practices, figure-it-out, show-me-your-work, create/maintain-verification-skill, create/maintain-formal-verification-skill, statechart, unslop, bro, technical-writing. Subagents: `poteto-agent`, `comment-sicko` (README:213-221). Not shipped: deslop/control-cli/control-ui live in `cursor-team-kit` (README:259-267). Ray Fernando counts "53 skills" (V5, transcript).
- Install (verbatim, `LC/plugins/pstack/README.md:15-30`):
  - Cursor:
    ```bash
    /add-plugin pstack
    ```
  - Claude Code:
    ```bash
    /plugin marketplace add cursor/plugins
    /plugin install pstack@cursor-plugins
    ```
    Auto-update off by default for third-party marketplaces; update manually with `claude plugin update pstack@cursor-plugins` (README:28). Commands get prefixed: `/pstack:poteto-mode` (README:30); `/pstack:setup-pstack` writes `~/.claude/rules/pstack-models.md`. Claude Code installs a generated copy from `harness/pstack/` (README:32).
  - First run (README:36-39): `/setup-pstack` then `/poteto-mode <task>`.
  - `npx skills`: **README documents no `npx skills` command.** Evidence that it works anyway: `skills-lock.json:70-75` has `unslop` sourced from `cursor/plugins` with `skillPath` `harness/pstack/claude-code/skills/unslop/SKILL.md`. So `npx skills add cursor/plugins --skill unslop` was evidently used (command form inferred; UNVERIFIED as official).
  - Manual copy: not documented in README. Community ports (V4 description): `michael-denyer/pstack-claude` for Claude Code. Third-party; UNVERIFIED.
- Manifests: `LC/plugins/pstack/plugin.json` (v0.15.34, lines 2-4); `LC/plugins/pstack/.cursor-plugin/plugin.json` (exists per glob; not read); `LC/plugins/.cursor-plugin/marketplace.json:77-79` (Cursor marketplace `cursor-plugins`, line 2 area); `LC/plugins/.claude-plugin/marketplace.json` (exists per glob; not read; this is what `/plugin marketplace add cursor/plugins` consumes); `LC/plugins/harness/pstack/claude-code/plugin.json` and a `.claude-plugin/plugin.json` under `harness/pstack` (listed by glob; exact path/contents UNVERIFIED).

### 4.4 garrytan/gstack (optional, not the video's Pstack)
- Philosophy: "turns Claude Code ... into a virtual engineering team" (CEO, eng manager, designer, reviewer, QA, security, release engineer); a sprint **Think -> Plan -> Build -> Review -> Test -> Ship -> Reflect**. https://github.com/garrytan/gstack (README intro + "The sprint").
- Skills (README sprint table): office-hours, plan-ceo-review, plan-eng-review, plan-design-review, plan-devex-review, design-consultation, review, deslop-shared-libs, test-audit, investigate, design-review, devex-review, design-shotgun, design-html, design-motion, qa, qa-only, pair-agent, cso, ship, land-and-deploy, canary, benchmark, ubicloud, eval-plan, document-release, document-generate, retro, browse, scrape, setup-browser-cookies, autoplan, spec, learn, make-pdf, diagram. Power tools: codex, claude-code, careful, freeze, guard, unfreeze, open-gstack-browser, setup-deploy, setup-gbrain, sync-gbrain, gstack-upgrade, captain, ios-qa/ios-fix/ios-design-review/ios-clean/ios-sync. Requires Bun (README "Requirements").
- Install (verbatim from README "Install"):
  - Claude Code, Step 1 (a prompt pasted into Claude Code): `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup`
  - Team mode: `(cd ~/.claude/skills/gstack && ./setup --team) && ~/.claude/skills/gstack/bin/gstack-team-init required && git add .claude/ CLAUDE.md && git commit -m "require gstack for AI-assisted work"`
  - Other agents: `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/gstack` then `cd ~/gstack && ./setup --host auto` (or `--host codex`, `cursor`, `opencode`, `factory`, `kiro`, `copilot`, `agy`); `./setup --status`.
  - Requirements (README:25): Claude Code, Git, Bun v1.4.2+ (setup refuses Bun older than 1.3.3), Node.js on Windows. Windows: `.\setup.ps1` (README:231).
  - **No Claude plugin marketplace route and no `npx skills` route.** The README install section documents only `git clone` + `./setup` (README:27-57). `https://raw.githubusercontent.com/garrytan/gstack/main/.claude-plugin/marketplace.json` returns 404. A plain skill copy would likely miss the compiled tools `./setup` builds (inference).
  - Troubleshooting: `~/.claude/skills/gstack/bin/gstack-doctor` (README:268).

### 4.5 obra/superpowers (compared in V3)
- Philosophy: "a complete software development methodology for your coding agents, built on top of a set of composable skills" (README:3). Flow: brainstorm a spec in short chunks, write an implementation plan, then *subagent-driven-development* with review per task; red/green TDD, YAGNI, DRY; skills trigger automatically (README:38-46). https://github.com/obra/superpowers
- Install (verbatim, README "Installation"):
  - Claude Code, official marketplace: `/plugin install superpowers@claude-plugins-official` (README:65).
  - Claude Code, Superpowers marketplace: `/plugin marketplace add obra/superpowers-marketplace` then `/plugin install superpowers@superpowers-marketplace` (README:75-81).
  - Cursor: `/add-plugin superpowers` in Agent chat (README:127). Gemini CLI: `gemini extensions install https://github.com/obra/superpowers` (README:165). Copilot CLI: `copilot plugin install superpowers@superpowers-marketplace` (README:185). Pi: `pi install git:github.com/obra/superpowers` (README:242). Antigravity: `agy plugin install https://github.com/obra/superpowers` (README:89).
  - Codex: in the Codex app, Plugins sidebar → Coding → Superpowers (README:98-101).
  - No documented `npx skills` route.
- Install separately for each harness you use (README:54).

## 5. `npx skills` CLI reference (vercel-labs/skills)

Primary: https://github.com/vercel-labs/skills (README), https://raw.githubusercontent.com/vercel-labs/skills/main/docs/commands.md (CLI reference), https://raw.githubusercontent.com/vercel-labs/skills/main/AGENTS.md, https://raw.githubusercontent.com/vercel-labs/skills/main/src/local-lock.ts. Requires Node.js 22.20+ (README). Supports OpenCode, Claude Code, Codex, Cursor and "75 more".

- **add** (docs/commands.md "skills add"): `npx skills add vercel-labs/agent-skills`. Sources: GitHub shorthand, full URL, `.../tree/main/skills/<skill>` path, GitLab, Azure Repos, any git URL, local path. Options table (verbatim flags):
  - `-g, --global` Install to user directory instead of project
  - `-a, --agent <agents...>` Target specific agents (e.g. `claude-code`, `codex`)
  - `-s, --skill <skills...>` Install specific skills by name (use `'*'` for all skills)
  - `-l, --list` List available skills without installing
  - `--copy` Copy files instead of symlinking to agent directories
  - `-y, --yes` Skip all confirmation prompts
  - `--all` Install all skills to all agents without prompts
  - Single skill from a multi-skill repo: `npx skills add vercel-labs/agent-skills --skill frontend-design --skill skill-creator`; README: `npx skills add vercel-labs/agent-skills --skill web-design-guidelines -a claude-code`. CI form: `npx skills add vercel-labs/agent-skills --skill frontend-design -g -a claude-code -y`. Names with spaces must be quoted.
- **Scope** (docs/commands.md "Installation Scope"): Project (default) -> `./<agent>/skills/`, committed with project; Global (`-g`) -> `~/<agent>/skills/`.
- **Method**: Symlink (recommended; canonical copy, single source of truth) vs Copy (`--copy`).
- **list**: `npx skills list`; `npx skills ls -g`; `npx skills ls -a claude-code -a cursor`.
- **find**: `npx skills find [query]`, `--owner <org>`.
- **check**: `npx skills check` (updates available, no reinstall).
- **update**: `npx skills update [skills...]`; `-g, --global`, `-p, --project`, `-y, --yes` (auto-detect: project if in project dir else global). Examples: `npx skills update my-skill`.
- **remove** (alias `rm`): `npx skills remove [skills...]`; options `-g, --global`, `-a, --agent`, `-s, --skill`, `-y, --yes`, `--all` (= `--skill '*' --agent '*' -y`). `npx skills remove owner/repo` removes all skills from an exact lock source.
- **use**: `npx skills use <source>@<skill> [--agent claude-code]` prints prompt or launches agent without installing.
- **init**: `npx skills init [name]` creates a SKILL.md template.
- **install (restore)**: `npx skills install` / `npx skills i` / `npx skills experimental_install` restore from `skills-lock.json` into `.agents/skills/`; `--frozen-lockfile` (default in CI) / `--no-frozen-lockfile` (AGENTS.md:22; docs/commands.md "Restore skills from the project lock file").
- **experimental_sync**: syncs npm-dependency skills; "Sync tracks its skills in `skills-lock.json`"; flags `--dry-run --copy --no-cleanup --no-remote --include --exclude -r/--recursive --frozen-lockfile --no-frozen-lockfile -a -y`.
- **How `skills-lock.json` is produced**: `src/local-lock.ts` defines the project lock: file `skills-lock.json` in cwd, `version: 1`, "meant to be checked into version control", skills sorted alphabetically, timestamp-free to reduce merge conflicts. Each entry: `source`, optional `sourceUrl`/`ref`, `sourceType`, `skillPath`, optional `version`/`via`, and `computedHash` = SHA-256 over all files in the skill folder (path + content, sorted; skips `.git`, `node_modules`). Written by `addSkillToLocalLock` / `removeSkillFromLocalLock`. This matches the L1 lock (version 1; entries with `source`, `sourceType`, `skillPath`, `computedHash`). Global installs (`-g`) use a separate lock `~/.agents/.skill-lock.json` v3 keyed on `skillFolderHash` = GitHub tree SHA (AGENTS.md:43,83,92). **UNVERIFIED:** that `skills add` (project scope) calls `addSkillToLocalLock` and `-g` writes the global lock - inferred from file names, AGENTS.md and the observed lock; the add.ts call sites were not read.
- Note: `skills update` / `check` use the global lock hash compare (AGENTS.md:83-88). Project-lock update behavior beyond that UNVERIFIED.

## 6. Overlap map

`-` = no dedicated skill. Pocock = `LC/skills/README.md`; Osmani = `LC/agent-skills/README.md`; pstack = `LC/plugins/pstack/README.md`; gstack = https://github.com/garrytan/gstack README. Video verdict only where a video said it (V2/V3); V1 verdicts UNVERIFIED.

| Job | pocock | osmani | pstack | gstack | video verdict |
|---|---|---|---|---|---|
| Grilling / requirements interview | `grill-me` (non-code), `grill-with-docs` (also builds `CONTEXT.md` + ADRs), `grilling` primitive (README:100-101,222,230); frontmatter `skills/engineering/grill-with-docs/SKILL.md:3` | `interview-me` (one question at a time to ~95% confidence; triggers on "grill me") `skills/interview-me/SKILL.md:3`; `idea-refine` | `in-your-own-words` (play back goal), `sharpen` (deepen a prompt), `poteto-help` (README:128-130); `/interrogate` is **code** review, not requirements (see review) | `/office-hours` (six forcing questions, writes design doc), `/plan-ceo-review` | V2: Pocock `grill-with-docs` is his daily driver; V3: grill asked ~30 questions, built more but results mixed (impl. flawed). Osmani `/spec` asked "basically the same questions" as grilling (V2) |
| Spec / PRD | `to-spec` (no interview, synthesizes conversation, publishes to tracker) | `spec-driven-development` + `/spec` (PRD), `constraint-driven-development` | none by design (README:269-271); `/poteto-mode` multi-phase-plan playbook | `/spec` (5 phases, files issue), `/autoplan` | V2: Pocock Wayfinder->to-spec->to-tickets 290 min vs Osmani spec/plan/build 108 min; similar cost |
| Planning / task breakdown | `to-tickets` (tracer-bullet tickets with blocking edges), `wayfinder` (map of decision tickets for work larger than a session) | `planning-and-task-breakdown` + `/plan`, `incremental-implementation` | multi-phase-plan, orchestrate playbooks; Cursor plan mode | `/plan-eng-review`, `/plan-ceo-review`, `/autoplan` | V2: Wayfinder only for large vague work; overkill for the test feature |
| Implementation orchestration | `implement` (drives `/tdd`, ends with `/code-review`), `implement-spec` (in-progress) | `/build`, `/build auto`, incremental-implementation | `/poteto-mode` (feature playbook), `swarm`, `arena`, autopilot playbooks | `/ship`, `captain` | V3: Pocock `implement` has `disable-model-invocation`, so delegated workers missed it |
| TDD | `tdd` (red-green-refactor, vertical slices; `skills/engineering/tdd/SKILL.md:3`) | `test-driven-development` (red-green-refactor, test pyramid 80/15/5; `skills/test-driven-development/SKILL.md:3`), `/test` | `tdd` = bug-fix regression test first, skips when no cheap test path; user-invoked only (`pstack/skills/tdd/SKILL.md:3-4`); principle `test-behavior-not-implementation` | no TDD skill; `/qa` writes failing regressions then fixes (README `/qa` row), `/test-audit` | V2: Osmani's test step was a no-op because build step already wrote tests |
| Debugging / root cause | `diagnosing-bugs` (feedback loop -> minimise -> hypothesise -> instrument -> fix -> regression test; `skills/engineering/diagnosing-bugs/SKILL.md:3`) | `debugging-and-error-recovery` (reproduce, localize, reduce, fix, guard; `skills/debugging-and-error-recovery/SKILL.md:3`), `browser-testing-with-devtools` | `/poteto-mode` bug-fix playbook (repro first, runtime evidence), `how`, `why`, runtime/trace forensics, principle `fix-root-causes` (README:70-75,132,249) | `/investigate` ("Iron Law: no fixes without investigation", stops after 3 failed fixes) | none in V2/V3. S1 (UNVERIFIED): pstack for hard-to-reproduce bugs |
| Code review | `code-review` (Standards + Spec axes in parallel sub-agents; `skills/engineering/code-review/SKILL.md:3`) | `code-review-and-quality` + `/review` (five-axis, severity labels; `skills/code-review-and-quality/SKILL.md:3`), persona `code-reviewer` | `interrogate` (one reviewer per configured model, synthesized verdict, no auto-apply; `pstack/skills/interrogate/SKILL.md:3-9`), `no-comments` | `/review` (auto-fixes obvious issues), `/codex`, `/claude-code` second opinions | V2: Osmani review phase was the biggest effort; 3 reject loops, caught data-loss/crash bug. Pocock side used external adversarial Codex review |
| Architecture / design | `improve-codebase-architecture` (HTML report of deepening candidates), `codebase-design`, `domain-modeling` | `api-and-interface-design`, `code-simplification` | `architect` (types/signatures before code; `pstack/skills/architect/SKILL.md:3`), principles `model-the-domain`, `foundational-thinking` | `/plan-eng-review`, `/design-consultation` | V2 praised Pocock `improve-codebase-architecture` |
| Adversarial / doubt | `grilling` | `doubt-driven-development` | `interrogate`, `arena`, `blast-radius` | `/codex`, `/cso` | V2 praised Osmani `doubt-driven-development` |
| Proving it runs (verification) | `/tdd` gates only | `/test`, `browser-testing-with-devtools`, `shipping-and-launch` | principle `prove-it-works`, `create-verification-skill` | `/qa`, `/browse`, `/canary` | V2/V3: neither Pocock nor Osmani caught a dead/missing UI path; manual app verification still required. V3: Superpowers showed no UI defect |
| Simplify / slop removal | `writing-for-agents` (docs) | `code-simplification`, `/code-simplify` | `unslop`, `no-comments`, principle `laziness-protocol` | `/deslop-shared-libs` advisory simplification lens in `/review` | - |
| Security | - | `security-and-hardening`, persona `security-auditor` | - | `/cso` | V2 praised Osmani security-and-hardening |
| Docs / ADRs | `domain-modeling`, `grill-with-docs` write `CONTEXT.md` + ADRs | `documentation-and-adrs` | `technical-writing` | `/document-release`, `/document-generate` | - |
| Prototyping | `prototype` | `idea-refine` | playbook `prototype`, principle `exhaust-the-design-space` | `/design-shotgun` | - |
| Handoff / ship | `handoff`, `triage` | `/ship`, `shipping-and-launch`, `ci-cd-and-automation` | playbooks `shipping`, `opening-a-pr`, `babysit` | `/ship`, `/land-and-deploy` | V2: Osmani `/ship` ran 3 subagents and fixed findings |

## 7. Open / unverified items

1. **V1 content unverified**: no transcript; only description. The per-job verdict of the "Pocock vs Pstack vs Osmani" video (the one the task is named after) is not known. Action: obtain transcript manually (yt-dlp/auto-captions) or watch chapters 01:00-12:54.
2. **V1 chapters** beyond 00:45 truncated by the page reader.
3. **S1 web_search output is Gemini-synthesized, secondary.** Pages claudeskills.xyz/compare/matt-pocock-vs-addy-osmani, skills.addy.ie/compare/, flaviocopes.com/pstack/, mindstudio.ai pstack post, skilldev.pro pstack page, medium.com/@martin.jordanovski/... were not opened. Its "choose X if" guidance is not validated here.
4. **No video found for Pocock vs gstack vs Osmani.**
5. pstack `npx skills add cursor/plugins --skill <name>` is only inferred from `skills-lock.json:70-75`; no README source. Whether `npx skills add cursor/plugins` exposes the Cursor-format `pstack/skills/*` or only the generated `harness/pstack/claude-code/skills/*` copy is unverified.
6. pstack local files not read: `plugins/.claude-plugin/marketplace.json`, `pstack/.cursor-plugin/plugin.json`, `harness/pstack/claude-code/plugin.json` (+ `.claude-plugin/plugin.json`), `pstack/docs/guide`, `docs/harness/claude-code.md`.
7. Pocock README claims presence in Claude Code's "official marketplace"; not verified against Anthropic's marketplace. Self-hosted marketplace `/plugin marketplace add mattpocock/skills` not documented.
8. gstack: `docs/skills.md` and `docs/install.md` not read. The README documents no plugin marketplace or `npx skills` path (marketplace.json 404).
9. `skills add` -> lock-file write call sites (add.ts) not read; global-vs-project lock behavior inferred (section 5).
10. Osmani README lines 300-410 (not install-relevant) and `.codex-plugin/plugin.json` not read.
11. Pocock local clone and plugin.json version (1.2.3) may differ from what V3 tested (V3 notes 32 new commits without a version bump). Skill names in V2/V3 (wayfinder, to-spec, to-tickets, implement, grill-with-docs) do exist in the local clone (`LC/skills/skills/engineering/*`).
12. Star/line counts and versions are point-in-time (read 2026-10-27): gstack 137,884 stars; vercel-labs/skills 36,786 stars; Osmani 0.6.13; pstack 0.15.34; Pocock 1.2.3.