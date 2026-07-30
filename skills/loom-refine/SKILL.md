---
name: loom-refine
description: Continuously refine the loom factory itself — a self-paced terminal loop that drains the queue (build → cross-family review → promote), discovers + fixes new friction when idle, parks protected/sensitive work for Ashley, and only surfaces when it's out of problems or needs a decision. Manually invoked; keeps going via ScheduleWakeup.
disable-model-invocation: true
---

You are running the **loom self-refinement loop** INSIDE an interactive Claude
Code session on Ashley's subscription (NOT headless — you and your fresh-context
subagents do the work in real git worktrees, so loom's own code actually changes).
This is the "self-healing factory" done the right way: a live terminal loop, not
a launchd daemon. `loom tick` builds greenfield in a throwaway temp dir and can't
edit the repo — so this loop NEVER relies on it for repo fixes.

The loom CLI is `~/loom` — run it with
`cd ~/loom && LOOM_MEMORY_STORE=~/loom deno run -A src/interface/cli.ts <cmd>`.
`$ARGUMENTS` (optional) is a focus hint (e.g. a repo, an area, "just drain"); blank
= full self-refine.

## One iteration (do exactly one, then pace the next)

1. **HEALTH** — `loom doctor`. A stale claim/lease → `loom reap`. A real infra
   FAIL you can't reap → surface to Ashley, don't paper over it.

2. **PULL** — `loom next`.
   - Hands you `<id> <goal>` → **BUILD IT** via the loom-work cycle (see below).
   - "drained — nothing to build" → **DISCOVER** (see below).

3. **BUILD (queued task)** — the exact loom-work guardrails apply; if unsure, read
   `~/.claude/skills/loom-work/SKILL.md` (don't duplicate its rules, honor them):
   claim is already held by `next`; make a git worktree off the target repo's main
   (`git worktree add -b loom/<id> /tmp/loom-<id> main`); delegate the build to a
   FRESH-CONTEXT SUBAGENT (hard guardrail — minimal correct code PLUS a runnable
   test, stay in the worktree); `loom review <id> <workdir> <test…>` (cross-family
   gate; FAIL → feed the verdict to a fresh fix subagent, re-review; **park after 2
   fix rounds**); on PASS `git commit` then `loom promote loom/<id> main --repo
   <path> --task <id>` (repo profiles auto-pick the gate). Remove the worktree.
   - **SENSITIVE repo** (`loom review` says SENSITIVE) → review with a fresh Claude
     subagent (Anthropic, never the external GLM), land with `loom land`.
   - **PROTECTED path** (config.ts / guard.ts / hooks) or **sensitive** → the guard
     blocks auto-land: commit the built+reviewed work to its branch, then **PARK**
     with a clear note that it awaits Ashley's approval + the exact `loom promote`
     line. Never auto-land protected/sensitive work.

4. **DISCOVER (queue drained)** — probe for ONE real problem, then `loom add` it
   (declare an `--area`) and build it via step 3. Probe order:
   - `deno task gate` / `loom doctor` — a real failure or gap.
   - Dogfood a bounded self-heal pass and read `~/loom/ops/self-heal.log` for friction.
   - The next open item in `~/loom/ops/loop-engineering-audit.md` (skip ones already
     landed; cross-check the run log).
   Pick real friction/bugs over speculative features. If a probe genuinely finds
   NOTHING and the queue is drained → the factory is clean (see Pacing → stop).

## The guardrails (never bend)

Fresh-context SUBAGENT builds · cross-family adversarial review with a recorded
verdict · park after 2 fix rounds · claim before build (`loom next`/`loom claim`
hold the atomic lock + area lane) · isolated worktrees, never `git add -A` in the
shared `~/loom` tree · land via `loom promote` (or `loom land` for sensitive).
Protected/sensitive/spend/infra-go-live → Ashley decides, you don't.

## Pacing (self-paced — you decide)

Do NOT stop to report each fix. After each iteration, as the LAST action of the
turn, call **ScheduleWakeup** with `prompt: "/loom-refine"` (re-enters this skill),
`delaySeconds` ~1200 (steady refinement without hammering the session), and a one-
line `reason`. Only DEVIATE to surface to Ashley when:
- **Clean** — a full probe finds no problems AND the queue is drained → send a
  one-line `PushNotification` ("loom clean — queue drained, gate green, nothing to
  fix"), then STOP (omit ScheduleWakeup).
- **Needs her** — a protected-path/sensitive build is parked awaiting approval, or
  a spend/infra decision is required → surface it plainly with the exact command she
  runs, then continue the loop (schedule the next wake) unless she must unblock first.

Keep Ashley's anti-AI voice. One idea per chunk, lead with the noun/verb, no windup.
