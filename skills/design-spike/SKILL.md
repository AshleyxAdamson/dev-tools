---
name: design-spike
description: |
  Explore how to design (or redesign) a UI surface when you have an experience
  goal but not a settled design. Fans out several DISTINCT design directions as
  self-contained, openable HTML mockups on REAL data, adversarially critiques them
  (scored 1-10, attacked, not praised), and synthesizes a recommendation (a base
  direction + grafts from the rest) with a build plan. Triggers: "design spike",
  "explore the design of X", "give me design options for X", "compare a few
  directions before we build".
---

# design-spike

A design-exploration harness. Most design tooling either builds one thing or
critiques one thing; this one EXPLORES: it fans out into competing directions,
pits them against each other, and hands back a decision you can act on, with
artifacts the user can actually open and click.

Use it when the experience is roughly known but the design isn't, or when the user
wants real options to compare before committing to a build. It is the phase BEFORE
`frontend-design` (build) and `design-review` (audit).

## 1. Gather inputs first (ask only for what's missing)

- **Surface** — which part of the UI (a pane, screen, flow).
- **Goal + tensions** — what it must achieve, and the competing pulls stated
  explicitly (e.g. "a layperson can just read it" vs "show the machine's data so it
  can be verified right/wrong"). Naming the tensions is what makes the critique sharp.
- **Constraints** — stack (framework, or plain HTML/CSS/JS), the design system
  (fonts, palette, tokens), offline vs online, and any backend/data shape the UI
  must consume.
- **REAL data** — point at actual files to populate the mockups. Mockups on lorem
  are worthless; mockups on the real content are how the user judges. Designers may
  hand-author plausible content (e.g. write the summaries a real model would) so the
  mockup previews the true experience.

## 2. Run the Workflow (three phases)

Author and run a `Workflow`. Give each designer a DISTINCT angle so they don't
converge — diversity is the entire point of the fan-out.

```js
// DESIGN — N designers (usually 3), distinct angles, each writes an OPENABLE mockup.
const designs = (await parallel(DIRECTIONS.map(d => () =>
  agent(designerPrompt(d), { phase:'Design', schema: DESIGN_SCHEMA })))).filter(Boolean);

// CRITIQUE — ONE adversarial judge. Read all the mockups + specs. Score each 1-10 on
// each tension + feasibility; ATTACK them (concrete weaknesses, no faint praise);
// then name the best elements across all and recommend a base + grafts.
const critique = await agent(critiquePrompt(designs), { phase:'Critique', schema: CRITIQUE_SCHEMA });

// SYNTHESIZE — write RECOMMENDATION.md (chosen base + which elements to graft from
// the runners-up + a concrete build plan), and return a short summary to relay.
const synth = await agent(synthPrompt(designs, critique), { phase:'Synthesize' });
return { mockups: designs.map(d => d.file), recommendation: critique.recommendation, synth };
```

**Each designer must:** read the real data; write a SELF-CONTAINED openable HTML
mockup (inline `<style>`/`<script>`, no network, no CDNs) with real content and the
key interaction actually WORKING; match the design system; apply the `design-craft`
skill (type hierarchy, spacing, anti-AI-slop); and resolve every named tension.
Return `{ file, concept, tensionA, tensionB, interaction, tradeoffs }`.

**The critique is the load-bearing step.** A single judge told to be adversarial —
score 1-10, name concrete weaknesses (catch the fatal flaw a designer won't admit,
e.g. a layout that collides with the persistence model), then recommend ONE base
direction PLUS the specific elements to graft from the others. Schema:
`{ rankings:[{name,score,strengths,weaknesses}], bestElements:[…], recommendation, why }`.

Pick angles that genuinely diverge. Examples that worked: reading-first (flowing
prose/brief) vs structure-first (mirror the document outline) vs concern-first
(answer the questions the user actually asks). Force the lens in the prompt.

## 3. After the run

1. `open` the mockup files so the user compares the real thing side by side.
2. Relay the recommendation (base + grafts) and the honest tradeoffs.
3. Let the user choose. Then build the winner **contract-first**: freeze the data
   shape the experience needs, make the backend deliver it, then the UI consumes it
   as pure presentation (so the UI doesn't change when real data lands later).

## Pairs with

- `design-craft` — the principles each designer applies inside the mockup.
- `frontend-design` — building the chosen direction for real.
- `design-review` — auditing it once it's shipped.
