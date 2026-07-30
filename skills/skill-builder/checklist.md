# The Great-Skills Checklist

Run this against any skill — one you're writing or one you pulled from the community. Four passes. For each check, cite the specific line that passes or fails.

## 1. Trigger — how the skill is invoked

- [ ] The invocation model is a deliberate choice, not an accident. (user-invoked *or* model-invoked — see Step 0 in `SKILL.md`)
- [ ] If **model-invoked**: the `description` is sharp enough to fire at the right time and *only* then. Every model-invoked skill adds **context load** to every session; this one earns it.
- [ ] If **user-invoked**: the skill is hidden from the agent's context (disable-model-invocation), so it costs zero tokens until called.
- [ ] The skill isn't paying both costs for no reason (a vague description that misfires *and* needs the user to babysit it).

## 2. Structure — how the skill is laid out

- [ ] `SKILL.md` is **as small as possible**. Nothing lives here that a branch could hold instead.
- [ ] Content splits cleanly into **steps** (the procedure) and **reference** (supporting material).
- [ ] **Branches** are identified — the distinct ways the skill gets used.
- [ ] Reference used in only **one branch** sits behind a **context pointer** (a sibling file), not inline in `SKILL.md`.
- [ ] Reference every branch needs *is* in `SKILL.md` (don't over-split — a one-branch skill keeps its reference inline).

## 3. Steering — getting the agent to actually do it

- [ ] **Leading words** carry the intent: short, meaning-dense phrases repeated through the skill (e.g. "vertical slice", "single source of truth", "deletion test"), not long prose the agent will paraphrase and drift from.
- [ ] The leading words are used **consistently** — same phrase every time, not five synonyms.
- [ ] You've watched (or can watch) the reasoning traces echo the leading word. If the agent never says it back, the word isn't landing — sharpen it.
- [ ] **Legwork** is right per step. If a step that needs deep effort gets rushed because the agent can see the final goal, that step is split into its own skill so the agent sees one step at a time.

## 4. Pruning — make it as small as it can be

- [ ] **Single source of truth (DRY).** Every fact, template, or definition appears once. No duplication across steps or across reference files.
- [ ] **No sediment.** No stale, half-relevant material that accumulated over edits. If added content isn't relevant to all branches, move it to the right branch; if it's dead, delete it.
- [ ] **No no-ops.** Apply the **deletion test** to every paragraph: delete it, and if the agent's behavior wouldn't change, it was a no-op — leave it deleted. (No-ops breed when an agent writes the skill.)
- [ ] The skill isn't **massive**. Size is a symptom — if it's big, one of the three checks above is failing.

---

## Vocabulary (the leading words of skill-building)

- **Steps** — the step-by-step procedure a skill walks through.
- **Reference** — supporting material the steps lean on (templates, definitions).
- **Context pointer** — a one-line reference from `SKILL.md` to a sibling file, loaded only when needed. Keeps branch-specific reference out of the main file.
- **Branch** — a distinct way the skill gets used. Drives what can move behind a context pointer.
- **Context load** — cost a model-invoked skill puts on the *agent*: its description sits in context every session, spending tokens and attention.
- **Cognitive load** — cost a user-invoked skill puts on the *user*: one more thing to remember and know when to use.
- **Leading word** — a short phrase packed with meaning (from *leitwort*). Put it in the skill; the agent repeats it in its reasoning and output, which steers its behavior.
- **Legwork** — how much effort the agent spends on the current step. Rushed when the final goal is visible; forced up by hiding future steps (split into separate skills).
- **Sediment** — irrelevant or stale material that piles up as many hands edit a shared file.
- **No-op** — text that looks instructive but doesn't change behavior. Caught with the deletion test.
- **Deletion test** — delete a chunk; if behavior is unchanged, it was a no-op. Keep it deleted.
- **Single source of truth** — each piece of information lives in exactly one place.
