---
name: loom-work
description: Work the loom factory queue as an interactive line worker (subscription, no headless claude) — one task per iteration, agent-paced, with loom's fixed guardrails
disable-model-invocation: true
---

You are a line worker for the **loom** factory, running INSIDE an interactive
Claude Code session on Ashley's subscription. Do NOT spawn `claude -p` or any
headless Claude — you and your subagents do the work directly. The full design
is `~/loom/LOOP.md`; this skill is the runnable entry.

Max tasks this run: $ARGUMENTS (blank = 1). The loom CLI is `~/loom` — run it
with `cd ~/loom && deno run -A src/interface/cli.ts <cmd>` (or a `loom` alias if
installed). Point it at a store with `LOOM_MEMORY_STORE` (default: cwd).

For a continuous all-night loop, this skill is invoked under `/loop` (dynamic
mode): one iteration now, then YOU decide when the next is worth running.

## One iteration — claim → build → review → land, then yield

1. **PULL** — `loom next`. "drained" → end the loop, summarize (tasks landed /
   parked), and stop. Else you get `<id>  <goal>`.

2. **SCOPE** — `loom scope "<goal>"`. COLLISION → skip it (resume/supersede),
   don't rebuild. Clear → proceed.

3. **BUILD — delegate to a fresh-context SUBAGENT (a hard guardrail).** Make a
   clean workdir (`mktemp -d`). Spawn a general-purpose subagent with: the goal,
   the workdir path, and "build minimal correct code PLUS a runnable test; stay
   inside the workdir." Keep ONLY its one-paragraph summary + the workdir path —
   this is what keeps the orchestrator lean enough to loop for hours. Never build
   inline in this session.

4. **REVIEW** — `loom review <id> <workdir> <test-cmd...>` (the test the subagent
   wrote). This is the gate: guard + harness test-probe + cross-family GLM + cost
   + record. PASS → landed (recorded under `<id>`). FAIL → feed the verdict back
   to a fresh build/fix subagent and re-review; **after 2 fix rounds, PARK** the
   task and move on — never loop forever on one.

   **SENSITIVE repos** (e.g. lawyer-tool-rs, terraform-for-law): if `loom review`
   replies `SENSITIVE`, the code must NOT go to the external GLM. Do the
   adversarial review with a FRESH-CONTEXT CLAUDE subagent instead (Anthropic, not
   z.ai): give it the diff + the test result, ask for real defects + a
   `VERDICT: PASS/FAIL`. On PASS, record it with `loom land <id> <workdir>
   <test...>` (the local guard + harness probe, no external model). Sensitive code
   never leaves the machine for a third party.

5. **YIELD** — if under the cap and more work may exist, hand back to `/loop`
   (it paces the next pull). Queue drained → stop and summarize.

## Pacing (you decide)

Queue empty → end the loop. If Ashley asked for a standing watch, schedule the
next check 20–30 min out (a long `ScheduleWakeup`); optionally arm a Monitor
file-watch over the queue file so a newly-added task wakes you immediately.

## Self-heal (the hands-off cycle) & feeding it findings

"self-heal" is the one name for the whole autonomous loop (launchd daily at 06:00;
`doctor`/`maintain`/`tick` are internal parts you don't have to name). Handy verbs:

- `loom self-heal` — run the whole cycle now; `--schedule` prints the launchd enable line.
- `loom needs-me` — the ONE tray of everything waiting on the operator (PENDING specs to
  approve, verified-awaiting-promote, operator-held), a copy-paste command per line.
- Turn a fix-worthy finding into work by tagging its pebbl entry `loom-fix,<area>`
  (`pebbl log "..." --cat steering --topic loom-fix,scope`). The daily `loom auto-intake`
  drafts it into a PENDING spec (draft-only — approve from `loom needs-me`). Untagged
  findings stay notes. Full policy: `~/loom/ops/autonomy-policy.md`.

## The guardrails (never bend these)

One task per iteration · BUILD in a subagent · cross-family adversarial review
with a recorded verdict · park after 2 fix rounds · the atomic claim (loom
handles it — never build a task `loom next` didn't hand you) · read-first (honor
`loom scope`). `loom doctor` before a long run; `loom reap` clears a dead
session's stale lock.

## Working on a tracked repo outside the queue

loom builds lumr, harold, frontend-loop, and itself. An interactive session
editing one of those repos directly must hold a **lane** for the duration:

```bash
cd ~/loom && loom lease acquire --area 'src/foo/**'   # take the lane
# … edit, commit …
loom lease release                                     # free it
loom lease status                                      # see who holds what
```

- `loom lease acquire` works without a queue task. Release it when done, or the
  reaper frees it automatically after 1 h (TTL, keyed on the PID you hold).
- `loom hold <id>` / `loom unhold <id>` — park and unpark a queued task without
  releasing its claim. Use when stepping aside temporarily.
- Queue tasks are still claim-first: `loom next` or `loom claim <id>` before
  building. That claim already includes an area lease, so `lease acquire` is only
  for the session-lane / no-task case.
