# dev-tools

The tooling I build to work with, and the history behind it. One source of
truth: the real files live here and the places that use them symlink in, so
there is never a live copy quietly drifting from a repo copy.

## What's in here

| Folder | What it is |
|---|---|
| `skills/` | The eight Claude Code skills I authored. |
| `statusline/` | The Claude Code status line I use, with its full history. |
| `bin/` | Health checks for this repo's symlinks, the Johnny Decimal name checker, and the Obsidian tag checker. |

## Symlinks

Nothing here is copied into place. These paths point at this repo:

```
~/.claude/skills/<name>   ->  dev-tools/skills/<name>      (8 skills)
~/.claude/statusline.sh   ->  dev-tools/statusline/statusline.sh
```

### Why this repo is at `~/dev-tools`

It looks misfiled — code belongs in `~/Documents/10.Code-Projects`. It isn't. macOS TCC
gives a launchd agent **zero** access to `~/Documents`: reading the directory, reading a
file, and `git status` are all denied. The daily memory commit below could never run from
there. loom, pebbl and digests all sit at the home root for the same reason. Moving this
back under Documents would break the automation silently, which is the worst way for
something to break.

Editing either path edits the same file. That matters more than it sounds:
the alternative is a copy in each location, and a copy has no way to tell you
it went stale. This session started by finding exactly that failure — two
clones of pebbl, one of them the real one, and nobody could tell which by
looking.

## tag-check

`bin/tag-check.py` lists tags in the Obsidian vault that sit outside the allowed
branches. Obsidian trusts any tag it is handed, so an importer or a generator can
fill the tag tree with strangers and nothing says where they came from.

```sh
~/dev-tools/bin/tag-check.py                  # list strangers (exit 1 if any)
~/dev-tools/bin/tag-check.py --allow travel   # a new branch: keep it
~/dev-tools/bin/tag-check.py --ignore pride   # a hashtag in note text: stop flagging it
```

The list holds branches, so `projects` allows `projects/anything` and a new
sub-tag costs nothing. Only a new top-level tag gets flagged. It reports and
never edits a note.

The script lives here; the list lives in the vault at `.obsidian/tag-roots.txt`.
The list names private topics and belongs to the vault, so it stays out of this
repo and moves if the vault moves.

## pebbl's memory moved out

Until 2026-07-30 this repo also held pebbl's memory in `pebbl-history/`, with
`~/pebbl/.pebbl` symlinking into it, plus the daily job that committed it. All
of it now lives in the pebbl repo itself:

| Was here | Now |
|---|---|
| `pebbl-history/live/` | `~/pebbl/.pebbl/` (a real directory, tracked) |
| `pebbl-history/archive-*`, `plans/` | `~/pebbl/memory-archive/` |
| `bin/commit-memory.sh` | `~/pebbl/ops/commit-memory.sh` |
| `bin/check-memory-health.sh` | `~/pebbl/ops/check-memory-health.sh` |
| `bin/test-memory-health.sh` | `~/pebbl/ops/test-memory-health.sh` |
| `com.ashley.dev-tools-memory` | `com.ashley.pebbl-memory` |

Why: a tool and its memory in separate repos means a clone of pebbl arrives with
no memory, and the connection between them was a machine-specific symlink — the
one part of the setup that could not survive this laptop. Moving the store in
also closed the amnesia failure for good: `git check-ignore` does not report
tracked paths, so a tracked `events.jsonl` can no longer be pushed back onto the
`db.sqlite` read path that this store does not keep.

## Not failing silently

`bin/check-dev-tools-health.sh` verifies and repairs what this repo still owns:
the eight skill symlinks, the statusline symlink, and the TCC constraint on where
the repo may live. pebbl's own pipeline has its own check, its own fault-injection
harness, and its own liveness heartbeat — `cd ~/pebbl && bash ops/check-memory-health.sh`.

```sh
~/dev-tools/bin/check-dev-tools-health.sh   # symlinks + location
~/dev-tools/bin/test-jd-check.sh            # the Johnny Decimal checker's own tests
~/dev-tools/bin/test-tag-check.sh           # the Obsidian tag checker's own tests
```

| Silent failure | Caught by |
|---|---|
| skill symlinks broken, Claude loses skills | `symlinks` probe |
| repo moved back under `~/Documents` | `repo-location` probe |

## skills

| Skill | What it does |
|---|---|
| `activity-check` | Mac activity diagnostic — CPU, memory pressure, swap, sleep preventers |
| `anti-ai-prose` | Makes writing sound like me instead of like AI. `RULES.md` is the canonical list; `anti_ai_checker.py` validates |
| `design-spike` | Fans out several distinct UI directions as openable HTML mockups on real data, critiques them adversarially (scored, attacked, not praised), then recommends a base plus grafts |
| `flare-strategy` | Consultant on FLARE forward-looking active-retrieval strategy for an agent, and generates the prompt scaffold |
| `loom-refine` | Self-paced loop that refines the loom factory itself |
| `loom-work` | Works the loom queue as an interactive line worker |
| `research-planner` | Six-phase research protocol — find the hinge, red-team the plan, tier the subagents, grade the evidence |
| `skill-builder` | Builds a new skill, or audits and shrinks an existing one |

Deliberately **not** here: the open-design pack (`design-craft`,
`design-review`, `frontend-design`, `shadcn-ui`, `theme-factory`,
`ui-skills`, `web-design-guidelines`) is vendored from
[nexu-io/open-design](https://github.com/nexu-io/open-design);
`agent-deck` and `session-share` ship with
[agent-deck](https://github.com/asheshgoplani/agent-deck);
`make-pages-interactive` is
[paraschopra's](https://github.com/paraschopra/make-pages-interactive); and
`bookforge` is a symlink into lumr. Those belong to their upstreams — copying
them here would fork them by accident.

## Related, deliberately elsewhere

- **Loom UI** — `~/loom/floor/loom-tui`. Stays in loom, versioned alongside
  the factory it drives. Pulling it here would either cut its history out of
  loom or leave two copies.
- **claude-theme** — its own repo in `10.Code-Projects`. Generates terminal
  themes; fold it in here if it ever needs to be.
- **pebbl** — `~/pebbl`, pushed to
  [SkywrightAI/pebbl](https://github.com/SkywrightAI/pebbl). Both its code and
  its memory live there now; see the table above.
