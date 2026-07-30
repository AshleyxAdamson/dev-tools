#!/usr/bin/env bash
# Repoint agent-deck sessions from /Users/ashley to their real repos.
#
# Why not `agent-deck session move`: that command migrates the WHOLE Claude
# project dir (~/.claude/projects/<slug>/) and hard-errors if the destination
# already exists. Every one of these sessions shares the source dir
# -Users-ashley, and the destinations (-Users-ashley-loom, ...-jig,
# ...-lawyer-tool-rs) already exist from prior work. The guard is correct — a
# dir-level move would drag all 11 sessions plus every home-dir Claude session
# into one repo and clobber real history. So it can't be used here.
#
# This sets project_path only. Conversation history stays in
# ~/.claude/projects/-Users-ashley/ and is still resumable from there.
#
# MUST run with the agent-deck TUI closed: SaveInstances does a full-row
# INSERT OR REPLACE and pre-merges only tool_data/auto_name, so a live TUI
# would revert project_path from its stale in-memory snapshot.

set -euo pipefail

DB="$HOME/.local/share/agent-deck/profiles/default/state.db"

# Only the TUI (and web mutator) call SaveInstances. notify-daemon never
# touches the instance store, so it can keep running.
TUI_PIDS=$(pgrep -fl "agent-deck" 2>/dev/null \
  | grep -v "notify-daemon" \
  | grep -v "agent-deck-fix-session-paths" \
  | awk '{print $1}' || true)

if [ -n "$TUI_PIDS" ]; then
  echo "ERROR: the agent-deck TUI is still running. Quit it (q), then re-run."
  echo "Offending processes:"
  ps -o pid=,command= -p $(echo "$TUI_PIDS" | tr '\n' ',' | sed 's/,$//') 2>/dev/null
  exit 1
fi

[ -f "$DB" ] || { echo "ERROR: no DB at $DB"; exit 1; }

BACKUP="$HOME/.local/share/agent-deck/profiles/default/state.db.bak-$(date +%Y%m%d-%H%M%S)"
cp "$DB" "$BACKUP"
echo "backed up DB -> $BACKUP"

# title -> repo path. Only the mappings the group names make unambiguous.
# Deliberately NOT included (no clear repo, left at /Users/ashley):
#   slutwear, Fixer, fixer-3, jade-otter, bv-research
apply() {
  local title="$1" path="$2"
  if [ ! -d "$path/.git" ]; then
    echo "SKIP  $title -> $path (not a git repo)"
    return
  fi
  local n
  n=$(sqlite3 "$DB" \
    "UPDATE instances SET project_path='$path' WHERE title='$title' AND archived_at=0;
     SELECT changes();")
  echo "OK    $title -> $path ($n row)"
}

apply "Janitor"  "$HOME/loom"
apply "fixer-2"  "$HOME/loom"
apply "Jig"      "$HOME/Documents/10.Code-Projects/jig"
apply "eager-canyon" "$HOME/Documents/10.Code-Projects/jig"
apply "leafy-thistle" "$HOME/pebbl"
apply "tf law"   "$HOME/Documents/10.Code-Projects/lawyer-tool-rs"

echo
echo "--- result ---"
sqlite3 -column -header "$DB" \
  "SELECT title, group_path, project_path FROM instances WHERE archived_at=0 ORDER BY group_path;"

echo
echo "Next: restart each moved session in agent-deck so the new cwd takes effect."
echo "Rollback: cp '$BACKUP' '$DB'"
