#!/bin/bash
# Commit (and push, when the remote is reachable) any pebbl memory written since
# the last run. Driven by launchd once a day — see com.ashley.dev-tools-memory.
#
# Why this exists: ~/pebbl/.pebbl symlinks into this repo, so the working tree
# is always current, but nothing is preserved until it is committed. A quiet
# week would otherwise leave a week of decisions uncommitted.
#
# Only events.jsonl is tracked for the live store (the rest is derived and
# gitignored), so a run either commits one text file or does nothing.
set -uo pipefail

REPO="/Users/ashley/Documents/10.Code-Projects/dev-tools"
LOG="$REPO/.git/memory-commit.log"
PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

say() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }

# launchd hands us a minimal PATH with no node, and node is needed twice: by the
# privacy scan below and by this repo pre-commit hook. Resolve it once and put
# its directory on PATH so both find it. nvm's version dir is globbed rather
# than pinned so a node upgrade does not silently break the job.
if ! command -v node >/dev/null 2>&1; then
  for cand in /opt/homebrew/bin/node /usr/local/bin/node \
              "$HOME"/.nvm/versions/node/*/bin/node; do
    [ -x "$cand" ] && { PATH="$(dirname "$cand"):$PATH"; break; }
  done
fi
if ! command -v node >/dev/null 2>&1; then
  say "FATAL node not found — cannot run the privacy scan, refusing to commit"
  exit 1
fi

cd "$REPO" || { say "FATAL cannot cd to $REPO"; exit 1; }

# Never fight a human mid-edit: if anything outside the pebbl stores is dirty,
# this is someone's working session, so stay out of it.
other=$(git status --porcelain -- . ':(exclude)pebbl-history' | head -1)
if [ -n "$other" ]; then
  say "SKIP working tree dirty outside pebbl-history ($other)"
  exit 0
fi

if [ -z "$(git status --porcelain -- pebbl-history)" ]; then
  say "nothing to commit"
  exit 0
fi

git add -- pebbl-history || { say "FATAL git add failed"; exit 1; }

# The pre-commit hook runs the same scan, but check here too so a block is
# recorded in this log with a readable reason instead of a bare non-zero exit.
# Exit 1 means it found leaks; anything else means the scan itself broke, and a
# scan that cannot run must never be reported as either clean or as a leak.
scan=$(node /Users/ashley/pebbl/bin/pebbl.js privacy-scan --staged 2>&1)
rc=$?
if [ "$rc" -eq 1 ]; then
  say "BLOCKED privacy-scan found leaks in the staged memory — left staged for review"
  printf '%s\n' "$scan" >> "$LOG"
  exit 1
elif [ "$rc" -ne 0 ]; then
  say "FATAL privacy-scan could not run (exit $rc) — refusing to commit unscanned memory"
  printf '%s\n' "$scan" >> "$LOG"
  exit 1
fi

n=$(git diff --cached --numstat -- pebbl-history | awk '{a+=$1; d+=$2} END {print a+0"+/"d+0"-"}')
if git commit -q -m "memory: pebbl decisions through $(date '+%Y-%m-%d') ($n)"; then
  say "committed $n"
else
  say "FATAL commit failed"; exit 1
fi

# Push is best-effort: the fine-grained PAT has to grant this repo access, and
# until it does the commit is still safely local.
if git push -q origin HEAD 2>>"$LOG"; then
  say "pushed"
else
  say "push failed (commit is local — check PAT access to the repo)"
fi
