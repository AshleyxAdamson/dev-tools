#!/bin/bash
# Prove the health check both DETECTS and REPAIRS each invariant. A monitor that
# has only ever returned green is indistinguishable from one that cannot fail,
# and a repairer that has never repaired is indistinguishable from one that
# cannot repair — so break each invariant on purpose and assert both halves:
#
#   1. --verify-only reports it as FAIL   (detection works)
#   2. a normal run reports FIXED         (repair is attempted)
#   3. the invariant is genuinely restored afterwards (repair actually worked)
#
# Everything is restored in a trap, so aborting mid-test cannot leave the live
# pipeline broken.
set -uo pipefail

REPO="/Users/ashley/dev-tools"
LIVE="$REPO/pebbl-history/live"
STORE_LINK="/Users/ashley/pebbl/.pebbl"
CHECK="$REPO/bin/check-memory-health.sh"
LABEL="com.ashley.dev-tools-memory"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

pass=0
fail=0

restore() {
  [ -L "$STORE_LINK" ] || { rm -rf "$STORE_LINK"; ln -sfn "$LIVE" "$STORE_LINK"; }
  [ -L "$HOME/.claude/skills/anti-ai-prose" ] || \
    ln -sfn "$REPO/skills/anti-ai-prose" "$HOME/.claude/skills/anti-ai-prose"
  launchctl list 2>/dev/null | grep -q "$LABEL" || launchctl load "$PLIST" 2>/dev/null
  git -C "$REPO" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1 || \
    git -C "$REPO" branch --set-upstream-to=origin/main main >/dev/null 2>&1
  rm -rf /Users/ashley/pebbl/.pebbl-orphaned-* 2>/dev/null
}
trap restore EXIT INT TERM

note() { printf '%-9s %-15s %s\n' "$1" "$2" "$3"; }

# $1 probe name, $2 description, $3 a command asserting the invariant is restored
cycle() {
  local probe="$1" desc="$2" assert="$3" out

  # The check EXITS 1 when something is broken, which is the whole point here.
  # Capture its output first and grep the variable: piping it straight into grep
  # would let `set -o pipefail` fail the pipeline on the check's exit code and
  # throw away a perfectly good match.

  # 1. detection
  out=$("$CHECK" --verify-only 2>&1) || true
  if printf '%s\n' "$out" | grep -qE "^FAIL  +$probe "; then
    note DETECTED "$probe" "$desc"
    pass=$((pass + 1))
  else
    note MISSED "$probe" "$desc"
    printf '%s\n' "$out" | sed 's/^/            /'
    fail=$((fail + 1))
    return
  fi

  # 2. repair attempted
  out=$("$CHECK" 2>&1) || true
  if printf '%s\n' "$out" | grep -qE "^FIXED +$probe "; then
    note REPAIRED "$probe" "$desc"
    pass=$((pass + 1))
  else
    note NOFIX "$probe" "$desc"
    printf '%s\n' "$out" | sed 's/^/            /'
    fail=$((fail + 1))
    return
  fi

  # 3. repair actually worked
  if eval "$assert"; then
    note VERIFIED "$probe" "invariant genuinely restored"
    pass=$((pass + 1))
  else
    note BOGUS "$probe" "reported FIXED but the invariant is still broken"
    fail=$((fail + 1))
  fi
}

echo "=== baseline ==="
if "$CHECK" --verify-only >/dev/null 2>&1; then
  note OK baseline "clean before we start"
  pass=$((pass + 1))
else
  note ABORT baseline "already failing — fix that before trusting this test"
  "$CHECK" --verify-only | sed 's/^/            /'
  exit 1
fi

echo
echo "=== detect + repair + verify, per invariant ==="

# store link missing
rm "$STORE_LINK"
cycle store-symlink "store link deleted" \
  '[ -L "$STORE_LINK" ] && [ "$(readlink "$STORE_LINK")" = "$LIVE" ]'

# store link pointing at the wrong place
ln -sfn /tmp "$STORE_LINK"
cycle store-symlink "store link points at the wrong target" \
  '[ "$(readlink "$STORE_LINK")" = "$LIVE" ]'

# store link replaced by a REAL directory holding unversioned memory.
# The repair must PRESERVE that memory, never delete it.
rm "$STORE_LINK"; mkdir -p "$STORE_LINK"
echo '{"canary":"unversioned memory that must survive the repair"}' \
  > "$STORE_LINK/events.jsonl"
cycle store-symlink "store link replaced by a real directory" \
  '[ -L "$STORE_LINK" ] && [ -n "$(ls -d /Users/ashley/pebbl/.pebbl-orphaned-* 2>/dev/null)" ]'
if grep -qs canary /Users/ashley/pebbl/.pebbl-orphaned-*/events.jsonl; then
  note VERIFIED store-symlink "orphaned memory preserved, not deleted"
  pass=$((pass + 1))
else
  note BOGUS store-symlink "orphaned memory was LOST by the repair"
  fail=$((fail + 1))
fi
rm -rf /Users/ashley/pebbl/.pebbl-orphaned-* 2>/dev/null

# the completeness marker removed, so pebbl silently serves an EMPTY store.
# This is the amnesia failure: history is right there in events.jsonl, every read
# comes back empty, and nothing errors. Assert BOTH that the marker returns and
# that pebbl can actually see its entries again.
rm -f "$LIVE/.events-canonical"
cycle store-mode "completeness marker removed (store reads EMPTY)" \
  '[ -f "$LIVE/.events-canonical" ]'
if (cd /Users/ashley/pebbl && pebbl context 2>/dev/null | grep -q 'TOPICS ('); then
  note VERIFIED store-mode "pebbl can read its entries again, not an empty store"
  pass=$((pass + 1))
else
  note BOGUS store-mode "marker restored but pebbl still reads EMPTY"
  fail=$((fail + 1))
fi

# a skill symlink removed
rm "$HOME/.claude/skills/anti-ai-prose"
cycle symlinks "a skill symlink removed" \
  '[ -f "$HOME/.claude/skills/anti-ai-prose/SKILL.md" ]'

# scheduled job unloaded
launchctl unload "$PLIST" 2>/dev/null
cycle launchd "scheduled job unloaded" \
  'launchctl list 2>/dev/null | grep -q "$LABEL"'

# upstream tracking lost
git -C "$REPO" branch --unset-upstream 2>/dev/null
cycle unpushed "upstream tracking removed" \
  'git -C "$REPO" rev-parse --abbrev-ref "@{upstream}" >/dev/null 2>&1'

# a derived file tracked (gitignore regression).
# Staged only — `git ls-files` reads the index, so forcing it there is a faithful
# fault without inventing a commit the repo history has to carry forever.
git -C "$REPO" add -f pebbl-history/live/db.sqlite >/dev/null 2>&1
cycle tracked-set "a derived file got tracked" \
  '[ -z "$(git -C "$REPO" ls-files pebbl-history/live/db.sqlite)" ]'

echo
echo "=== restore + confirm green ==="
restore
if "$CHECK" --verify-only >/dev/null 2>&1; then
  note OK restored "clean"
  pass=$((pass + 1))
else
  note BAD restored "did not come back clean"
  "$CHECK" --verify-only | sed 's/^/            /'
  fail=$((fail + 1))
fi

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ] || exit 1
