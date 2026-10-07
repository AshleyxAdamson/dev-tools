#!/bin/bash
# Keep the Obsidian theme in this repo and the copy in the vault the same.
#
# Everything else in dev-tools is symlinked into place. The theme cannot be:
# the vault lives in iCloud and the phone reads it, and iCloud does not follow
# a symlink out of the vault. So this is the one real copy in the repo, and a
# copy cannot tell you it went stale. This script is what tells you.
#
# The repo is the source. Edit the theme here, --install, look at Obsidian
# (it reloads a theme when the file changes), and commit when it is right.
#
# Usage:
#   obsidian-theme.sh              # compare repo and vault, change nothing
#   obsidian-theme.sh --install    # repo -> vault
#   obsidian-theme.sh --pull       # vault -> repo, for an edit made in the vault
#   obsidian-theme.sh --vault DIR  # a vault other than Main
#
# Exit: 0 same (or copied), 1 the copies differ, 2 bad usage or no vault.

set -uo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)/obsidian/themes"
VAULT="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main"
MODE=check

while [ $# -gt 0 ]; do
  case "$1" in
    --install) MODE=install ;;
    --pull) MODE=pull ;;
    --vault)
      shift
      [ $# -gt 0 ] || { echo "obsidian-theme: --vault needs a path" >&2; exit 2; }
      VAULT="$1" ;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "obsidian-theme: unknown argument $1" >&2; exit 2 ;;
  esac
  shift
done

DEST="$VAULT/.obsidian/themes"
[ -d "$VAULT/.obsidian" ] || { echo "obsidian-theme: no vault at $VAULT" >&2; exit 2; }

status=0
for dir in "$SRC"/*/; do
  name=$(basename "$dir")
  for f in theme.css manifest.json; do
    repo="$dir$f"
    vault="$DEST/$name/$f"
    case "$MODE" in
      install)
        if mkdir -p "$DEST/$name" && cp "$repo" "$vault"; then echo "installed  $name/$f"
        else status=1; fi ;;
      pull)
        if [ -f "$vault" ] && cp "$vault" "$repo"; then echo "pulled     $name/$f"
        else echo "MISSING    $name/$f (not in the vault)"; status=1; fi ;;
      check)
        if [ ! -f "$vault" ]; then echo "MISSING    $name/$f (not in the vault)"; status=1
        elif ! cmp -s "$repo" "$vault"; then echo "DIFFERS    $name/$f"; status=1
        else echo "same       $name/$f"; fi ;;
    esac
  done
done

if [ "$MODE" = check ] && [ $status -eq 1 ]; then
  echo "Repo and vault differ. --install makes the vault match the repo; --pull does the reverse."
fi
exit $status
