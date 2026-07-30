---
name: research-planner
description: Run a rigorous multi-phase research protocol - find the hinge, red-team the plan, tier subagents, verify every citation with fresh agents, ship an evidence-graded report.
disable-model-invocation: true
---

# Research Planner

Encode planning discipline as scaffolds so cheaper subagents do the work. The coordinator finds the hinge, tiers the work, and synthesizes; everything between is delegated. Good research fails at the planning step, not the searching step.

Full framework and worked example: `21.06` and `21.05` under `~/Documents/20.Claude-Docs/21 Research & reports/`.

## The 6-phase protocol

| Phase | What | Who |
|---|---|---|
| 0. Interrogate | Find the hinge; list load-bearing unknowns; confirm top few with human | Coordinator |
| 1. Plan | Decompose into independent strands; define deliverable + evidence grading | Coordinator (or Sonnet from scaffold) |
| 2. Red-team the plan | Adversarial lenses attack the plan before execution | Sonnet x4 (light: x1) |
| 3. Execute + verify | Tiered subagents gather; skeptic refutes claims; **fresh** agents re-verify every citation (3b) | Haiku (lookups) + Sonnet (judgment/verify) |
| 4. Synthesize | Merge with strong/moderate/inference grading and honesty rules | Coordinator |
| 5. Package | Report skeleton, audience separation, designed PDF — read `packaging.md` when you get here | Coordinator (or Haiku assembly) |

Run phases as a pipeline where possible. Only barrier where a phase genuinely needs all of the prior phase's output (synthesis needs all findings; execution strands don't need each other).

## Sizing: full vs light

**Full is the default.** Run light ONLY when the human asks for it at invocation (`/research-planner light ...` or "light mode") — never downgrade on your own judgment.

- **Full**: 5-8 strands, 4 red-team lenses, skeptic pass, batched 3b, packaged per `packaging.md`.
- **Light**: 2-4 strands, ONE red-team agent covering all four lenses in a single prompt, skeptic only on load-bearing claims, one 3b verifier batch, single-file deliverable (skip `packaging.md`).

Citation verification (3b) is mandatory at both sizes. It's the trust artifact; never skip it silently.

Model tiering rule of thumb: find-and-verify-a-fact = Haiku. Weigh a tradeoff = Sonnet. Decide the shape of the whole thing, or a human acts directly on it = coordinator.

## Phase scaffolds

Copy-paste these. Fill the brackets. These are the operational heart — keep them intact.

### Phase 0 — Interrogate the request

```
Before researching [REQUEST], answer these about the request itself:
- What is the stated question? What is the DECISION it feeds?
- What single unknown, if resolved, would most change the answer? (the hinge)
- List every assumption the request makes as fact. Which are actually unverified?
- Which 1-3 unknowns should be confirmed with the human BEFORE running, because
  the answer deletes a whole branch of work? (allergy status, exact scope, hard constraints)
- What would make the whole effort unnecessary or trivial?
Output: the hinge, the assumptions-to-check, and the questions for the human.
```

### Phase 1 — Draft the plan

```
Plan the research for [REFINED QUESTION]. Produce:
- [N per size] INDEPENDENT strands, each a self-contained question a subagent can answer alone.
- For each strand: model tier (Haiku = bounded lookup; Sonnet = judgment/tradeoff),
  and what a good answer contains.
- The deliverable and its OUTPUT FORMAT, decided now (who reads it, how it's packaged).
- The evidence-grading scheme (strong / moderate / inference) applied to every claim.
- What "done" looks like and what is explicitly OUT of scope.
```

### Phase 2 — Red-team the plan (full: one agent per lens, parallel; light: one agent, all lenses)

```
You are an adversarial [LENS] reviewer. Attack this plan; do not praise it.
LENS in {
  Safety/harm         -- what could hurt someone or backfire; unsafe defaults; false reassurance
  Evidence honesty    -- will weak evidence get laundered into confident numbers; is strong-vs-
                         inference separation real; which claims are most likely overstated
  Domain accuracy     -- mechanistic/technical errors, myths, outdated facts, missed nuance
  Feasibility/coverage-- over-engineering to cut; patient/user burden; what's MISSING
}
Return: (1) fatal flaws worst-first, (2) missing items, (3) overreach to cut,
(4) concrete fixes, (5) a 1-10 score with one-line justification. Flag uncertainty.
```

### Phase 3 — Execute a strand + verify

```
[STRAND QUESTION]. Use web search/fetch. Cite only what you actually find; for every
citation return title, venue, year, and a REAL URL (PMID/PMC/DOI where possible).
Flag anything you cannot verify. Grade each finding strong/moderate/inference.
State how a decision-maker should act on it.
```

Then run the skeptic on load-bearing claims:

```
Try to REFUTE these claims: [CLAIMS]. For each: survives / qualify / wrong, with a real
source. Default to skepticism when uncertain. This is the safety net before a human acts.
```

### Phase 3b — Verify every citation

Mandatory before shipping anything cited. The agent that verifies must not be the one that gathered — "verified" gatherer citations still carry wrong authors, years, and numbers. Read `verify-citations.md` when you reach this phase for the scaffold, batching, and known failure modes.

### Phase 4 — Synthesize (honesty rules non-negotiable)

```
Merge the findings into [DELIVERABLE]. Rules:
- Lead with the answer. State the recommendation before the evidence.
- Grade every claim strong/moderate/inference INLINE.
- Any inference-grade claim gets qualitative language -- NEVER a fabricated percentage.
- Add a "corrections flagged" note: which sources NOT to use and why (retracted, misattributed).
- Name the lever hierarchy: which action moves the outcome most, in order.
- If there is no tradeoff, say so explicitly.
```

### Phase 5 — Package

Full runs: read `packaging.md` (report skeleton, Johnny-Decimal foldering, audience separation, PDF rendering via the bundled `render_pdf.py`). Light runs: single markdown file using the Bottom line → evidence → recommendation shape.

## Anti-patterns

- **Executing a confident prompt verbatim.** Scope first — the confident framing is often the wrong question.
- **Optimizing a leaf with the root unresolved.** Find the hinge before you fan out.
- **Silent truncation.** If you capped coverage, say so — it reads as "covered everything" when it isn't.
