#!/bin/bash
# Report knowledge docs that don't follow Johnny Decimal naming.
# Rules: ~/dev-tools/johnny-decimal-rules.md
#
# Two scopes, on purpose:
#
#   HARD      docs/**/*.md      must be "NN.NN Title.md" — violations exit 1
#   ADVISORY  plans|ops|notes|research/**   reported only with --all, never exits 1
#
# The hard scope is narrow because loom's review guard blocks on it. A gate that
# is sometimes wrong teaches you to bypass it, and a bypassed gate protects
# nothing — so the block only covers docs/, where the answer is never ambiguous.
#
# The exemptions matter more than the check. Plenty of .md files are read by
# something other than a human (GitHub reads README.md, the skill loader reads
# SKILL.md, Terraform-for-Law's own pipeline loads prompts/01-extract-clauses.md).
# Renaming those breaks them, so they are skipped by basename and by directory.
#
# Usage:
#   jd-check.sh                    # scan the standard roots, hard scope
#   jd-check.sh --all              # include the advisory scope
#   jd-check.sh path [path...]     # scan specific trees
#   jd-check.sh --all ~/loom
#
# Exit: 0 clean, 1 hard violations found, 2 bad usage.

set -uo pipefail

# --- what counts as correctly named -----------------------------------------
JD_RE='^[0-9][0-9]\.[0-9][0-9] .+\.md$'

# Fixed-name files: something other than a human reads these by exact name.
# Compared lowercase, so README.md and readme.md both match.
FIXED_NAMES="readme.md agents.md claude.md skill.md contributing.md security.md
code_of_conduct.md changelog.md license.md licence.md index.md summary.md
_sidebar.md _index.md _footer.md _navbar.md notes.md results.md plan.md
design.md findings.md product.md smoke.md vendored.md"

# Directories never scanned: build output, vendored code, tool state, and the
# dirs whose .md files are program inputs rather than documentation.
SKIP_DIRS=".git node_modules target .venv venv vendor dist build .next
.pebbl .pytest_cache .frontloop .claude .cache site-packages __pycache__
prompts workflows skill skills templates fixtures testdata"

# Trees scanned when no path argument is given.
DEFAULT_ROOTS="$HOME/loom $HOME/Documents/10.Code-Projects"

SHOW_ADVISORY=0
ROOTS=""

while [ $# -gt 0 ]; do
  case "$1" in
    --all) SHOW_ADVISORY=1 ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "jd-check: unknown flag $1" >&2; exit 2 ;;
    *)  ROOTS="$ROOTS $1" ;;
  esac
  shift
done
[ -n "${ROOTS// /}" ] || ROOTS="$DEFAULT_ROOTS"

# Build the find prune expression from SKIP_DIRS once, as an ARGUMENT ARRAY.
# Not a string + eval: find's grouping parens are shell metacharacters, so an
# eval'd string dies with "syntax error near unexpected token `('" — and because
# the failure was on stderr behind a 2>/dev/null, it reported everything clean.
PRUNE=()
first=1
for d in $SKIP_DIRS; do
  if [ $first -eq 1 ]; then PRUNE+=( '(' ); else PRUNE+=( -o ); fi
  PRUNE+=( -name "$d" )
  first=0
done
PRUNE+=( ')' -prune -o )

is_fixed_name() {
  local lower n
  lower=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  for n in $FIXED_NAMES; do
    [ "$lower" = "$n" ] && return 0
  done
  return 1
}

# Which scope does this path fall in? Echoes "hard", "advisory", or nothing.
# Matches on a path SEGMENT (/docs/), so a file merely named docs-foo.md and a
# directory called mydocs are both correctly ignored.
scope_of() {
  case "$1" in
    */docs/*) echo hard; return ;;
  esac
  case "$1" in
    */plans/*|*/ops/*|*/notes/*|*/research/*) echo advisory ;;
  esac
}

hard_count=0
advisory_count=0
hard_out=""
advisory_out=""

for root in $ROOTS; do
  if [ ! -d "$root" ]; then
    echo "jd-check: no such directory: $root" >&2
    exit 2
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    base=${f##*/}
    is_fixed_name "$base" && continue
    scope=$(scope_of "$f")
    [ -n "$scope" ] || continue
    printf '%s' "$base" | grep -Eq "$JD_RE" && continue
    rel=${f#"$root"/}
    if [ "$scope" = hard ]; then
      hard_out="$hard_out  $(basename "$root")/$rel"$'\n'
      hard_count=$((hard_count + 1))
    else
      advisory_out="$advisory_out  $(basename "$root")/$rel"$'\n'
      advisory_count=$((advisory_count + 1))
    fi
  done < <(find "$root" "${PRUNE[@]}" -type f -name '*.md' -print)
done

if [ $hard_count -gt 0 ]; then
  echo "NOT JD-NAMED — docs/ (must be fixed):"
  printf '%s' "$hard_out"
fi

if [ $SHOW_ADVISORY -eq 1 ] && [ $advisory_count -gt 0 ]; then
  echo
  echo "NOT JD-NAMED — plans/ ops/ notes/ research/ (advisory, your call):"
  printf '%s' "$advisory_out"
fi

echo
if [ $hard_count -eq 0 ]; then
  echo "docs/ clean."
else
  echo "$hard_count file(s) in docs/ need JD names."
fi
if [ $SHOW_ADVISORY -eq 1 ]; then
  echo "$advisory_count advisory file(s)."
elif [ $advisory_count -gt 0 ]; then
  echo "$advisory_count advisory file(s) outside docs/ — rerun with --all to list."
fi
echo "Rules: ~/dev-tools/johnny-decimal-rules.md · spine: 11 findings 12 results"
echo "13 plans 14 research 15 specs 16 handoffs 17 runbooks 18 design"

[ $hard_count -eq 0 ] || exit 1
exit 0
