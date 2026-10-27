#!/usr/bin/env python3
"""Build references/catalog.md: every publicly installable SKILL.md under a root.

A skill is kept only when it resolves to a public GitHub source, either through a
skills-lock.json entry or because it lives in a public clone (9_Github/* or
bluecapone-skills). Everything else is dropped, which keeps private and work
skills out of the committed catalog. Each `npx skills` install command is then
checked against `npx skills add <source> --list`, so stale or broken entries drop.
"""
import argparse
import datetime
import json
import os
import re
import shlex
import subprocess
import sys
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

PRUNE = {"node_modules", ".git", ".venv", "venv", "dist", "build", "__pycache__", ".worktrees"}
SKIP_COMPONENTS = {"test", "tests", "fixtures", "vendor"}
PUBLIC_CLONE_PREFIX = "9_Github"
PUBLIC_SELF = "5_Personal/bluecapone-skills"
SELF_SOURCE = "bluecapone/bluecapone-skills"

PACK_LABELS = {
    "mattpocock/skills": "Matt Pocock",
    "addyosmani/agent-skills": "Addy Osmani",
    "garrytan/gstack": "gstack (Garry Tan)",
    "obra/superpowers": "superpowers (obra)",
    "bluecapone/bluecapone-skills": "bluecapone",
}

# Pack-level install commands that replace the per-skill `npx skills add` form.
INSTALL_OVERRIDES = {
    "garrytan/gstack": "git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup",
    "obra/superpowers": "/plugin install superpowers@claude-plugins-official",
}

CATEGORY_RULES = [
    ("Principles", r"^principle-"),
    ("Security", r"secur|threat|vuln|harden|secret|keychain|ssh-key|\bcso\b|pentest"),
    ("Slides & diagrams", r"slide|deck|present|excalidraw|diagram|mermaid|chart"),
    ("Research & web", r"research|firecrawl|scrap|crawl|web search|osint|last30days|notebooklm"),
    ("Planning & requirements", r"grill|interview|\bspec\b|spec-|requirement|plan|ticket|wayfinder|idea|brainstorm|questionnaire|office-hours|\bprd\b"),
    ("Debugging", r"debug|diagnos|\bbug|root cause|reproduce|investigat"),
    ("Testing & verification", r"tdd|test|verif|\bqa\b|smoke|benchmark|prove"),
    ("Code review & quality", r"review|quality|slop|simplif|lint|comment|refactor"),
    ("Architecture & design", r"architect|domain|design|interface|codebase|deep-module|statechart|type-system|typescript"),
    ("Git, PR & CI", r"\bgit\b|git-|commit|pull request|\bpr\b|merge|branch|\bci\b|ci-|ship|release|deploy|launch"),
    ("Docs & writing", r"\bdoc|writ|\badr|readme|glossary|humaniz|prose|explain|teach|learn"),
    ("Agent workflow & meta", r"skill|agent|context|handoff|caveman|cave|ponytail|poteto|loop|mode|token|prompt|orchestr|swarm|setup|plugin|memory|recall|reflect"),
    ("Integrations & tools", r"google|slack|tailscale|\bx-|\bapi\b|\bcli\b|sdk|mcp|voice|app\b"),
]
CATEGORY_ORDER = [c for c, _ in CATEGORY_RULES] + ["Other"]

