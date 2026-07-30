#!/bin/bash
# Prove jd-check both FLAGS a bad name and SPARES every exempt one. A checker
# that has only ever returned green is indistinguishable from one that cannot
# fail, and an exemption list nobody tested is indistinguishable from no
# exemption list — so assert both halves on a scratch tree.
#
# The exemption half is the important one. A false positive here means the fix
# is "rename README.md", which breaks GitHub. Wrong-and-confident beats missing.

set -uo pipefail

JD="$(dirname "$0")/jd-check.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok()   { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL %s\n' "$1"; fail=$((fail + 1)); }

# Run jd-check and echo its output. Deliberately NOT `jd-check | grep`: this
# script sets `pipefail`, and jd-check exits 1 by design when it finds
# violations, so the pipeline inherits that 1 and every `if …| grep -q` test
# silently took its else branch — the suite inverted its own results. Capture
# the output first, grep the variable second.
run_jd() { "$JD" --all "$TMP/repo" 2>/dev/null || true; }

# assert_flagged <relpath> — jd-check must report this file
assert_flagged() {
  if printf '%s' "$(run_jd)" | grep -Fq "$1"; then
    ok "flagged   $1"
  else
    bad "flagged   $1  (expected a violation, got none)"
  fi
}

# assert_spared <relpath> — jd-check must NOT report this file
assert_spared() {
  if printf '%s' "$(run_jd)" | grep -Fq "$1"; then
    bad "spared    $1  (exempt file was flagged — this breaks tooling)"
  else
    ok "spared    $1"
  fi
}

mk() { mkdir -p "$(dirname "$TMP/repo/$1")"; echo "x" > "$TMP/repo/$1"; }

mkdir -p "$TMP/repo"

echo "== detects bad names in docs/ =="
mk 'docs/kebab-case-thing.md'
mk 'docs/SHOUTY-SPEC.md'
mk 'docs/2026-06-23-date-suffixed.md'
mk 'docs/nested/deep/also-bad.md'
assert_flagged 'docs/kebab-case-thing.md'
assert_flagged 'docs/SHOUTY-SPEC.md'
assert_flagged 'docs/2026-06-23-date-suffixed.md'
assert_flagged 'docs/nested/deep/also-bad.md'

echo "== accepts correct JD names =="
mk 'docs/15.01 Three-pass pipeline spec.md'
mk 'docs/11.02 Spike 2 findings.md'
assert_spared '15.01 Three-pass pipeline spec.md'
assert_spared '11.02 Spike 2 findings.md'

echo "== spares fixed-name files (tools read these by exact path) =="
mk 'docs/index.md'
mk 'docs/README.md'
mk 'README.md'
mk 'AGENTS.md'
mk 'CLAUDE.md'
mk 'CHANGELOG.md'
mk 'SECURITY.md'
mk 'CONTRIBUTING.md'
mk 'LICENSE.md'
mk 'docs/SUMMARY.md'
mk 'src/capabilities/README.md'
assert_spared 'docs/index.md'
assert_spared 'docs/README.md'
assert_spared 'src/capabilities/README.md'
assert_spared 'CHANGELOG.md'
assert_spared 'CONTRIBUTING.md'

echo "== spares program inputs (application code loads these) =="
mk 'prompts/01-extract-clauses.md'
mk 'prompts/dad/02-classify.md'
mk 'bookforge/workflows/draft.md'
mk 'skill/SKILL.md'
mk '.claude/agents/some-agent.md'
assert_spared 'prompts/01-extract-clauses.md'
assert_spared 'prompts/dad/02-classify.md'
assert_spared 'workflows/draft.md'
assert_spared '.claude/agents/some-agent.md'

echo "== spares build output and vendored trees =="
mk 'node_modules/pkg/docs/whatever.md'
mk 'target/debug/docs/readme-ish.md'
mk '.venv/lib/docs/thing.md'
assert_spared 'node_modules/pkg/docs/whatever.md'
assert_spared 'target/debug/docs/readme-ish.md'
assert_spared '.venv/lib/docs/thing.md'

echo "== spares a NESTED git repo (third-party fixture) =="
mk 'testbed/other-app/docs/their-spec.md'
mkdir -p "$TMP/repo/fixtures-live/vendored-app/.git"
mk 'fixtures-live/vendored-app/docs/not-ours.md'
assert_spared 'testbed/other-app/docs/their-spec.md'
assert_spared 'fixtures-live/vendored-app/docs/not-ours.md'

echo "== spares docs/handoffs (pebbl regenerates that recommendation) =="
mk 'docs/handoffs/auth-rework.md'
mk 'docs/my-handoff.md'
assert_spared 'docs/handoffs/auth-rework.md'
assert_flagged 'docs/my-handoff.md'

echo "== docs/ is hard scope, others advisory =="
mk 'ops/operating-thing.md'
hard_only="$("$JD" "$TMP/repo" 2>/dev/null || true)"
if printf '%s' "$hard_only" | grep -Fq 'ops/operating-thing.md'; then
  bad "advisory  ops/ leaked into the default (hard) run"
else
  ok "advisory  ops/ hidden without --all"
fi
if printf '%s' "$(run_jd)" | grep -Fq 'ops/operating-thing.md'; then
  ok "advisory  ops/ listed with --all"
else
  bad "advisory  ops/ missing from --all"
fi

echo "== exit codes =="
rm -rf "$TMP/repo"; mkdir -p "$TMP/repo/docs"
mk 'docs/16.01 Handoff.md'
"$JD" "$TMP/repo" >/dev/null 2>&1
[ $? -eq 0 ] && ok "exit 0 on a clean tree" || bad "exit 0 on a clean tree"
mk 'docs/bad-name.md'
"$JD" "$TMP/repo" >/dev/null 2>&1
[ $? -eq 1 ] && ok "exit 1 when docs/ has violations" || bad "exit 1 when docs/ has violations"
"$JD" --all "$TMP/repo/nope-does-not-exist" >/dev/null 2>&1
[ $? -eq 2 ] && ok "exit 2 on a bad path" || bad "exit 2 on a bad path"

echo
echo "$pass passed, $fail failed"
[ $fail -eq 0 ] || exit 1
