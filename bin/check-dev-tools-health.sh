#!/bin/bash
# Verify -- and REPAIR -- the invariants dev-tools itself owns.
#
# Until 2026-07-30 this file also watched pebbl's memory pipeline, because the
# store lived here and ~/pebbl/.pebbl symlinked in. The store moved into the
# pebbl repo, and its checks went with it: see ~/pebbl/ops/check-memory-health.sh.
# What is left is what this repo actually owns -- the symlinks that put the
# skills and the statusline where Claude Code looks for them, and the TCC
# constraint on where this repo may live.
#
# Repairing by default is a deliberate choice: a symlink has exactly one correct
# target, so there is no diagnosis to get wrong. Relocating the repo is the
# carve-out and stays report-only.
#
#   (no args)   verify and repair          --verify-only   report, change nothing
#   --json      machine-readable           --fix-location  allow the repo relocation
#
# Exit 0 = everything holds (possibly after repair). Exit 1 = still broken.
set -uo pipefail

REPO="/Users/ashley/dev-tools"
PEBBL="/Users/ashley/pebbl/bin/pebbl.js"
SKILLS="activity-check anti-ai-prose design-spike flare-strategy loom-refine loom-work research-planner skill-builder"

JSON=0; REPAIR=1; FIX_LOCATION=0
for a in "$@"; do
  case "$a" in
    --json) JSON=1 ;;
    --verify-only) REPAIR=0 ;;
    --fix-location) FIX_LOCATION=1 ;;
  esac
done

fails=0; repairs=0
findings=()

ok()     { findings+=("PASS|$1|$2"); }
fail()   { findings+=("FAIL|$1|$2"); fails=$((fails + 1)); }
fixed()  { findings+=("FIXED|$1|$2"); repairs=$((repairs + 1)); log_repair "$1" "$2"; }

# Record the repair in pebbl so a RECURRING break escalates instead of being
# quietly papered over every night. Best-effort: a store that cannot be written
# must not turn a successful repair into a failure.
log_repair() {
  local check="$1" detail="$2"
  (cd /Users/ashley/loom && node "$PEBBL" log \
     "auto-repaired dev-tools memory invariant [$check]: $detail" \
     --cat steering --topic loom,pebbl,liveness,self-heal >/dev/null 2>&1) || true
}

# Attempt a repair only when repairing is enabled; otherwise record the FAIL.
# $1 check name, $2 problem description, $3 repair description, $4.. the command.
try_fix() {
  local check="$1" problem="$2" what="$3"; shift 3
  if [ "$REPAIR" != "1" ]; then
    fail "$check" "$problem (repairable: $what)"
    return 1
  fi
  if "$@" >/dev/null 2>&1; then
    fixed "$check" "$problem -> $what"
    return 0
  fi
  fail "$check" "$problem — REPAIR FAILED ($what)"
  return 1
}

# ── 3. repo location (TCC) — REPORT-ONLY by default ──────────────────────────
# Relocating means moving 37 files and repointing 10 symlinks. Doing that
# underneath a live session is how you corrupt someone's work in progress, so it
# needs --fix-location. This is one of the two carve-outs.
check_repo_location() {
  case "$REPO" in
    "$HOME"/Documents/*|"$HOME"/Desktop/*|"$HOME"/Downloads/*) ;;
    *) ok repo-location "$REPO is outside the TCC-protected folders"; return ;;
  esac
  if [ "$FIX_LOCATION" = "1" ] && [ "$REPAIR" = "1" ]; then
    fail repo-location "inside a TCC-protected folder — rerun the move by hand: mv '$REPO' ~/dev-tools then re-run this check to repair the symlinks"
  else
    fail repo-location "inside a macOS TCC-protected folder — launchd cannot read it (pass --fix-location for guidance; not moved automatically under a live session)"
  fi
}

# ── 4. skill + statusline symlinks ───────────────────────────────────────────
check_symlinks() {
  local broken="" repaired="" still=""
  for n in $SKILLS; do
    local p="$HOME/.claude/skills/$n"
    { [ -L "$p" ] && [ -f "$p/SKILL.md" ]; } && continue
    broken="$broken $n"
    if [ "$REPAIR" = "1" ] && [ -f "$REPO/skills/$n/SKILL.md" ]; then
      rm -rf "$p" 2>/dev/null
      if ln -sfn "$REPO/skills/$n" "$p" 2>/dev/null && [ -f "$p/SKILL.md" ]; then
        repaired="$repaired $n"; continue
      fi
    fi
    still="$still $n"
  done
  local sl="$HOME/.claude/statusline.sh"
  if ! { [ -L "$sl" ] && [ -f "$sl" ]; }; then
    broken="$broken statusline.sh"
    if [ "$REPAIR" = "1" ] && [ -f "$REPO/statusline/statusline.sh" ] \
       && ln -sfn "$REPO/statusline/statusline.sh" "$sl" 2>/dev/null; then
      repaired="$repaired statusline.sh"
    else
      still="$still statusline.sh"
    fi
  fi

  if [ -z "$broken" ]; then
    ok symlinks "8 skills + statusline resolve into the repo"
  elif [ -z "$still" ]; then
    fixed symlinks "relinked:$repaired"
  else
    fail symlinks "could not relink:$still (source missing in the repo?)"
  fi
}

check_repo_location
check_symlinks

# ── report ───────────────────────────────────────────────────────────────────
if [ "$JSON" = "1" ]; then
  printf '{"ok":%s,"fails":%d,"repairs":%d,"findings":[' \
    "$([ "$fails" -eq 0 ] && echo true || echo false)" "$fails" "$repairs"
  first=1
  for f in "${findings[@]}"; do
    IFS='|' read -r status name detail <<< "$f"
    [ "$first" = 1 ] || printf ','
    first=0
    printf '{"status":"%s","check":"%s","detail":"%s"}' "$status" "$name" "${detail//\"/\\\"}"
  done
  printf ']}\n'
else
  echo "--- dev-tools health ---"
  for f in "${findings[@]}"; do
    IFS='|' read -r status name detail <<< "$f"
    printf '%-5s %-15s %s\n' "$status" "$name" "$detail"
  done
  summary="${#findings[@]} invariants"
  [ "$repairs" -gt 0 ] && summary="$summary, $repairs repaired"
  if [ "$fails" -eq 0 ]; then
    echo "--- all hold ($summary) ---"
  else
    echo "--- $fails STILL BROKEN ($summary) ---"
  fi
fi

[ "$fails" -eq 0 ] || exit 1
