#!/bin/bash
# Prove tag-check both FLAGS a stranger and SPARES everything it should. Same
# reasoning as test-jd-check.sh: a checker that has only ever said "clean" is
# indistinguishable from one that cannot fail.
#
# The spare half matters most here too. If the checker flags a hashtag inside a
# code block, or a sub-tag under an allowed branch, the fix it asks for is one
# you should not make, and after the second false alarm nobody reads the output.
#
# One case is here because it already happened: a generator wrote its tags as a
# YAML flow list (tags: ["a", "b"]) and a parser that only knew block lists saw
# nothing at all.

set -uo pipefail

TC="$(dirname "$0")/tag-check.py"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
VAULT="$TMP/vault"

pass=0
fail=0

ok()   { printf '  ok   %s\n' "$1"; pass=$((pass + 1)); }
bad()  { printf '  FAIL %s\n' "$1"; fail=$((fail + 1)); }

# Capture first, grep second. tag-check exits 1 by design when it finds
# strangers, and under pipefail a `tag-check | grep -q` would inherit that 1.
run_tc() { python3 "$TC" --vault "$VAULT" "$@" 2>/dev/null || true; }

# The tag rows are indented two spaces; note names are indented six. Match the
# tag column only, so a note NAMED like a tag cannot satisfy an assertion.
tag_rows() { printf '%s\n' "$1" | grep -E '^  [^ ]' || true; }

# assert_flagged <tag> [extra args] : the tag must be reported
assert_flagged() {
  local tag="$1"; shift
  if tag_rows "$(run_tc "$@")" | grep -Eq "^  $tag( |\$)"; then
    ok "flagged   $tag"
  else
    bad "flagged   $tag  (expected a stranger, got none)"
  fi
}

# assert_spared <tag> [extra args] : the tag must NOT be reported
assert_spared() {
  local tag="$1"; shift
  if tag_rows "$(run_tc "$@")" | grep -Eq "^  $tag( |\$)"; then
    bad "spared    $tag  (flagged something it should leave alone)"
  else
    ok "spared    $tag"
  fi
}

# note <relpath> : write stdin to that note
note() { mkdir -p "$(dirname "$VAULT/$1")"; cat > "$VAULT/$1"; }

mkdir -p "$VAULT/.obsidian"
cat > "$VAULT/.obsidian/tag-roots.txt" <<'EOF'
# Test list
admin
Projects
#journal
!pride
EOF

echo "== spares tags under an allowed branch =="
note 'a.md' <<'EOF'
---
tags:
  - Admin/hashicorp
  - projects/brand-new-subtag
  - journal
---
Body with #admin/finances/estate and #Projects/Writing in it.
EOF
assert_spared 'admin/hashicorp'
assert_spared 'projects/brand-new-subtag'
assert_spared 'journal'
assert_spared 'admin/finances/estate'
assert_spared 'projects/writing'

echo "== flags a stranger in Properties, in every YAML shape =="
note 'block.md' <<'EOF'
---
tags:
  - blocklisted
  - "quoted-one"
---
x
EOF
note 'flow.md' <<'EOF'
---
title: "Generated"
tags: ["meeting-notes", "terraform", 'drift-detection']
---
x
EOF
note 'wrapped.md' <<'EOF'
---
tags: [wrapped-one,
  wrapped-two]
---
x
EOF
note 'scalar.md' <<'EOF'
---
tags: scalar-one, scalar-two
---
x
EOF
note 'singular.md' <<'EOF'
---
tag: singular-key
---
x
EOF
assert_flagged 'blocklisted'
assert_flagged 'quoted-one'
assert_flagged 'meeting-notes'
assert_flagged 'terraform'
assert_flagged 'drift-detection'
assert_flagged 'wrapped-one'
assert_flagged 'wrapped-two'
assert_flagged 'scalar-one'
assert_flagged 'scalar-two'
assert_flagged 'singular-key'

echo "== a branch covers whole path segments only =="
note 'prefix.md' <<'EOF'
---
tags:
  - administrator
  - projects-old
---
x
EOF
assert_flagged 'administrator'
assert_flagged 'projects-old'

echo "== counts digits the way Obsidian does =="
note 'digits.md' <<'EOF'
---
tags:
  - "557"
---
My #1 priority, see issue #2024 and #3d-print.
EOF
assert_flagged '557'
assert_spared '1'
assert_spared '2024'
assert_flagged '3d-print'

echo "== flags a hashtag in the text =="
note 'inline.md' <<'EOF'
Caption draft #wontbeerased and
#startofline too.
EOF
assert_flagged 'wontbeerased'
assert_flagged 'startofline'

echo "== spares what Obsidian does not treat as a tag =="
note 'nottags.md' <<'EOF'
# Heading
## Another heading
See https://example.com/page#fragment and C#sharp and a#b.
Inline `#incode` here.
```
#infence
```
~~~
#intilde
~~~
EOF
assert_spared 'heading'
assert_spared 'fragment'
assert_spared 'sharp'
assert_spared 'b'
assert_spared 'incode'
assert_spared 'infence'
assert_spared 'intilde'

