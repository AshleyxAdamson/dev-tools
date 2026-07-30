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

REPO="/Users/ashley/dev-tools"
PEBBL="/Users/ashley/pebbl/bin/pebbl.js"
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

# Beat the liveness heartbeat, but ONLY after the run is verified healthy. The
# beat lands in LOOM's store (~/loom), because `loom maintain` reads the registry
# from there every 4h and escalates whatever is OVERDUE — the absence of a beat
# is what turns a silent death into an alarm. Never beat from anywhere but this
# scheduled job: a human beating by hand would mask a dead scheduler.
beat() {
  local proof="$1"
  if ! "$REPO/bin/check-memory-health.sh" >>"$LOG" 2>&1; then
    say "NO BEAT invariants failing — see the health report above; liveness will go OVERDUE"
    return 1
  fi
  # Invoke pebbl through node + its entry script, not the bare `pebbl` name:
  # ~/bin is not on launchd's PATH, and a bare name here failed silently in
  # exactly the way this whole heartbeat exists to prevent.
  if (cd /Users/ashley/loom && node "$PEBBL" heartbeat dev-tools-memory \
        --proof "$proof" >/dev/null 2>&1); then
    say "beat dev-tools-memory ($proof)"
  else
    say "WARN heartbeat failed to record — liveness will go OVERDUE even though the run was fine"
  fi
}

if [ -z "$(git status --porcelain -- pebbl-history)" ]; then
  # A quiet day is a healthy day: the pipeline ran and there was nothing new, so
  # it must still beat or every quiet stretch would false-alarm.
  say "nothing to commit"
  beat "no new memory"
  exit 0
fi

git add -- pebbl-history || { say "FATAL git add failed"; exit 1; }

# The pre-commit hook runs the same scan, but check here too so a block is
# recorded in this log with a readable reason instead of a bare non-zero exit.
# Exit 1 means it found leaks; anything else means the scan itself broke, and a
# scan that cannot run must never be reported as either clean or as a leak.
scan=$(node "$PEBBL" privacy-scan --staged 2>&1)
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

# The push is what gets memory OFF this machine, so a failure here is a real
# degradation even though the commit is safely local — no beat, so liveness
# escalates it rather than leaving it to be noticed by luck.
if git push -q origin HEAD 2>>"$LOG"; then
  say "pushed"
  beat "$(git rev-parse --short HEAD)"
else
  say "push failed (commit is local — PAT expired or lost repo access); NOT beating"
fi
