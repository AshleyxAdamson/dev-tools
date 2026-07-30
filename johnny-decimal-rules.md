# Johnny Decimal Naming Convention

The one rule set for organizing files and folders across Ashley's machine.
Canonical copy lives here in `dev-tools` (version-controlled). `~/.claude/CLAUDE.md`
points at it, so every Claude Code session in every repo applies it.

Check compliance with `dev-tools/bin/jd-check.sh`.

## Part 1 — The structure

Three levels, in this order:

```
Area (10-19, 20-29, …) ─► Category (11, 12, 13, …) ─► ID (11.01, 11.02, …)
```

- **Areas** group related categories. Ranges like `10-19`, `20-29`, up to `90-99`. Max 10 areas.
- **Categories** are two-digit numbers inside an area. `10-19` contains `11`, `12`, … `19`. Max 10 per area.
- **IDs** are a category number plus a two-digit suffix: `11.01`, `11.02`. Max 99 per category.

### Naming format

```
NN[.NN] Title In Sentence Case
```

Examples: `12 Taxes`, `12.04 German tax correspondence`

Rules:
1. Number first, then a single space, then the title.
2. Titles use sentence case. No underscores or hyphens as word separators — use real spaces.
3. Keep titles short. Aim for 2-5 words.
4. Never reuse a number. Once `12.04` is assigned it stays that thing forever, even if archived.
5. Never reorganize by renumbering. If something stops fitting, archive it and create a new ID.

### Known deviation, deliberately kept

On disk the top-level areas are `10.Code-Projects`, `20.Claude-Docs`, `30.Media`, not
`10-19 Code projects`. That predates this doc and renumbering it would violate rule 5.
Treat the on-disk form as correct for areas. Categories and IDs below them use the
standard `NN Title` / `NN.NN Title` form (`20.Claude-Docs/21 Research & reports/21.06 …`).

### What goes inside an ID

An ID folder holds everything about that one thing. Loose files inside need no numeric
prefix — the ID folder itself is the unit of organization.

## Part 2 — Docs inside code repos

This is where the convention used to stop, and why repo docs drifted.

### The library rule

Think of a library. Spine labels go on the books people browse. The front door, the fire
exit sign, and the card catalog keep their fixed names because the building's systems
depend on them. Rename the fire exit to "14.02" and people die.

A repo works the same way. Two kinds of `.md`:

**Fixed-name files — never take a JD number.** Something other than a human reads these
by exact path, so renaming breaks it:

| File | Who reads it by name |
|---|---|
| `README.md` | GitHub, npm, crates.io, every code host |
| `AGENTS.md`, `CLAUDE.md` | Claude Code, agent harnesses |
| `SKILL.md` | the Claude Code skill loader |
| `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` | GitHub UI |
| `CHANGELOG.md` | release tooling, convention |
| `LICENSE.md` | license detectors |
| `docs/index.md`, `SUMMARY.md`, `_sidebar.md` | doc site generators |
| anything under `prompts/`, `workflows/`, `.claude/` | **application code loads these by path** |

That last row is the one that bites. `Terraform-for-Law/prompts/01-extract-clauses.md` and
`lumr/bookforge/bookforge/workflows/draft.md` look like docs and are program inputs. They
are already numbered in a pipeline sequence, which is not JD and must not be "corrected."

**Knowledge docs — these get JD numbers.** Spikes, research, plans, specs, handoffs,
runbooks, design notes. Written for a human, read by a human, and the kind that sprawls.

### Scope of enforcement

| Scope | Rule | Enforced by |
|---|---|---|
| `docs/**/*.md` | must be JD-named | hard: `loom` review guard + `jd-check` |
| `plans/`, `ops/`, `notes/`, `research/` | should be JD-named | advisory: `jd-check --all` reports, nothing blocks |
| everything else | no rule | — |

Enforcement is deliberately narrow. A hard gate that is sometimes wrong teaches you to
bypass it, and a bypassed gate protects nothing. So the block only covers `docs/`, where
the answer is never ambiguous. The broader sweep reports and lets a human judge.

Per-directory `README.md` (`loom/src/capabilities/README.md`) is exempt everywhere.

### The shared category spine

Every repo's `docs/` reuses the **same** category numbers for the same *kind* of doc. `14`
means research in every repo, forever.

| # | Category | Holds |
|---|---|---|
| `11` | Spike findings | what a spike learned |
| `12` | Spike results | measured output of a spike |
| `13` | Plans | spike plans, build plans, task briefs |
| `14` | Research | landscape scans, ecosystem surveys, prior art |
| `15` | Specs & PRDs | what to build, acceptance criteria |
| `16` | Handoffs | state at a session/context boundary |
| `17` | Runbooks & ops | how to operate the thing in production |
| `18` | Design notes | UX and architecture reasoning |
| `19` | *(free)* | a repo-specific kind that fits nothing above |

Nine assigned, `19` held open, which respects the 10-per-area ceiling.

The spine was derived from `jig/docs/`, the first repo to use JD properly. Its existing
`11`-`16` numbers are unchanged on purpose (rule 5).

### Why one spine instead of one area per repo

The tempting alternative is giving each repo its own area: loom `30-39`, lumr `40-49`, and
so on. It dies immediately. JD allows 10 areas total and there are 24 projects in
`10.Code-Projects`.

So the repo path is the disambiguator instead. `lumr/docs/14.02` and `jig/docs/14.02` are
different documents and coexist fine, the same way two libraries can both shelve a book at
the same Dewey number. Numbers are unique *within a repo's* `docs/`, not machine-wide.

One upside: the taxonomy is learned once and transfers. Opening an unfamiliar repo, `15.xx`
is the spec without reading a single filename.

## Part 3 — Assigning something new

1. Identify the **area**. If none fit, propose a new one.
2. Identify the **category**. For repo docs, use the spine above. Elsewhere, next available.
3. Assign the next free **ID** suffix in that category (`.01`, `.02`, …).
4. Return the full path.

```
lumr/docs/
  └── 15.01 Three-pass pipeline spec.md
```

## Part 4 — When in doubt

- Prefer fewer, broader categories over many narrow ones.
- If two things could share a category, they probably should.
- Never create an ID that could plausibly sit in two categories. Pick one and commit.
- If a category passes ~20 IDs, split it before adding more.
- Unsure whether a file is a knowledge doc or a program input? Grep for its filename in the
  repo's source. A hit means it is a program input. Leave it alone.

## Part 5 — Avoid

- Nesting past three levels (no numbered sub-folders inside an ID).
- Decimals past two digits (`12.04.01` is invalid).
- Skipping the number prefix on an area, category, or ID.
- Treating numbers as ordering hints. They are identifiers, not priorities.
- Renaming a fixed-name file from the Part 2 table. Ever.
- Date-suffixed filenames as an organizing scheme (`factory-rewrite-blueprint-2026-06-23.md`).
  The date belongs in git history or inside the doc, not in the name.
