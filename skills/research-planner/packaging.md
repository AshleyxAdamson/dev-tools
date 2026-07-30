# Phase 5 — Package and render

## Report skeleton

```
# [Title]
**Status:** Decided | Undecided | Active | Reference   **Date:** YYYY-MM-DD   **Audience:** ...

## Bottom line
[2-5 bullets. Recommendation plainly, first. If no tradeoff exists, say so.]

## Contents    (multi-file packages only — table with Audience column)

## The problem / context
[What triggered this; constraints; only facts that shape the recommendation.]

## The key reframe / root cause
[The insight that decides which options are worth considering. Put it before the options.]

## Options / evidence
[Multi-axis comparison table with evidence graded strong/moderate/inference inline.]

## Recommendation
[Explicit. Lead + fallback + what triggers the fallback. Lever hierarchy in order.]

## Caveats / honesty notes
[What the evidence doesn't cover. Corrections: what not to cite and why.
 Numbers only where an RCT/meta-analysis anchors them.]

## Open items / next steps
- [ ] [Decision or action with a named trigger/owner]

## Sources
[One line each; PMID/PMC/DOI where possible; grouped by question if long.]
```

## Packaging conventions

- **Johnny-Decimal foldering** under `21 Research & reports` (`21.05`, `21.06`, ...).
- **`00-README` as master index** for multi-file packages: bottom line + contents-with-audience + context + open items. It's the doc for someone with ten seconds.
- **Zero-padded file numbering** (`00-`, `01-`, ...) so order is unambiguous.
- **Audience separation:** decision-maker one-pager / evidence brief / action list. The surgeon doesn't need the protocol; the executor doesn't need the meta-analysis.
- **Context-and-rationale map:** an anonymized "subject context" doc near the front that pairs each unusual fact with the problem it creates and the recommendation it drives. A recommendation without its triggering constraint reads as arbitrary.
- **Ship the verification log** (Phase 3b) as a numbered appendix so the audit travels with the report.

## Write it in voice — anti-AI, no filler

Before rendering, the prose must read like Ashley wrote it, not like an AI. Run the deliverable through the **`anti-ai-prose`** skill (`~/.claude/skills/anti-ai-prose/RULES.md` + `anti_ai_checker.py`) and fix what it flags. The essentials that bite research prose:

- **Lead with the answer.** No windup, no "In this section we will." Start on the noun or verb.
- **No filler summaries.** Cut any section that only restates what the reader just read ("The plainest summary," "In conclusion," a recap that adds no new decision or action). A *ranked* list of next actions earns its place; a paragraph that re-says the chapter does not. When in doubt, delete it.
- **No AI tells:** em dashes (use a hyphen or restructure), "It's not X, it's Y," prestige words (delve, leverage, robust, nuanced), hedge stacks, filler affirmations. Use contractions; vary sentence length.
- **Plain-first for a lay audience.** For anything with more than one moving part, open with a plain-language anchor or everyday analogy before the technical term. If a reader hits two pieces of jargon before an anchor, rewrite.
- **Grade honestly inline** and never launder a low-evidence claim into a confident number.

## Rendering — designed PDF, not raw markdown

```
DYLD_FALLBACK_LIBRARY_PATH=$(brew --prefix)/lib python3 ~/.claude/skills/research-planner/render_pdf.py \
  --dir "<package folder>" --title "..." --subtitle "..." --meta "..." --tag "21.NN" --theme <name>
```

Auto-discovers the folder's `NN-*.md` files and emits a cover, a contents list with real page numbers, running chapter headers, and the design below. On success it **reveals the finished PDF in Finder** (pass `--no-open` for headless/cron runs or when batch-rendering). Needs `pip install weasyprint markdown` (true `target-counter` page numbers + `string-set` running headers). Drop a `labels.json` (`{"01-foo.md": "Foo"}`) for section labels.

**Theme per subject.** `--theme <name>` (or a `theme.json` in the folder: `{"theme": "care"}`, plus optional per-token overrides) picks the palette + type. Specialize the design to the subject and its reader:
- `care` — warm, humane healthcare brand (muted pine-green, serif body): for a patient/caregiver audience navigating illness.
- `default` — refined neutral navy: decisions, ops, technical reports.
- Add a new theme by extending the `THEMES` dict in `render_pdf.py` (carry identity through accent + type, keep backgrounds near-white tinted toward the theme's own hue — never a cream/beige body).

Design system (baked into the renderer — write markdown that feeds it):
- **Editorial type.** Serif body (Charter) paired against a humanist sans (Avenir Next) for headings — pairing on a contrast axis, not two similar sans. Comfortable measure, generous rhythm.
- **Chapters flow continuously** (no forced page-per-file), so pages fill instead of leaving colored voids; headings stay with their content. There is no blank leading page.
- **Hierarchy without slop.** Serif H1 with a hairline; sans H2 with a small accent dot (no side-stripe borders — banned); a per-chapter kicker that doubles as the running header (a chapter label on a real sequence, not an eyebrow on every subsection).
- **Evidence grades → pills.** End graded claims with `**Strong**` / `**Moderate**` / `**Inference**` (also `**Patient-reported**` / `**Lived-experience**` / `**Emerging**` → gray) for tinted rounded pills.
- **Recommendation highlighted.** `RECOMMENDED` in a table row → tinted green.
- **Callouts.** `## Bottom line` → tinted panel; blockquotes → soft cards (use for the disclaimer and key takeaways).
- **Tables** render skimmable with a soft accent header and zebra rows — keep them multi-axis.

Goal: the intended reader — often not a specialist — skims it calmly and lands on the answer, its evidence grade, and the one thing that makes this case unique.
