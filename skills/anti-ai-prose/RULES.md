# Anti-AI Prose Rules (don't write like this)

The single source of truth for AI tells. Merged from three drifting copies:
the BookForge voice spec, the Claude "Plain" output style, and Ashley's global
CLAUDE.md, plus current online research (Wikipedia "Signs of AI writing,"
jalaalrd/anti-ai-slop-writing).

The principle is **density**, not any single tell. One em dash is fine. Five
stacked patterns reads as machine. `anti_ai_checker.py` enforces the mechanical
subset; the rest need a human or model eye. A `[checker]` tag marks rules the
script catches.

## Punctuation
- Em-dash overuse. Humans use roughly one per 500 words; AI drops them every
  50-80. `[checker]` flags >3 total or >2 per 500 words. Use a hyphen or recast.
- Colon-before-list as a setup ("Here's what you need to know:"). `[checker]`
- Semicolon used the way AI uses an em dash (to glue two thoughts for gravitas).

## Sentence structure
- **"It's not X, it's Y"** and its family: "Not because X, but because Y," "X is
  more than just Y." The #1 tell. Never use it. `[checker]`
- Self-answered rhetorical question: "The result? A faster team." `[checker]`
- Participial false-depth tails: "...marking a new era," "...highlighting its
  importance." `[checker]`
- "Not X. Not Y. Just Z." countdown. `[checker]`
- Compulsive rule-of-three / tricolon every sentence. Vary groupings. `[checker]`
- Anaphora abuse: the same opener 3+ times in a row.
- **Trailing "not X" restatement tail.** Once you've stated the thing, don't
  append a negation that just restates it. "It runs hourly, not daily." ->
  "It runs hourly." `[checker]`
- **Parallel scaffolding.** "There's an old idea for this... there's a law for
  this too..." Two mirrored setups in a row announce a template. `[checker]`
- **Reveal cleft.** "What nobody admitted was...", "What no one tells you is...",
  "What most people miss is..." A fake-insider setup that promises a secret.
  Just state the thing. `[checker]`
- **Pseudo-cleft anaphora.** Leaning on "What ___ is ___" to open sentence after
  sentence ("What's left is...", "What makes it fast is...", "What you need is").
  One is fine; three is a tell. `[checker]`
- **False-profundity flourish.** "the part that was always the point," "the thing
  that always mattered" as a dramatic reveal. Say the part plainly. `[checker]`
- **Trailing "in a way we couldn't before."** Padding that restates the gain by
  contrast. Cut it. `[checker]`

## Word choice
- Prestige vocab: delve, leverage, harness, streamline, underscore, foster,
  navigate, embark, showcase, elevate, alleviate, optimize, tapestry, landscape,
  realm, paradigm, synergy, ecosystem, framework, testament, multifaceted,
  myriad, robust, nuanced, meticulous, seamless, intricate, comprehensive,
  vibrant, daunting, innovative, cutting-edge. `[checker]`
- **Latinate over plain.** Prefer the short Anglo-Saxon word: use (not utilize),
  start (not commence), show (not demonstrate), help (not facilitate), people
  (not individuals), before (not prior to), to (not in order to), many (not
  numerous), some (not a number of), more (not additional), about (not
  approximately), enough (not sufficient), end (not terminate), get (not obtain),
  buy (not purchase). `[checker]`
- Magic adverbs: deeply, fundamentally, remarkably, arguably, notably,
  importantly, interestingly, effectively, strategically, consistently,
  quietly. `[checker]`
- "Serves as / stands as / marks / represents" instead of plain "is." `[checker]`
- **Hedge stacking.** A modal next to a hedge adverb cancels itself: "could
  potentially," "may eventually," "might possibly." Assert or don't. `[checker]`
- Gravitas inflation: crucial, essential, vital, pivotal, transformative on a
  topic that doesn't earn it. `[checker]`

## Rhetorical
- "Here's the thing..." / "Here's where it gets interesting..." / "Here's the
  kicker..." / "Let's unpack this" / "Let's dive in." `[checker]`
- "It's worth noting" / "It bears mentioning" / "Importantly," / "Notably," /
  "Interestingly," / "At its core" / "To put it simply" / "Moreover," /
  "Furthermore," / "Additionally," / "Consequently," / "That being said" `[checker]`
- Templated intros: "In today's fast-paced...", "In a world where...", "Now more
  than ever..." `[checker]`
- **Mode-announcing labels.** "Short answer:", "My bet:", "TL;DR:", "Honestly,",
  "To be direct." Saying you're being direct is itself fluff. Just say it.
  `[checker]`
- Acknowledge-then-dismiss: "While X presents challenges, the opportunities far
  outweigh..."
- Stakes inflation: every topic treated as transformative.

## Structure
- Uniform paragraph length (~80 words each). Vary wildly, one sentence to ten.
  `[checker]`
- Bold-first bullet points, three or more in a row. `[checker]`
- Signposted conclusion: "In conclusion," "To sum up," "Overall." `[checker]`
- **Editorializing section headers.** A header names its content flat. Not "Why
  X matters," "Why X is real," "The part where X." `[checker]`
- Fractal summaries: intro, body, and conclusion all restating the same points.
- "The first consideration... The second factor... Finally..."

## Tone
- Emotional flatness: competent but anonymous.
- No contractions ("It is important" vs "It's important"). `[checker]`
- False vulnerability: "And honestly?" / "I'll be the first to admit..."
- Generic encouragement: "You're valid!" with nothing specific behind it.
  `[checker]`
- **Grading the work or worker.** "did honest work," "solid effort," "great
  job." Report what was done; let facts carry the grade.
- **Self-narrated cleverness.** "the elegant part," "the beautiful thing here,"
  "earned its keep," "paid off." State the thing; don't tag it as worth it.

## Severity (checker thresholds)
- 0-2 flags: pass
- 3-5 flags: warn (review, rewrite one or two)
- 6+ flags: rewrite
