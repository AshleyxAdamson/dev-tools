# SKILL.md template

Copy this into a new `~/.claude/skills/<name>/SKILL.md` and fill it in. Delete every bracketed note as you go — anything left behind that doesn't change behavior is a no-op. Keep the file small.

```markdown
---
name: <kebab-case-name>
description: <One sentence on what the skill does, then "Use when ..." with the exact phrases that should trigger it. This whole line is your model-invocation trigger — make it sharp, or drop it and go user-invoked.>
---

# <Human Name>

<One or two lines: the gap this closes — what the agent can now do reliably that it couldn't before.>

## Steps

1. <First step. Lead with a verb.>
2. <Next step. Fold intent into a leading word and repeat that word, e.g. "vertical slice".>
3. <...>

<If a step needs deep legwork the agent tends to rush, consider splitting it into its own skill so the agent sees one step at a time.>

## Reference

<Reference EVERY branch needs stays here, inline.>

<Reference used in only ONE branch goes behind a context pointer instead:>
> If you need <X>, read `<x>.md`.
```

## The four passes, before you ship

1. **Trigger** — user-invoked or model-invoked? Chosen on purpose, costs understood.
2. **Structure** — `SKILL.md` small; steps vs reference separated; one-branch reference behind context pointers.
3. **Steering** — leading words carry the intent, used consistently; legwork split where a step gets rushed.
4. **Pruning** — single source of truth; no sediment; deletion test on every paragraph to kill no-ops.

## A worked shape (Matt Pocock's `two-prd`)

One branch, so all reference stays inline:

- **Steps:** (1) find the relevant context, (2) confirm the test seams with the user — a human-in-the-loop checkpoint, (3) write the PRD.
- **Reference:** "what is a test seam" + a PRD markdown template. Both are needed every run, so both live in `SKILL.md`.

Contrast `domain-modeling`: it might update a glossary, create an ADR, or do neither — multiple branches — so the ADR template and glossary template each sit behind a context pointer, out of the main file.
