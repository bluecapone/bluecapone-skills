#!/usr/bin/env bash
# merge-results.sh — merge agy + Firecrawl search outputs, dedupe by canonical URL, tag provenance.
#
# Usage: merge-results.sh <agy.json> <firecrawl.json>
#
# Reads two JSON files:
#   - agy: assumed to be a JSON array of {title, url, snippet, date_published}
#   - Firecrawl: assumed to be {data: {web: [{title, url, description, date}]}}
#
# Emits a markdown-formatted ranked list to stdout. Items found in both sources are
# tagged "[via both]" and surfaced first.

set -euo pipefail

AGY_FILE="${1:?usage: merge-results.sh <agy.json> <firecrawl.json>}"
FIRECRAWL_FILE="${2:?usage: merge-results.sh <agy.json> <firecrawl.json>}"

# Normalize URL: lowercase host, strip trailing slash, drop common tracking params.
normalize_url() {
  python3 -c '
import sys, urllib.parse as up
u = sys.argv[1]
p = up.urlparse(u)
host = p.netloc.lower()
path = p.path.rstrip("/")
query = "&".join(
    s for s in p.query.split("&")
    if s and not s.split("=",1)[0].lower().startswith(("utm_","fbclid","gclid","mc_eid","mc_cid","ref_"))
)
clean = up.urlunparse((p.scheme, host, path, p.params, query, ""))
print(clean)
' "$1"
}

# Build a JSON merge map: { canonical_url: { sources: [g|f|both], title, url, snippet, date } }
merge_json() {
  python3 - <<'PYEOF' "$AGY_FILE" "$FIRECRAWL_FILE"
import sys, json, urllib.parse as up

def normalize(u):
    p = up.urlparse(u or "")
    host = p.netloc.lower()
    path = p.path.rstrip("/")
    query = "&".join(
        s for s in p.query.split("&")
        if s and not s.split("=",1)[0].lower().startswith(("utm_","fbclid","gclid","mc_eid","mc_cid","ref_"))
    )
    return up.urlunparse((p.scheme, host, path, p.params, query, ""))

def safe_load(path):
    try:
        with open(path) as f:
            return json.load(f)
    except Exception:
        return None

agy = safe_load(sys.argv[1])
firecrawl = safe_load(sys.argv[2])

results = {}

# agy path: expect a top-level array or {results: [...]} or {response: ...}
def iter_agy(data):
    if data is None: return
    if isinstance(data, list):
        yield from data; return
    if isinstance(data, dict):
        for key in ("results", "data", "items", "response"):
            v = data.get(key)
            if isinstance(v, list):
                yield from v; return
        # Last resort: try to find an array anywhere
        for v in data.values():
            if isinstance(v, list) and v and isinstance(v[0], dict) and "url" in v[0]:
                yield from v; return

for item in iter_agy(agy):
    url = item.get("url") or item.get("link")
    if not url: continue
    canon = normalize(url)
    results.setdefault(canon, {
        "title": item.get("title", ""),
        "url": url,
        "snippet": item.get("snippet") or item.get("description") or "",
        "date": item.get("date_published") or item.get("date") or "",
        "sources": set(),
    })["sources"].add("agy")

# Firecrawl path: {data: {web: [...]}}
fc_list = []
if isinstance(firecrawl, dict):
    fc_list = firecrawl.get("data", {}).get("web") or firecrawl.get("data") or []
    if isinstance(fc_list, dict):
        fc_list = fc_list.get("web", [])

for item in fc_list or []:
    if not isinstance(item, dict): continue
    url = item.get("url")
    if not url: continue
    canon = normalize(url)
    if canon in results:
        results[canon]["sources"].add("firecrawl")
        # Prefer Firecrawl's description if agy's snippet was empty
        if not results[canon]["snippet"]:
            results[canon]["snippet"] = item.get("description", "") or ""
    else:
        results[canon] = {
            "title": item.get("title", ""),
            "url": url,
            "snippet": item.get("description", "") or "",
            "date": item.get("date", "") or "",
            "sources": {"firecrawl"},
        }

# Rank: both > agy > firecrawl. Preserve insertion order within each tier.
def tier(srcs):
    if srcs == {"agy", "firecrawl"}: return 0
    if "agy" in srcs: return 1
    return 2

def tag(srcs):
    if srcs == {"agy", "firecrawl"}: return "[via both]"
    if "agy" in srcs: return "[via agy]"
    return "[via Firecrawl]"

ranked = sorted(results.values(), key=lambda r: tier(r["sources"]))

print(f"**Web search results** — {len(ranked)} unique URLs after dedup\n")
for i, r in enumerate(ranked, 1):
    domain = up.urlparse(r["url"]).netloc
    snippet = (r["snippet"] or "").replace("\n", " ").strip()[:200]
    date = f" — {r['date']}" if r["date"] else ""
    print(f"{i}. **{tag(r['sources'])}** [{r['title'] or domain}]({r['url']}) — {domain}{date}")
    if snippet:
        print(f"   {snippet}")
    print()
PYEOF
}

merge_json
