# dev-tools

The tooling I build to work with, and the history behind it. One source of
truth: the real files live here and the places that use them symlink in, so
there is never a live copy quietly drifting from a repo copy.

## What's in here

| Folder | What it is |
|---|---|
| `pebbl-history/` | The pebbl project's memory store from its first two months (125 entries, 2026-05-23 → 2026-07-02). Rescued from a stale clone that was about to be deleted. |
| `skills/` | The eight Claude Code skills I authored. |
| `statusline/` | The Claude Code status line I use, with its full history. |

## Symlinks

Nothing here is copied into place. These paths point at this repo:

```
~/.claude/skills/<name>   ->  dev-tools/skills/<name>      (8 skills)
~/.claude/statusline.sh   ->  dev-tools/statusline/statusline.sh
```

Editing either path edits the same file. That matters more than it sounds:
the alternative is a copy in each location, and a copy has no way to tell you
it went stale. This session started by finding exactly that failure — two
clones of pebbl, one of them the real one, and nobody could tell which by
looking.

## pebbl-history

`store/` is a complete pebbl store, not an export. `store/manual-logs.md` is
the human-readable projection; `store/db.sqlite` is the source of truth. To
browse it live:

```sh
cd pebbl-history && pebbl context        # reads store/ if renamed to .pebbl
```

It holds the design rationale for pebbl itself — why the `AGENTS.md` block
uses `<!-- pebbl:begin/end -->` sentinels (header scanning was fragile when a
project had several `##` sections), why `PEBBL.md` is no longer generated in
user projects (its content moved into `pebbl help <topic>`), plus the
storage, search, compaction, rubric and handoff-schema decisions. Only 2 of
the 125 entries mention the archived sw-factory era; the rest is the tool.

`plans/` holds the two v0.2 planning documents from the same period.

Still open: mounting this store under `~/pebbl/.pebbl/mirror/` would make all
125 entries searchable from the live store rather than only archived here.
`pebbl migrate-to-events` is the lossless on-ramp for it.

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
