#!/bin/bash
# Verify every invariant the pebbl-memory pipeline depends on. READ-ONLY: it
# reports, it never repairs — auto-fixing from a wrong diagnosis is how you turn
# a small break into a big one.
#
# Exit 0 = all invariants hold. Exit 1 = at least one FAIL.
#
# It deliberately does NOT beat the liveness heartbeat. A heartbeat must mean
# "the scheduled job completed", so only commit-memory.sh may beat it; if running
# this by hand could beat, a human checking on things would mask a dead
# scheduler, which is the exact failure we are trying to detect.
#
# --json prints one object per finding for a machine caller (loom's doctor).
set -uo pipefail

REPO="/Users/ashley/dev-tools"
LIVE="$REPO/pebbl-history/live"
STORE_LINK="/Users/ashley/pebbl/.pebbl"
LABEL="com.ashley.dev-tools-memory"
SKILLS="activity-check anti-ai-prose design-spike flare-strategy loom-refine loom-work research-planner skill-builder"
# A push that has not landed for this long means pushes are failing quietly.
UNPUSHED_MAX=3
# events.jsonl dirty for this long means the committer is stuck (see failure 2).
UNCOMMITTED_MAX_H=36

JSON=0
[ "${1:-}" = "--json" ] && JSON=1

fails=0
findings=()

ok()   { findings+=("PASS|$1|$2"); }
fail() { findings+=("FAIL|$1|$2"); fails=$((fails + 1)); }

# ── 1. the store symlink ─────────────────────────────────────────────────────
# The nastiest failure: if this is a real directory instead of a symlink, pebbl
# is writing memory that never reaches the repo, and nothing looks wrong.
if [ -L "$STORE_LINK" ]; then
  target=$(readlink "$STORE_LINK")
  if [ "$target" = "$LIVE" ]; then
    if [ -f "$LIVE/events.jsonl" ]; then
      ok store-symlink "~/pebbl/.pebbl -> $LIVE"
    else
      fail store-symlink "symlink resolves but $LIVE/events.jsonl is missing"
    fi
  else
    fail store-symlink "points at $target, expected $LIVE"
  fi
elif [ -d "$STORE_LINK" ]; then
  fail store-symlink "IS A REAL DIRECTORY — pebbl memory is being written outside the repo and is unversioned"
else
  fail store-symlink "missing entirely — pebbl has no store at ~/pebbl"
fi

# ── 2. repo location (TCC) ───────────────────────────────────────────────────
# launchd gets zero access to ~/Documents, so a repo moved back there kills the
# scheduled job silently.
case "$REPO" in
  "$HOME"/Documents/*|"$HOME"/Desktop/*|"$HOME"/Downloads/*)
    fail repo-location "inside a macOS TCC-protected folder — launchd cannot read it" ;;
  *) ok repo-location "$REPO is outside the TCC-protected folders" ;;
esac

# ── 3. the scheduled job is loaded ───────────────────────────────────────────
if launchctl list 2>/dev/null | grep -q "$LABEL"; then
  ok launchd "$LABEL is loaded"
else
  fail launchd "$LABEL is NOT loaded — nothing will commit memory"
fi

# ── 4. skill + statusline symlinks ───────────────────────────────────────────
broken=""
for n in $SKILLS; do
  p="$HOME/.claude/skills/$n"
  { [ -L "$p" ] && [ -f "$p/SKILL.md" ]; } || broken="$broken $n"
done
[ -L "$HOME/.claude/statusline.sh" ] && [ -f "$HOME/.claude/statusline.sh" ] \
  || broken="$broken statusline.sh"
if [ -z "$broken" ]; then
  ok symlinks "8 skills + statusline resolve into the repo"
else
  fail symlinks "broken or no longer symlinked:$broken"
fi

# ── 5. only canonical files tracked for the live store ───────────────────────
# events.jsonl is canonical; db.sqlite / view.sqlite / the .md projections are
# derived. If one gets tracked, the gitignore regressed and we are back to
# binary churn and two sources of truth.
derived=$(git -C "$REPO" ls-files pebbl-history/live \
  | grep -Ev '^pebbl-history/live/(events\.jsonl|rubric\.yml|config\.yml)$' || true)
if [ -z "$derived" ]; then
  ok tracked-set "live store tracks only events.jsonl + rubric + config"
else
  fail tracked-set "derived files are tracked: $(echo "$derived" | tr '\n' ' ')"
fi

# ── 6. push auth (catches an expired PAT) ────────────────────────────────────
# --dry-run exercises write authorization without moving anything.
if ! git -C "$REPO" remote get-url origin >/dev/null 2>&1; then
  fail push-auth "no origin remote configured"
elif git -C "$REPO" push --dry-run origin HEAD >/dev/null 2>&1; then
  ok push-auth "origin accepts a write (PAT valid)"
else
  fail push-auth "origin REFUSED a dry-run push — PAT expired or lost repo access"
fi

# ── 7. unpushed drift ────────────────────────────────────────────────────────
if git -C "$REPO" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
  ahead=$(git -C "$REPO" rev-list --count '@{upstream}..HEAD' 2>/dev/null || echo 0)
  if [ "$ahead" -le "$UNPUSHED_MAX" ]; then
    ok unpushed "$ahead commit(s) ahead of origin"
  else
    fail unpushed "$ahead commits unpushed (>$UNPUSHED_MAX) — pushes are failing quietly"
  fi
else
  fail unpushed "no upstream set for the current branch"
fi

# ── 8. uncommitted memory is not stuck ───────────────────────────────────────
# commit-memory.sh skips while anything outside pebbl-history is dirty. That is
# the right call for one run and a trap if it lasts, so age the dirt.
if [ -n "$(git -C "$REPO" status --porcelain -- pebbl-history 2>/dev/null)" ]; then
  mtime=$(stat -f %m "$LIVE/events.jsonl" 2>/dev/null || echo 0)
  age_h=$(( ( $(date +%s) - mtime ) / 3600 ))
  if [ "$age_h" -le "$UNCOMMITTED_MAX_H" ]; then
    ok uncommitted "memory dirty but fresh (${age_h}h)"
  else
    fail uncommitted "memory uncommitted for ${age_h}h (>${UNCOMMITTED_MAX_H}h) — the committer is stuck"
  fi
else
  ok uncommitted "no uncommitted memory"
fi

# ── report ───────────────────────────────────────────────────────────────────
if [ "$JSON" = "1" ]; then
  printf '{"ok":%s,"fails":%d,"findings":[' "$([ "$fails" -eq 0 ] && echo true || echo false)" "$fails"
  first=1
  for f in "${findings[@]}"; do
    IFS='|' read -r status name detail <<< "$f"
    [ "$first" = 1 ] || printf ','
    first=0
    printf '{"status":"%s","check":"%s","detail":"%s"}' "$status" "$name" "${detail//\"/\\\"}"
  done
  printf ']}\n'
else
  echo "--- dev-tools memory health ---"
  for f in "${findings[@]}"; do
    IFS='|' read -r status name detail <<< "$f"
    printf '%-4s  %-15s %s\n' "$status" "$name" "$detail"
  done
  if [ "$fails" -eq 0 ]; then
    echo "--- all ${#findings[@]} invariants hold ---"
  else
    echo "--- $fails FAILING (of ${#findings[@]}) ---"
  fi
fi

[ "$fails" -eq 0 ] || exit 1