# "<source>:<name>" -> category, for rows the regex rules misfile.
CATEGORY_OVERRIDES: dict[str, str] = {
    "mattpocock/skills:wizard": "Agent workflow & meta",
    "cursor/plugins:thermos": "Code review & quality",
    "cursor/plugins:interrogate": "Code review & quality",
    "addyosmani/agent-skills:doubt-driven-development": "Code review & quality",
    "addyosmani/agent-skills:performance-optimization": "Debugging",
    "addyosmani/agent-skills:frontend-ui-engineering": "Architecture & design",
    "addyosmani/agent-skills:source-driven-development": "Research & web",
    "mattpocock/skills:improve-codebase-architecture": "Architecture & design",
    "mattpocock/skills:scaffold-exercises": "Docs & writing",
    "cursor/plugins:build-figma": "Architecture & design",
    "cursor/plugins:statechart": "Architecture & design",
    "cursor/plugins:cli-for-agents": "Architecture & design",
    "cursor/plugins:figure-it-out": "Planning & requirements",
    "cursor/plugins:show-me-your-work": "Agent workflow & meta",
    "cursor/plugins:weekly-review": "Git, PR & CI",
    "cursor/plugins:control-ui": "Testing & verification",
    "cursor/plugins:check-compiler-errors": "Testing & verification",
    "cursor/plugins:arena": "Agent workflow & meta",
    "cursor/plugins:continual-learning": "Agent workflow & meta",
    "cursor/plugins:sharpen": "Agent workflow & meta",
    "cursor/plugins:workflow-from-chats": "Agent workflow & meta",
    "cursor/plugins:google-docs": "Integrations & tools",
    "cursor/plugins:X MCP guide": "Integrations & tools",
    "cursor/plugins:add-dictation": "Integrations & tools",
    "cursor/plugins:add-read-aloud": "Integrations & tools",
    "cursor/plugins:tailscale-setup": "Integrations & tools",
    "garrytan/gstack:make-pdf": "Docs & writing",
    "garrytan/gstack:gstack-upgrade": "Agent workflow & meta",
    "garrytan/gstack:captain": "Agent workflow & meta",
    "garrytan/gstack:learn": "Agent workflow & meta",
    "obra/superpowers:writing-skills": "Agent workflow & meta",
    "JuliusBrussee/caveman:caveman-learn": "Agent workflow & meta",
    "JuliusBrussee/caveman:migration": "Architecture & design",
    "bluecapone/bluecapone-skills:super-productivity": "Integrations & tools",
    "herdrdev/herdr:herdr": "Integrations & tools",
    "herdrdev/herdr:herdr-throwaway-repro": "Integrations & tools",
    "herdrdev/herdr:triage": "Planning & requirements",
}

GITHUB_RE = re.compile(r"^(?:https://github\.com/|git@github\.com:)([^/\s]+)/([^/\s]+?)(?:\.git)?/?$")


def warn(msg):
    print(f"warning: {msg}", file=sys.stderr)


def parse_frontmatter(text):
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    fields, i = {}, 1
    while i < len(lines) and lines[i].strip() != "---":
        m = re.match(r"^([A-Za-z_][\w-]*):\s*(.*)$", lines[i])
        i += 1
        if not m:
            continue
        key, value = m.group(1), m.group(2).strip()
        if value in ("", ">", "|", ">-", "|-", ">+", "|+"):
            parts = []
            while i < len(lines) and lines[i].strip() != "---" and (lines[i][:1].isspace() or not lines[i].strip()):
                if lines[i].strip():
                    parts.append(lines[i].strip())
                i += 1
            value = " ".join(parts)
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
            value = value[1:-1]
        fields[key] = value
    return fields


def first_body_line(text):
    """First prose line after the frontmatter: no heading, list, table, quote, fence or HTML."""
    lines = text.splitlines()
    start = 0
    if lines and lines[0].strip() == "---":
        start = next((i + 1 for i in range(1, len(lines)) if lines[i].strip() == "---"), 0)
    in_fence = False
    for line in lines[start:]:
        s = line.strip()
        if s.startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence or not s or s[0] in "#|><-*" or re.match(r"^\d+\.", s):
            continue
        return re.sub(r"\*\*|__|`", "", s)
    return ""


def walk_skills(root):
    for dirpath, dirnames, filenames in os.walk(root, followlinks=False):
        dirnames[:] = [d for d in dirnames if d not in PRUNE]
        if "SKILL.md" not in filenames:
            continue
        path = Path(dirpath) / "SKILL.md"
        if SKIP_COMPONENTS & set(path.relative_to(root).parts):
            continue
        yield path


_lock_cache = {}


def load_lock(path):
    if path not in _lock_cache:
        data = None
        if path.is_file():
            try:
                data = json.loads(path.read_text(encoding="utf-8")).get("skills") or {}
            except (json.JSONDecodeError, OSError, AttributeError) as e:
                warn(f"bad lock file {path}: {e}")
        _lock_cache[path] = data
    return _lock_cache[path]


