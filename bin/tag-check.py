#!/usr/bin/env python3
"""Report tags in the Obsidian vault that sit outside the allowed branches.

Why this exists: Obsidian trusts any tag it is handed. The Bear importer filed
"#1" as a tag, and a notes-synthesis tool wrote fourteen of its own into one
note's Properties. Both showed up as clutter in the tag tree with nothing to
say where they came from.

The list holds BRANCHES, not every tag. `projects` allows projects/anything, so
a new sub-tag costs nothing. Only a new top-level tag is a stranger, and that is
where every piece of junk so far has landed.

Report only, on purpose. Nothing here edits a note. A tag made on purpose
yesterday must not vanish because nobody added it to a list, so the two answers
to a stranger are both one command and both additive:

    --allow  <tag>   it is a new branch, keep it (everything under it passes)
    --ignore <tag>   it is a hashtag in note text, leave it and stop flagging it

A tag counts the way Obsidian counts it: anything in the Properties `tags` list,
plus any #hashtag in the body that has at least one non-digit character. Code
blocks and inline code are skipped because Obsidian skips them. A checker that
flags what the app does not show teaches you to ignore the checker.

The list lives in the vault (.obsidian/tag-roots.txt), not in this repo. The
script is the mechanism and travels with dev-tools; the list is the vault's own
policy, names private topics, and should move if the vault moves.

Usage:
    tag-check.py                     scan the vault, list strangers
    tag-check.py --allow travel      add a branch to the list
    tag-check.py --ignore pride      stop flagging a known hashtag
    tag-check.py --include-trash     also scan trash/ (Bear's trashed notes)
    tag-check.py --vault PATH        a different vault ($OBSIDIAN_VAULT also works)

Exit: 0 clean, 1 strangers found, 2 bad usage or no list yet.
"""

import argparse
import os
import re
import sys
from collections import defaultdict

DEFAULT_VAULT = os.path.expanduser(
    "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Main"
)
LIST_RELPATH = os.path.join(".obsidian", "tag-roots.txt")

# Never scanned: Obsidian's own config and its deleted-files folder.
SKIP_DIRS = {".obsidian", ".trash"}
# Bear's trashed notes came across as a real folder. The navigator hides it, so
# its tags are not in the tree and flagging them would be noise. --include-trash
# brings it back.
TRASH_DIR = "trash"

LIST_HEADER = """\
# Tag branches allowed in this vault. One per line.
# A branch covers everything under it: `projects` allows projects/anything.
# Lines starting with ! are known hashtags in note text to leave alone.
# Managed by ~/dev-tools/bin/tag-check.py (--allow, --ignore). Hand edits are fine.
"""

# Same character set Obsidian accepts in a tag. The # must start a line or
# follow whitespace, which is what keeps URL fragments and "C#" out.
INLINE_TAG = re.compile(r"(?:(?<=\s)|^)#([A-Za-z0-9_\-/À-￿]+)")
INLINE_CODE = re.compile(r"`[^`\n]*`")
FENCE = re.compile(r"^\s*(`{3,}|~{3,})(.*)$")
TAGS_KEY = re.compile(r"^(tags?)\s*:(.*)$", re.IGNORECASE)
LIST_ITEM = re.compile(r"^\s*-\s*(.*)$")


def normalize(tag):
    """Strip the decoration a tag can arrive with; compare lowercase."""
    return tag.strip().strip("'\"").lstrip("#").strip("/").lower()


def under(tag, branch):
    """True when tag IS the branch or sits below it. Matches whole path
    segments, so `admin` covers admin/x and does not cover administrator."""
    return tag == branch or tag.startswith(branch + "/")


