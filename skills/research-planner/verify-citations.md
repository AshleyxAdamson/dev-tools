# Phase 3b — Verify every citation

Independence is the point: the agent that VERIFIES a citation must not be the one that GATHERED it. Subagents that claim "verified, URL included" still leave errors. In one real run an independent pass found **11 bibliographic errors across ~50 citations** the gatherers had already "verified" — zero were hallucinations, but authors, PMIDs, years, and numbers were wrong.

1. Extract the inventory: `grep -rhoE 'https?://[^ )]+|PMID:? ?[0-9]+|PMC[0-9]+|10\.[0-9]{4,}/[^ ,;)]+' *.md | sort -u`
2. Batch ~8-10 citations per verifier agent (Sonnet, web), run in parallel, each given the CLAIM every citation supports. Light runs: one verifier batch still covers every citation.
3. Scaffold:

```
Fact-check these citations so NONE is hallucinated before a human acts. For EACH, use web
fetch/search to confirm: (a) it EXISTS and resolves, (b) authors, year, venue are correct,
(c) the FINDING we attribute matches — verify the specific number. Be skeptical: if you
cannot confirm it exists with the stated details, mark NOT-FOUND.
Return: | # | Citation as stated | Exists? | Bib correct? | Finding matches? | VERDICT | Correction |
VERDICT in {VERIFIED, MISMATCH, NOT-FOUND, DEAD-LINK-REAL-PAPER, UNVERIFIABLE}.
[list each citation with the CLAIM it supports]
```

Failure modes to expect (all seen in real runs):
- **Wrong first author** — most common; plausible name, wrong paper (~half the errors).
- **PMID/PMC resolves to a different paper**, or to a co-published version in another journal.
- **Wrong year** — e.g. a DOI's `-22` suffix is the submission year, not publication.
- **Numbers drift** — percentages/ORs don't match the source.
- **Overstated finding** — "positive RCT" when the primary endpoint was missed.
- **Retracted paper** — check retraction status explicitly.
- **One source cited under two author names** across files — a tell; reconcile it.
- **Exact figure paywalled** — mark UNVERIFIABLE, not VERIFIED.

Apply the corrections, then ship a **citation-verification log** appendix that travels with the deliverable: sources checked, count hallucinated (state it, e.g. "0"), and a corrections table. It is the trust artifact for anything a clinician or lawyer acts on.