def lock_lookup(skill_dir, name, root):
    d = skill_dir
    while d != root and root in d.parents:
        for lock in (d / "skills-lock.json", d / ".agents" / "skills-lock.json"):
            skills = load_lock(lock)
            entry = skills.get(name) if skills else None
            if isinstance(entry, dict) and entry.get("sourceType") == "github" and entry.get("source"):
                return entry["source"], entry.get("skillPath", "")
        d = d.parent
    return None


def enclosing_repo(path, root):
    d = path.parent
    while d != root and root in d.parents:
        if (d / ".git").exists():
            return d
        d = d.parent
    return None


_origin_cache = {}


def public_clone_source(repo, root):
    rel = repo.relative_to(root).as_posix()
    if not (rel.startswith(PUBLIC_CLONE_PREFIX + "/") or rel == PUBLIC_SELF):
        return None
    if repo not in _origin_cache:
        r = subprocess.run(["git", "-C", str(repo), "remote", "get-url", "origin"], capture_output=True, text=True)
        m = GITHUB_RE.match(r.stdout.strip()) if r.returncode == 0 else None
        _origin_cache[repo] = f"{m.group(1)}/{m.group(2)}" if m else None
    return _origin_cache[repo]


_public_cache = {}


def is_public(source):
    if source not in _public_cache:
        req = urllib.request.Request(f"https://github.com/{source}", method="HEAD")
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                _public_cache[source] = resp.status == 200
        except urllib.error.HTTPError:
            _public_cache[source] = False
        except (urllib.error.URLError, TimeoutError, OSError):
            print("error: network required to verify sources are public", file=sys.stderr)
            sys.exit(2)
    return _public_cache[source]


ANSI_RE = re.compile(r"\x1b\[[0-9;]*m")
LIST_NAME_RE = re.compile(r"^│ {4}(\S.*?)\s*$")


def npx_listing(source):
    """Skill names the installer finds in source: (default discovery, --full-depth)."""
    found = []
    for extra in ([], ["--full-depth"]):
        try:
            r = subprocess.run(["npx", "-y", "skills", "add", source, "--list", *extra],
                               capture_output=True, text=True, timeout=300)
        except (FileNotFoundError, subprocess.TimeoutExpired) as e:
            print(f"error: npx skills add {source} --list failed: {e}", file=sys.stderr)
            sys.exit(2)
        if r.returncode != 0:
            print(f"error: npx skills add {source} --list exited {r.returncode}", file=sys.stderr)
            sys.exit(2)
        lines = ANSI_RE.sub("", r.stdout + r.stderr).splitlines()
        found.append({m.group(1) for m in map(LIST_NAME_RE.match, lines) if m})
    return source, found[0], found[1]


def pack_label(source, rel_parts):
    if source == "cursor/plugins":
        parts = [p for p in rel_parts if p]
        plugin = parts[1] if parts and parts[0] in ("harness", "third_party") and len(parts) > 1 else (parts[0] if parts else "?")
        return f"cursor/plugins: {plugin}"
    return PACK_LABELS.get(source, source)


def categorize(source, name, description):
    category = None
    for text in (name, description.lower()):
        for cat, rx in CATEGORY_RULES:
            if cat == "Principles" and text is not name:
                continue
            if re.search(rx, text):
                category = cat
                break
        if category:
            break
    return CATEGORY_OVERRIDES.get(f"{source}:{name}", category or "Other")


def cell(text, limit=None):
    text = " ".join(text.split())
    if limit and len(text) > limit:
        text = text[: limit - 1].rstrip() + "…"
    return text.replace("|", "\\|")


