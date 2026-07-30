#!/bin/bash
# Prove each probe in check-memory-health.sh actually FIRES. A monitor that has
# only ever returned green is indistinguishable from a monitor that cannot fail,
# so break each invariant on purpose, confirm the check catches it, and restore.
#
# Everything is restored in a trap, so an abort mid-test cannot leave the live
# pipeline broken. Run it any time: ./bin/test-memory-health.sh
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
  # Idempotent: each step only acts if that fault is still in place.
  [ -L "$STORE_LINK" ] || { rm -rf "$STORE_LINK"; ln -sfn "$LIVE" "$STORE_LINK"; }
  [ -L "$HOME/.claude/skills/anti-ai-prose" ] || \
    ln -sfn "$REPO/skills/anti-ai-prose" "$HOME/.claude/skills/anti-ai-prose"
  launchctl list 2>/dev/null | grep -q "$LABEL" || launchctl load "$PLIST" 2>/dev/null
  git -C "$REPO" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1 || \
    git -C "$REPO" branch --set-upstream-to=origin/main main >/dev/null 2>&1
}
trap restore EXIT INT TERM

# Assert the check reports FAIL for $1 while a fault is in place.
expect_fail_on() {
  local probe="$1" desc="$2"
  local out
  out=$("$CHECK" 2>&1)
  if printf '%s' "$out" | grep -qE "^FAIL  +$probe "; then
    printf 'CAUGHT   %-15s %s\n' "$probe" "$desc"
    pass=$((pass + 1))
  else
    printf 'MISSED   %-15s %s\n' "$probe" "$desc"
    printf '%s\n' "$out" | sed 's/^/           /'
    fail=$((fail + 1))
  fi
}

echo "=== baseline: everything should be green ==="
if "$CHECK" >/dev/null 2>&1; then
  echo "OK       baseline clean"
  pass=$((pass + 1))
else
  echo "ABORT    baseline is already failing — fix that before trusting this test"
  "$CHECK" | sed 's/^/           /'
  exit 1
fi

echo
echo "=== fault injection ==="

# 1. the store symlink replaced by a real directory (memory silently splits)
rm "$STORE_LINK" && mkdir -p "$STORE_LINK"
expect_fail_on store-symlink "store link replaced by a real directory"
rmdir "$STORE_LINK" && ln -sfn "$LIVE" "$STORE_LINK"

# 2. the store symlink pointing somewhere else
ln -sfn /tmp "$STORE_LINK"
expect_fail_on store-symlink "store link points at the wrong target"
ln -sfn "$LIVE" "$STORE_LINK"

# 3. a skill symlink broken
rm "$HOME/.claude/skills/anti-ai-prose"
expect_fail_on symlinks "a skill symlink removed"
ln -sfn "$REPO/skills/anti-ai-prose" "$HOME/.claude/skills/anti-ai-prose"

# 4. the scheduled job unloaded
launchctl unload "$PLIST" 2>/dev/null
expect_fail_on launchd "scheduled job unloaded"
launchctl load "$PLIST" 2>/dev/null

# 5. upstream tracking lost (breaks drift detection)
git -C "$REPO" branch --unset-upstream 2>/dev/null
expect_fail_on unpushed "upstream tracking removed"
git -C "$REPO" branch --set-upstream-to=origin/main main >/dev/null 2>&1

echo
echo "=== restore + confirm green again ==="
restore
if "$CHECK" >/dev/null 2>&1; then
  echo "OK       restored clean"
  pass=$((pass + 1))
else
  echo "BAD      did not restore cleanly"
  "$CHECK" | sed 's/^/           /'
  fail=$((fail + 1))
fi

echo
echo "passed: $pass   failed: $fail"
[ "$fail" -eq 0 ] || exit 1
