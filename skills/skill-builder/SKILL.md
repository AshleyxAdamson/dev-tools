---
name: skill-builder
description: Build a new Claude skill, or audit and shrink an existing one, against Matt Pocock's "great skills" rubric — trigger, structure, steering, pruning. Use when the user says "build a skill", "write a skill", "make a skill", "improve/audit this skill", "is this a good skill", "de-slop this skill", or "skill-builder".
---

# Skill Builder

Build skills that are **small, predictable, and do what they say**. A skill is a folder with a `SKILL.md` (the meat) plus any reference files it points to. Source: Matt Pocock, *"The Missing Manual: How to Write Great Skills"* (aihero.dev, `mattpocock/skills`).

The whole job comes down to four passes: **trigger → structure → steering → pruning**. Read `checklist.md` for the full rubric and vocabulary before you start.

Two branches. Pick one:

- **Create** a skill from scratch → do Step 0, then **Create**.
- **Audit** an existing skill and make it smaller/sharper → do **Audit**.

---

## Step 0 — Trigger: user-invoked or model-invoked?

Decide who fires the skill. Neither option is free; both carry a cost.

- **Model-invoked** — the `description` lands in the agent's context every session. The agent decides when to load the skill. Cost: **context load** (tokens on every request + one more thing for the agent to weigh) and **unpredictability** (the agent may skip it even when it fits perfectly). Pick this when the agent should reach for it mid-task on its own.
- **User-invoked** — the user calls it deliberately (`/name`). To hide it from the agent, set the harness's disable-model-invocation flag so the description shows only to the user. Cost: **cognitive load** on the user (they have to remember it exists and when to use it). Pick this for deliberate, high-control tools.

**Default:** if the user will always invoke it on purpose, prefer user-invoked (less context load, no misfires). If the agent should auto-fire it, make it model-invoked and write a razor-sharp `description` so it triggers at the right time and only then.

---

## Create

1. **Name the gap in one sentence.** What should the agent do reliably *after* this skill loads that it can't now? If you can't name the gap, you don't have a skill yet.
2. **Trigger.** Do Step 0.
3. **Split into steps and reference.** Skills are made of two units: **steps** (the procedure to walk through) and **reference** (supporting material the steps need). List the steps. For each, list the reference it needs. A skill can be all steps, all reference, or both.
4. **Find the branches.** A branch is a distinct way the skill gets used. Reference material used in *only one* branch is a candidate to move out of `SKILL.md` and **behind a context pointer** — a one-line "if you need X, read `x.md`" pointing at a sibling file. Keep `SKILL.md` for what every branch needs.
5. **Write `SKILL.md` from `template.md`.** Keep it as small as possible. Every word is a token paid on every use; small skills are easier to maintain, audit, and trust.
6. **Add leading words.** Pick short, meaning-dense phrases (e.g. "vertical slice") and repeat them through the skill instead of long explanations. The agent echoes them in its reasoning and changes behavior. Verify by watching the reasoning traces adopt your word.
7. **Check legwork.** If one step needs deep effort and the agent rushes it to reach the final goal (classic: "ask clarifying questions" before "make a plan"), split that step into its **own** skill so the agent sees one step at a time. Hiding the future goal forces legwork on the current one.
8. **Prune.** Run the pruning pass from `checklist.md`: single source of truth (no duplication), no sediment, no no-ops (apply the deletion test to every paragraph).

## Audit

1. **Read the target skill** — `SKILL.md` and every file it points to.
2. **Run the rubric** in `checklist.md` section by section: trigger, structure, steering, pruning. Mark each check pass/fail with the specific line.
3. **Report, then fix.** Give the findings as a short list (what's wrong / why / the fix). Apply the fixes, or propose them if the user wants to review first. Bias toward deletion — the win is almost always a *smaller* skill.

---

Match the host repo's conventions when you write (frontmatter shape, file layout, `description` phrasing). On Ashley's machine skills live at `~/.claude/skills/<name>/SKILL.md` with `name` + `description` frontmatter and reference files as siblings.
