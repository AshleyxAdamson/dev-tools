# dev-tools

The tooling I build to work with, and the history behind it. One source of
truth: the real files live here and the places that use them symlink in, so
there is never a live copy quietly drifting from a repo copy.

## What's in here

| Folder | What it is |
|---|---|
| `pebbl-history/` | All of pebbl's memory — the rescued first two months, and the live store it writes to today. |
| `skills/` | The eight Claude Code skills I authored. |
| `statusline/` | The Claude Code status line I use, with its full history. |
| `bin/` | The daily memory-commit job. |

## Symlinks

Nothing here is copied into place. These paths point at this repo:

```
~/.claude/skills/<name>   ->  dev-tools/skills/<name>      (8 skills)
~/.claude/statusline.sh   ->  dev-tools/statusline/statusline.sh
~/pebbl/.pebbl            ->  dev-tools/pebbl-history/live
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

## pebbl-history

Two complete pebbl stores, not exports, split by era. They are versioned
differently because pebbl treats them differently.

### `live/` — the working store

`~/pebbl/.pebbl` symlinks here, so pebbl writes into this repo as we work.
Only **`events.jsonl`** is tracked: it is the canonical append-only record.
`db.sqlite`, `view.sqlite` and the four markdown projections are derived from
it and gitignored, using the same paths `pebbl init` writes into any project.
That keeps the history one diffable text file instead of a churning binary.

Regenerate anything derived with `pebbl rebuild`.

This store was gitignored inside pebbl itself — **zero tracked files** — so
every decision logged about the tool was unversioned, one disk failure from
gone. That is the same way the entries below were nearly lost.

### `archive-2026-05_2026-07/` — the rescued first two months

125 entries, 2026-05-23 → 2026-07-02, rescued from a stale clone that was
about to be deleted. Legacy-mode with no `events.jsonl`, so here `db.sqlite`
**is** canonical and the markdown is the only readable form — both tracked.
Frozen, so it never churns.

It holds the design rationale for pebbl itself — why the `AGENTS.md` block
uses `<!-- pebbl:begin/end -->` sentinels (header scanning was fragile when a
project had several `##` sections), why `PEBBL.md` is no longer generated in
user projects (its content moved into `pebbl help <topic>`), plus the
storage, search, compaction, rubric and handoff-schema decisions. Only 2 of
the 125 entries mention the archived sw-factory era; the rest is the tool.

`plans/` holds the two v0.2 planning documents from the same period.

Still open: `pebbl search` from `~/pebbl` only covers the live store. Mounting
the archive under `~/pebbl/.pebbl/mirror/` would make all 125 entries
searchable too — `pebbl migrate-to-events` is the lossless on-ramp.

## Staying current

`bin/commit-memory.sh` commits new memory once a day via launchd
(`com.ashley.dev-tools-memory`, 22:00). It runs pebbl's privacy scan first and
refuses to commit unscanned memory if the scan cannot run — a guard that
cannot execute must not look like a guard that passed. It skips entirely if
anything outside `pebbl-history` is dirty, so it never commits over a working
session. Its log is `.git/memory-commit.log`.

Run it by hand any time:

```sh
~/dev-tools/bin/commit-memory.sh
```

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
- **pebbl** — the tool itself is `~/pebbl`, pushed to
  [SkywrightAI/pebbl](https://github.com/SkywrightAI/pebbl). Only its early
  *memory* lives here, not its code.