def split_frontmatter(text):
    """Return (frontmatter lines, body). Obsidian only reads Properties when
    the very first line is ---."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return [], text
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], "\n".join(lines[i + 1:])
    return [], text


def property_tags(fm_lines):
    """Tags from the Properties block, in every shape YAML allows them:
    a block list, a flow list like [a, b], or a bare scalar. The flow list is
    the one a generator writes, and missing it is how fourteen tags once went
    unseen."""
    found = []
    i = 0
    while i < len(fm_lines):
        m = TAGS_KEY.match(fm_lines[i])
        if not m:
            i += 1
            continue
        rest = m.group(2).strip()
        if rest.startswith("["):
            # A flow list may wrap across lines; read until it closes.
            while "]" not in rest and i + 1 < len(fm_lines):
                i += 1
                rest += " " + fm_lines[i].strip()
            found += rest.strip("[]").split(",")
        elif rest:
            found += re.split(r"[,\s]+", rest)
        else:
            while i + 1 < len(fm_lines):
                item = LIST_ITEM.match(fm_lines[i + 1])
                if not item:
                    break
                found.append(item.group(1))
                i += 1
        i += 1
    return [t for t in (normalize(t) for t in found) if t]


def inline_tags(body):
    """#hashtags in the note text, skipping fenced and inline code.

    Fences follow the Markdown rule, not a simple toggle: a block closes only
    on a bare line of the SAME character at least as long as the one that
    opened it, and a block that never closes runs to the end of the note.
    Caption drafts kept in code blocks are full of hashtags, and a toggle
    that miscounts one fence would report every one of them."""
    found = []
    fence = None  # (character, length) while inside a fenced block
    for line in body.split("\n"):
        m = FENCE.match(line)
        if fence is None:
            # A backtick fence cannot have a backtick in its info string;
            # that shape is inline code, not the start of a block.
            if m and not (m.group(1)[0] == "`" and "`" in m.group(2)):
                fence = (m.group(1)[0], len(m.group(1)))
                continue
        else:
            if (m and m.group(1)[0] == fence[0]
                    and len(m.group(1)) >= fence[1] and not m.group(2).strip()):
                fence = None
            continue
        for raw in INLINE_TAG.findall(INLINE_CODE.sub("", line)):
            tag = normalize(raw)
            # Obsidian ignores a hashtag made only of digits (#1, #2024).
            if tag and not re.fullmatch(r"[\d/]+", tag):
                found.append(tag)
    return found


def read_list(path):
    """Return (allowed branches, ignored tags). `# comment` is a comment;
    `#travel` is the tag travel, the same rule Obsidian uses for headings."""
    allowed, ignored = [], []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line == "#" or line.startswith("# "):
                continue
            if line.startswith("!"):
                tag = normalize(line[1:])
                if tag:
                    ignored.append(tag)
            else:
                tag = normalize(line)
                if tag:
                    allowed.append(tag)
    return allowed, ignored


def add_to_list(path, tag, ignore):
    tag = normalize(tag)
    if not tag:
        print("tag-check: empty tag", file=sys.stderr)
        return 2
    allowed, ignored = read_list(path) if os.path.exists(path) else ([], [])
    covered_by = next((b for b in (ignored if ignore else allowed) if under(tag, b)), None)
    if covered_by:
        print(f"Already {'ignored' if ignore else 'allowed'}: {tag} (covered by {covered_by})")
        return 0
    if not os.path.exists(path):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(LIST_HEADER)
    with open(path, "a", encoding="utf-8") as f:
        f.write(("!" if ignore else "") + tag + "\n")
    if ignore:
        print(f"Ignoring: {tag}")
    else:
        print(f"Allowed: {tag} (and everything under it)")
    return 0


def scan(vault, include_trash):
    """Return (notes scanned, {tag: {"props": set(notes), "text": set(notes)}})."""
    skip = set(SKIP_DIRS)
    if not include_trash:
        skip.add(TRASH_DIR)
    seen = defaultdict(lambda: {"props": set(), "text": set()})
    notes = 0
    for root, dirs, files in os.walk(vault):
        dirs[:] = [d for d in dirs if d not in skip]
        for name in files:
            if not name.endswith(".md"):
                continue
            notes += 1
            path = os.path.join(root, name)
            with open(path, encoding="utf-8", errors="replace") as f:
                fm_lines, body = split_frontmatter(f.read())
            note = os.path.relpath(path, vault)[:-3]
            for tag in property_tags(fm_lines):
                seen[tag]["props"].add(note)
            for tag in inline_tags(body):
                seen[tag]["text"].add(note)
    return notes, seen


def main():
    ap = argparse.ArgumentParser(
        description="Report Obsidian tags outside the allowed branches.",
        epilog="Exit: 0 clean, 1 strangers found, 2 bad usage or no list yet.",
    )
    ap.add_argument("--vault", default=os.environ.get("OBSIDIAN_VAULT", DEFAULT_VAULT))
    ap.add_argument("--allow", metavar="TAG", help="add a branch to the list")
    ap.add_argument("--ignore", metavar="TAG", help="stop flagging a known hashtag")
    ap.add_argument("--include-trash", action="store_true", help="also scan trash/")
    args = ap.parse_args()

    if not os.path.isdir(args.vault):
        print(f"tag-check: no such vault: {args.vault}", file=sys.stderr)
        return 2
    list_path = os.path.join(args.vault, LIST_RELPATH)

    if args.allow and args.ignore:
        print("tag-check: use --allow or --ignore, one at a time", file=sys.stderr)
        return 2
    if args.allow:
        return add_to_list(list_path, args.allow, ignore=False)
    if args.ignore:
        return add_to_list(list_path, args.ignore, ignore=True)

    if not os.path.exists(list_path):
        print(f"tag-check: no tag list yet at {list_path}", file=sys.stderr)
        print("Start one with: tag-check.py --allow <your-top-level-tag>", file=sys.stderr)
        return 2
    allowed, ignored = read_list(list_path)

    notes, seen = scan(args.vault, args.include_trash)
    strangers = {
        tag: where
        for tag, where in seen.items()
        if not any(under(tag, b) for b in allowed)
        and not any(under(tag, b) for b in ignored)
    }

    if not strangers:
        print(f"Tags clean. {notes} notes scanned, "
              f"{len(allowed)} branches allowed, {len(ignored)} ignored.")
        return 0

    flagged_notes = set()
    for where in strangers.values():
        flagged_notes |= where["props"] | where["text"]
    print(f"NOT IN YOUR TAG LIST ({len(strangers)} tags in {len(flagged_notes)} notes):")
    width = max(len(t) for t in strangers)
    ordered = sorted(strangers.items(),
                     key=lambda kv: (-len(kv[1]["props"] | kv[1]["text"]), kv[0]))
    for tag, where in ordered:
        in_notes = sorted(where["props"] | where["text"])
        if where["props"] and where["text"]:
            source = "Properties + text"
        elif where["props"]:
            source = "Properties"
        else:
            source = "text"
        count = f"{len(in_notes)} note{'' if len(in_notes) == 1 else 's'}"
        print(f"  {tag.ljust(width)}  {count:>9}  {source}")
        # Note names go on their own indented lines so the tag rows stay scannable.
        for note in in_notes[:3]:
            print(f"      {note}")
        if len(in_notes) > 3:
            print(f"      +{len(in_notes) - 3} more")
    print()
    print("Keep one:   tag-check.py --allow <tag>    a new branch; everything under it passes")
    print("Leave one:  tag-check.py --ignore <tag>   a hashtag in your text, stop flagging it")
    print("Junk in Properties: delete it from the note's tags.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
