#!/usr/bin/env python3
"""
Anti-AI prose checker — consolidated edition.

Scans writing for AI-generated text patterns and returns a severity rating
(pass / warn / rewrite) plus a list of flagged issues.

This is the MECHANICAL half of the anti-ai-prose skill: the subset of rules
that regex can catch. The full, canonical rule list (including judgment-only
rules a regex can't see) lives in RULES.md next to this file. When you add a
rule, add it to RULES.md first, then encode it here if it's detectable.

Usage:
    python3 anti_ai_checker.py "Some text to check"
    python3 anti_ai_checker.py path/to/file.md
    python3 anti_ai_checker.py          # reads from stdin
"""

import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Pattern dictionaries  (mirror RULES.md — keep in sync)
# ---------------------------------------------------------------------------

PRESTIGE_WORDS = {
    "delve", "leverage", "harness", "streamline", "underscore",
    "foster", "navigate", "embark", "showcase", "elevate", "alleviate",
    "optimize", "tapestry", "landscape", "realm", "paradigm", "synergy",
    "ecosystem", "framework", "testament", "multifaceted", "myriad",
    "robust", "nuanced", "meticulous", "seamless", "intricate",
    "comprehensive", "vibrant", "daunting", "innovative",
    "cutting-edge",
}

# Latinate words with a plainer Anglo-Saxon swap. value -> suggested swap.
LATINATE_SWAPS = {
    "utilize": "use", "commence": "start", "demonstrate": "show",
    "facilitate": "help", "individuals": "people", "numerous": "many",
    "prior to": "before", "in order to": "to", "a number of": "some",
    "additional": "more", "approximately": "about", "sufficient": "enough",
    "terminate": "end", "obtain": "get", "purchase": "buy",
}

MAGIC_ADVERBS = {
    "deeply", "fundamentally", "remarkably", "arguably", "notably",
    "importantly", "interestingly", "effectively", "strategically",
    "consistently", "quietly",
}

# Hedge stacks: a modal next to a hedge adverb. Each cancels the other.
HEDGE_STACKS = [
    "could potentially", "may eventually", "might possibly", "can sometimes",
    "could possibly", "may potentially", "might eventually", "could perhaps",
]

FILLER_TRANSITIONS = [
    "it's worth noting", "it bears mentioning", "importantly,", "notably,",
    "interestingly,", "at its core", "to put it simply", "moreover,",
    "furthermore,", "additionally,", "consequently,", "that being said",
]

RHETORICAL_OPENERS = [
    "here's the thing", "here's where it gets interesting",
    "here's what most people miss", "here's the kicker",
    "here's the uncomfortable truth", "let's unpack this",
    "let's explore", "let's dive in", "let's break it down",
    "let's break this down", "here's where i'll", "here's the part where",
    "here's the part people",
]

# Mode-announcing / colon-label openers at the start of a line.
MODE_LABELS = [
    "short answer", "quick answer", "the short version", "tl;dr", "tldr",
    "bottom line", "my bet", "the bet", "honest answer", "straight answer",
    "real talk", "to be direct", "in short",
]

TEMPLATED_INTROS = [
    r"in today's fast[- ]paced",
    r"in a world where",
    r"as the \w+ continues to evolve",
    r"now more than ever",
    r"have you ever wondered",
]

SERVES_AS_PATTERNS = [
    r"\bserves as\b", r"\bstands as\b", r"\bmarks a\b", r"\brepresents a\b",
]


# ---------------------------------------------------------------------------
# Core checker
# ---------------------------------------------------------------------------

