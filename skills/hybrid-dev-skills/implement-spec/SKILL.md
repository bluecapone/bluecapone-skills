---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets: one pstack /poteto-mode implementer per ticket, all ready tickets in parallel, then /pstack:interrogate on the integration branch."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-pocock-skills`.

The goal is the entire spec implemented on a single **integration branch**, with every ticket resolved the way the issue tracker closes work.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Start every subagent with a fresh context window.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

## Steps

1. Read the spec and tickets to understand the task graph. Resolve `<pstack>`, the pstack plugin folder:

   ```bash
   claude plugin list --json | jq -r --arg pwd "$PWD" '[.[] | select(.id=="pstack@cursor-plugins")] | map(select(.projectPath==$pwd)) + (sort_by(.version | split(".") | map(tonumber? // 0)) | reverse) | .[0].installPath // empty'
   ```

   If that prints nothing, stop and tell the user to run `hybrid-dev-setup`'s `scripts/install.sh`. Read `<pstack>/docs/harness/claude-code.md` once.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Create the integration branch. If the issue tracker closes work through PRs, or the user asks for one, open a draft PR after the first merge in step 5 (a branch with no commits ahead of main can't open one), marked as closing the spec and tickets.

4. For **every ticket on the frontier**, start an **implementer subagent** in the same message, so they all run in parallel. Use `subagent_type: "general-purpose"`, `model: "opus"`, `effort: "medium"` and `isolation: "worktree"` (its own worktree on its own branch). Subagents get no Agent tool, so each implementer runs poteto-mode inline. Every implementer prompt is exactly this kickoff, with the placeholders filled in:

   ```text
   Read <pstack>/skills/poteto-mode/worker.md before anything else.
   Then read <pstack>/skills/poteto-mode/SKILL.md in full and run it on <ticket ref>, as if the operator typed /pstack:poteto-mode <ticket ref>. Spec: <spec ref>. Notes: <exploration notes dir, if any>.
   Overrides (explicit, per worker.md):
   - Confirm your worktree is based on the integration branch <branch>; reset onto it if not.
   - Do not open a PR. Merge the integration branch tip into your branch, then report done.
   - The bar is the ticket's acceptance criteria plus a passing test suite. A spec-level /pstack:interrogate follows; add no review round of your own.
   - You cannot start agents. Do poteto-mode's delegate, swarm and arena work yourself, inline, and say so.
   ```

5. Once an **implementer subagent** completes, merge its work to the integration branch with a **merger subagent**.

6. If this changes the **frontier** of available tickets, start implementers for **all** newly ready tickets at once, with the same kickoff. This allows for maximum concurrency.

7. Once all tickets are complete, read `<pstack>/skills/interrogate/SKILL.md` and run it on the integration branch diff against its base. Fix every finding in a single fresh **implementer subagent**, using the same kickoff with "the interrogate findings" in place of the ticket.

8. If a draft PR exists, mark it ready for review. Otherwise, resolve each ticket the way the issue tracker closes work, and report the integration branch.

9. Clean up all **implementer subagent** worktrees.