echo "== follows Markdown's fence rules, not a simple toggle =="
# A line that opens with a fence but carries text cannot CLOSE a block, a ~~~
# line cannot close a ``` block, and a shorter fence cannot close a longer one.
note 'fences.md' <<'EOF'
```text
#stillin-a
```python
#stillin-b
~~~
#stillin-c
```
#afterclose
````
#long-a
```
#long-b
````
#afterlong
A line with ```inline``` fences and #besideinline here.
EOF
assert_spared 'stillin-a'
assert_spared 'stillin-b'
assert_spared 'stillin-c'
assert_flagged 'afterclose'
assert_spared 'long-a'
assert_spared 'long-b'
assert_flagged 'afterlong'
assert_flagged 'besideinline'
# A block that never closes runs to the end of the note.
note 'unclosed.md' <<'EOF'
#beforeopen
```
#neverclosed-a

#neverclosed-b
EOF
assert_flagged 'beforeopen'
assert_spared 'neverclosed-a'
assert_spared 'neverclosed-b'

echo "== spares an ignored tag, and the list file's own comment rule =="
note 'ignored.md' <<'EOF'
Some text #pride and #Pride/2024 here.
EOF
assert_spared 'pride'
assert_spared 'pride/2024'

echo "== skips Obsidian's folders and Bear's trash by default =="
note '.obsidian/backups/old.md' <<'EOF'
---
tags:
  - in-obsidian-dir
---
EOF
note '.trash/gone.md' <<'EOF'
#in-dot-trash
EOF
note 'trash/old.md' <<'EOF'
---
tags:
  - flexport
---
EOF
assert_spared 'in-obsidian-dir'
assert_spared 'in-dot-trash'
assert_spared 'flexport'
assert_flagged 'flexport' --include-trash

echo "== shows where the tag is and which note =="
out="$(run_tc)"
if printf '%s\n' "$out" | grep -Eq '^  terraform +1 note +Properties$'; then
  ok "source    Properties"
else
  bad "source    Properties"
fi
if printf '%s\n' "$out" | grep -Eq '^  wontbeerased +1 note +text$'; then
  ok "source    text"
else
  bad "source    text"
fi
if printf '%s\n' "$out" | grep -Fxq '      flow'; then
  ok "names     the note"
else
  bad "names     the note"
fi

echo "== --allow and --ignore add to the list =="
run_tc --allow '#Terraform' >/dev/null
assert_spared 'terraform'
run_tc --allow terraform/cloud >/dev/null
if [ "$(grep -c '^terraform' "$VAULT/.obsidian/tag-roots.txt")" = "1" ]; then
  ok "allow     no duplicate when already covered"
else
  bad "allow     no duplicate when already covered"
fi
run_tc --ignore wontbeerased >/dev/null
assert_spared 'wontbeerased'
if grep -Fxq '!wontbeerased' "$VAULT/.obsidian/tag-roots.txt"; then
  ok "ignore    written with a leading !"
else
  bad "ignore    written with a leading !"
fi
assert_flagged 'meeting-notes'

echo "== never edits a note =="
before=$(find "$VAULT" -name '*.md' -exec cat {} + | shasum)
run_tc >/dev/null; run_tc --include-trash >/dev/null; run_tc --allow zzz >/dev/null
after=$(find "$VAULT" -name '*.md' -exec cat {} + | shasum)
[ "$before" = "$after" ] && ok "notes     byte-identical after every mode" \
                         || bad "notes     byte-identical after every mode"

echo "== exit codes =="
CLEAN="$TMP/clean"
mkdir -p "$CLEAN/.obsidian"
echo "admin" > "$CLEAN/.obsidian/tag-roots.txt"
printf -- '---\ntags:\n  - admin/x\n---\nfine\n' > "$CLEAN/n.md"
python3 "$TC" --vault "$CLEAN" >/dev/null 2>&1
[ $? -eq 0 ] && ok "exit 0 on a clean vault" || bad "exit 0 on a clean vault"
python3 "$TC" --vault "$VAULT" >/dev/null 2>&1
[ $? -eq 1 ] && ok "exit 1 when strangers exist" || bad "exit 1 when strangers exist"
python3 "$TC" --vault "$TMP/nope" >/dev/null 2>&1
[ $? -eq 2 ] && ok "exit 2 on a missing vault" || bad "exit 2 on a missing vault"
mkdir -p "$TMP/nolist"
python3 "$TC" --vault "$TMP/nolist" >/dev/null 2>&1
[ $? -eq 2 ] && ok "exit 2 when there is no list yet" || bad "exit 2 when there is no list yet"
python3 "$TC" --vault "$TMP/nolist" --allow first >/dev/null 2>&1
[ -f "$TMP/nolist/.obsidian/tag-roots.txt" ] && ok "--allow creates the list" \
                                             || bad "--allow creates the list"

echo
echo "$pass passed, $fail failed"
[ $fail -eq 0 ] || exit 1
