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
if ! scan=$(node /Users/ashley/pebbl/bin/pebbl.js privacy-scan --staged 2>&1); then
  say "BLOCKED privacy-scan refused the staged memory — left staged for review"
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