def main():
    here = Path(__file__).resolve().parent.parent
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--root", default=os.environ.get("SKILLS_ROOT"),
                    help="directory holding your skill repo clones (default: $SKILLS_ROOT)")
    ap.add_argument("--out", default=str(here / "references" / "catalog.md"))
    args = ap.parse_args()
    if not args.root:
        ap.error("--root is required (or set SKILLS_ROOT)")
    root = Path(args.root).resolve()
    if not root.is_dir():
        sys.exit(f"error: root {root} does not exist")

    candidates = {}  # (source, name) -> list of (rank tuple, entry)
    dropped = 0
    for path in walk_skills(root):
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as e:
            warn(f"cannot read {path}: {e}")
            dropped += 1
            continue
        fm = parse_frontmatter(text)
        name = fm.get("name") or path.parent.name
        description = fm.get("description", "")
        if not re.search(r"[A-Za-z0-9]", description):
            # Placeholder descriptions (e.g. a literal ">") are unsearchable; use the body's first prose line.
            description = first_body_line(text)

        source, via_clone, rel_parts = None, False, ()
        repo = enclosing_repo(path, root)
        hit = lock_lookup(path.parent, name, root)
        clone_source = None if hit else (public_clone_source(repo, root) if repo else None)
        if hit:
            source = hit[0]
            rel_parts = tuple(Path(hit[1]).parent.parts)
        elif clone_source:
            source, via_clone = clone_source, True
            rel_parts = path.parent.relative_to(repo).parts
        if not source:
            dropped += 1
            continue
        hidden = any(p.startswith(".") for p in (path.parent.relative_to(repo).parts if repo else path.parts))
        rank = (0 if via_clone else 1, 1 if hidden else 0, len(str(path)))
        entry = {"source": source, "name": name, "description": description, "rel_parts": rel_parts}
        candidates.setdefault((source, name), []).append((rank, entry))

    public = {}
    for (source, name), cands in candidates.items():
        if source not in public:
            public[source] = is_public(source)
            if not public[source]:
                warn(f"skipped non-public source {source}")
        if not public[source]:
            dropped += len(cands)

    # Ask the installer itself which skills each npx source exposes, so every
    # printed command works. The repo this script ships in is trusted as-is:
    # its unpushed skills are not on GitHub yet.
    npx_sources = sorted(s for s, ok in public.items() if ok and s not in INSTALL_OVERRIDES and s != SELF_SOURCE)
    with ThreadPoolExecutor(8) as pool:
        listings = {s: (shallow, deep) for s, shallow, deep in pool.map(npx_listing, npx_sources)}

    rows = []
    for (source, name), cands in candidates.items():
        if not public[source]:
            continue
        entry = min(cands, key=lambda c: c[0])[1]
        install = INSTALL_OVERRIDES.get(source, f"npx skills add {source} -s {shlex.quote(name)}")
        if source in listings:
            shallow, deep = listings[source]
            if name in deep and name not in shallow:
                install += " --full-depth"
            elif name not in shallow:
                warn(f"skipped {source}:{name}: npx skills add {source} --list does not offer it")
                dropped += len(cands)
                continue
        rows.append({
            **entry,
            "pack": pack_label(source, entry["rel_parts"]),
            "install": install,
            "category": categorize(source, name, entry["description"]),
        })

    seen = {f"{r['source']}:{r['name']}" for r in rows}
    for key in CATEGORY_OVERRIDES.keys() - seen:
        warn(f"CATEGORY_OVERRIDES key matches no skill: {key}")

    sources = {r["source"] for r in rows}
    out = [
        "# Skill catalog",
        "",
        f"Generated by scripts/build-catalog.py on {datetime.date.today().isoformat()} from {len(rows)} skills "
        f"in {len(sources)} public sources. Do not edit by hand; rerun the script.",
    ]
    for cat in CATEGORY_ORDER:
        cat_rows = sorted((r for r in rows if r["category"] == cat), key=lambda r: (r["name"], r["pack"]))
        if not cat_rows:
            continue
        out += ["", f"## {cat}", "", "| Skill | Pack | What it does | Install |", "|---|---|---|---|"]
        for r in cat_rows:
            out.append(f"| {cell(r['name'])} | {cell(r['pack'])} | {cell(r['description'], 160)} | `{cell(r['install'])}` |")
    out_path = Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"wrote {out_path}: {len(rows)} skills, {len(sources)} sources, {dropped} dropped (private/unresolved)")


if __name__ == "__main__":
    main()