def check_passage(text: str) -> dict:
    """
    Scan text for AI writing patterns.

    Returns:
        {"score": int, "severity": "pass"|"warn"|"rewrite", "flags": [(cat, desc)]}
    """
    flags = []
    text_lower = text.lower()
    word_count = max(1, len(text.split()))

    # --- Punctuation ---

    # Em-dash density: flat count AND per-500-words rate (humans ~1 per 500).
    em_dash_count = text.count('—') + text.count(' -- ')
    em_dash_rate = em_dash_count / word_count * 500
    if em_dash_count > 3 or em_dash_rate > 2:
        flags.append((
            "punctuation",
            f"em dash overuse ({em_dash_count} found, {em_dash_rate:.1f} per 500 words)",
        ))

    if re.search(r':\s*\n\s*[-*\d]', text):
        flags.append(("punctuation", "colon-before-list pattern"))

    # --- Sentence structure ---

    if re.search(r"it'?s not just .{3,40}[-—,;] it'?s", text_lower):
        flags.append(("structure", '"It\'s not just X, it\'s Y" pattern'))

    # Bare "not X, it's Y" / "not X. It's Y" contrast frame.
    if re.search(r"\b(?:isn'?t|wasn'?t|aren'?t|was never|is never) .{3,50}[.,;] it'?s ", text_lower):
        flags.append(("structure", '"not X, it\'s Y" contrast frame'))

    if re.search(r"not because .{3,40}, but because", text_lower):
        flags.append(("structure", '"Not because X, but because Y" pattern'))

    if re.search(r"is more than just", text_lower):
        flags.append(("structure", '"more than just" pattern'))

    if re.search(r"the \w+\? [A-Z]", text, re.IGNORECASE):
        flags.append(("structure", "self-answered rhetorical question"))

    participial = re.findall(
        r', (?:marking|highlighting|underscoring|reflecting|showcasing|'
        r'demonstrating|illustrating|signaling|suggesting) ',
        text_lower,
    )
    if len(participial) >= 2:
        flags.append(("structure", f"participial phrases for false depth ({len(participial)} found)"))

    if re.search(r"not \w+\.\s*not \w+\.\s*(?:just|only)", text_lower):
        flags.append(("structure", '"Not X. Not Y. Just Z." countdown'))

    # Trailing "..., not X." restatement tail at end of a sentence.
    tails = re.findall(r", not [a-z]{2,15}\.", text_lower)
    if len(tails) >= 2:
        flags.append(("structure", f'trailing "not X" restatement tails ({len(tails)} found)'))

    # Parallel scaffolding: "there's a/an ___ for this/that" used to set up.
    scaffolds = re.findall(r"there'?s an? \w+ (?:for|to) (?:this|that|it)\b", text_lower)
    if scaffolds:
        flags.append(("structure", f'"there\'s a ___ for this" scaffolding ({len(scaffolds)} found)'))

    # Reveal cleft: "What nobody admitted was...", "What no one tells you is...".
    if re.search(
        r"\bwhat (?:nobody|no one|few people|everyone|most people) "
        r"(?:admits?|admitted|says?|said|tells? you|knew|knows?|realized?|"
        r"realizes|misses?|gets?|sees?)\b",
        text_lower,
    ):
        flags.append(("structure", 'reveal cleft ("what nobody X was...")'))

    # Pseudo-cleft anaphora: clause-initial "What ... is/was" used repeatedly.
    pseudo_clefts = re.findall(
        r"(?:^|[.!?]\s|\n)\s*what(?:'s)?\b[^.?!\n]{2,40}?\b(?:is|was|are|were)\b",
        text_lower,
    )
    if len(pseudo_clefts) >= 3:
        flags.append((
            "structure",
            f'pseudo-cleft anaphora ({len(pseudo_clefts)} "What ... is" openers)',
        ))

    # "the part/thing that was always X" false-profundity flourish.
    if re.search(r"the (?:part|thing|point|reason) (?:that |)(?:was|is) always\b", text_lower):
        flags.append(("structure", '"the part that was always..." flourish'))

    # "...in a way we couldn't before" trailing contrast.
    if re.search(r"in a way (?:you|we|they|i|that)\b[^.?!\n]{0,30}\b(?:could|couldn'?t|never|hadn'?t|wouldn'?t)\b",
                 text_lower):
        flags.append(("rhetorical", '"in a way ... couldn\'t before" tail'))

    # Tricolon / rule-of-three: "word, word, and word" runs.
    tricolons = re.findall(r"\b\w+, \w+,? and \w+\b", text_lower)
    if len(tricolons) >= 3:
        flags.append(("structure", f"rule-of-three overuse ({len(tricolons)} tricolons)"))

    # --- Word choice ---

    found_prestige = [w for w in PRESTIGE_WORDS if w in text_lower]
    if len(found_prestige) >= 2:
        flags.append(("word_choice", f"prestige vocabulary: {', '.join(sorted(found_prestige)[:5])}"))

    found_latinate = [w for w in LATINATE_SWAPS if w in text_lower]
    if len(found_latinate) >= 2:
        swaps = ', '.join(f"{w}->{LATINATE_SWAPS[w]}" for w in sorted(found_latinate)[:4])
        flags.append(("word_choice", f"Latinate over plain: {swaps}"))

    found_adverbs = [w for w in MAGIC_ADVERBS if w in text_lower]
    if len(found_adverbs) >= 2:
        flags.append(("word_choice", f"magic adverbs: {', '.join(sorted(found_adverbs)[:5])}"))

    found_hedges = [h for h in HEDGE_STACKS if h in text_lower]
    if found_hedges:
        flags.append(("word_choice", f"hedge stacking: {', '.join(found_hedges[:3])}"))

    for pattern in SERVES_AS_PATTERNS:
        m = re.search(pattern, text_lower)
        if m:
            flags.append(("word_choice", f"'{m.group()}' dodge"))
            break

    # --- Rhetorical ---

    for phrase in RHETORICAL_OPENERS:
        if phrase in text_lower:
            flags.append(("rhetorical", f'opener: "{phrase}"'))
            break

    # Mode-announcing labels at line start: "Short answer:", "My bet:".
    for label in MODE_LABELS:
        if re.search(r"(?:^|\n)\s*" + re.escape(label) + r"\b[:,]", text_lower):
            flags.append(("rhetorical", f'mode-announcing label: "{label}:"'))
            break

    for phrase in FILLER_TRANSITIONS:
        if phrase in text_lower:
            flags.append(("rhetorical", f'filler transition: "{phrase}"'))
            break

    for pattern in TEMPLATED_INTROS:
        if re.search(pattern, text_lower):
            flags.append(("rhetorical", "templated intro"))
            break

    gravitas = sum(
        1 for w in ["crucial", "essential", "vital", "pivotal", "transformative"]
        if w in text_lower
    )
    if gravitas >= 2:
        flags.append(("rhetorical", "gravitas inflation"))

    # --- Document structure ---

    paragraphs = [p for p in text.split('\n\n') if p.strip() and len(p.split()) > 10]
    if len(paragraphs) >= 3:
        lengths = [len(p.split()) for p in paragraphs]
        spread = max(lengths) - min(lengths)
        if spread < 20:
            flags.append(("structure", f"uniform paragraph length (spread: {spread} words)"))

    if re.search(r"(?:in conclusion|to sum up|in summary|overall)[,.]?\s", text_lower):
        flags.append(("structure", "signposted conclusion"))

    # Editorializing markdown headers: "## Why X matters", "### The part where".
    if re.search(r"(?:^|\n)#{1,6}\s+(?:why\b.*\bmatters?|why .* is (?:real|important)|the part where)",
                 text_lower):
        flags.append(("structure", "editorializing section header"))

    bold_bullets = re.findall(r'[-*]\s*\*\*[^*]+\*\*', text)
    if len(bold_bullets) >= 3:
        flags.append(("structure", f"bold-first bullet points ({len(bold_bullets)} found)"))

    # --- Tone ---

    expanded = len(re.findall(
        r'\b(?:it is|do not|cannot|will not|does not|is not|are not|was not|have not)\b',
        text_lower,
    ))
    contracted = len(re.findall(
        r"\b(?:it's|don't|can't|won't|doesn't|isn't|aren't|wasn't|haven't)\b",
        text_lower,
    ))
    if expanded > 3 and contracted == 0:
        flags.append(("tone", "no contractions (stiff phrasing)"))

    if re.search(r"(?:you'?re valid|remember (?:that )?you matter|your feelings are valid)", text_lower):
        flags.append(("tone", "generic encouragement without specificity"))

    # --- Score ---
    score = len(flags)
    if score < 3:
        severity = "pass"
    elif score < 6:
        severity = "warn"
    else:
        severity = "rewrite"

    return {"score": score, "severity": severity, "flags": flags}


# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------

SEVERITY_EMOJI = {"pass": "✅", "warn": "⚠️", "rewrite": "🚨"}

def format_report(result: dict, source_label: str = "") -> str:
    """Format checker result for display."""
    sev = result["severity"]
    header = f"{SEVERITY_EMOJI[sev]} Anti-AI Check: {result['score']} flag(s) — {sev.upper()}"
    if source_label:
        header = f"{header}  [{source_label}]"

    lines = [header]

    if result["flags"]:
        lines.append("")
        for cat, desc in result["flags"]:
            lines.append(f"  [{cat}] {desc}")

    lines.append("")
    if sev == "rewrite":
        lines.append("Recommendation: Rewrite this passage. Avoid the flagged patterns.")
    elif sev == "warn":
        lines.append("Recommendation: Review flagged phrases. Consider rewriting 1-2.")
    else:
        lines.append("Recommendation: Looks good - no significant AI patterns detected.")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        candidate = Path(arg)
        if candidate.exists() and candidate.is_file():
            text = candidate.read_text(encoding="utf-8")
            label = str(candidate)
        else:
            text = arg
            label = "inline text"
    else:
        print("Paste text to check, then press Ctrl-D (or Ctrl-Z on Windows):")
        text = sys.stdin.read()
        label = "stdin"

    result = check_passage(text)
    print(format_report(result, source_label=label))
    sys.exit(0 if result["severity"] == "pass" else 1)


if __name__ == "__main__":
    main()
