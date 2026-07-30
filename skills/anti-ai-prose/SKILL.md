---
name: anti-ai-prose
description: Make writing sound like Ashley, not like AI. Use when drafting, editing, or de-slopping any prose (blog posts, tweets, essays, notes) - or when the user says "anti-AI", "does this sound like AI", "de-slop", "sound like me", "voice check". Pairs a positive voice profile with an upgraded AI-tell checker.
---

# Anti-AI Prose

The single source of truth for "how Ashley writes." Two halves (write toward one, away from the other), plus a checker:

- **VOICE-ASHLEY.md** - write *toward* this. Her voice DNA, teaching style, and
  short-form/tweet patterns, extracted from the BookForge voice spec and made
  general-purpose.
- **RULES.md** - write *away* from this. The canonical AI-tell list, merged from
  the BookForge spec, the Plain output style, CLAUDE.md, and current research.
- **anti_ai_checker.py** - the mechanical enforcement of the detectable subset
  of RULES.md.

This skill is the maintained home. The Plain output style and CLAUDE.md keep
short inline copies for runtime (a system prompt can't load a file), but they
point here. Update rules HERE first, then propagate.

## When writing or editing prose
1. Read **VOICE-ASHLEY.md** and aim for it. Set the customization knobs
   (profanity, register, spiritual vocab) for the context. Product writing
   defaults: profanity light, spiritual off, register blended.
2. Draft. Then reread once and cut the windup, per RULES.md.
3. Run the checker on the draft:
   ```
   python3 ~/.claude/skills/anti-ai-prose/anti_ai_checker.py path/to/draft.md
   ```
   Output is a severity (pass / warn / rewrite) plus flagged lines with
   categories. Fix flags, rerun until it passes. The checker is a floor, not a
   ceiling: a clean score means no *mechanical* tells, not that it sounds like
   Ashley. Judgment rules (voice, rhythm, honesty) still need your eye.
4. For tweets/threads, use the short-form section of VOICE-ASHLEY.md.

## Maintaining
- A new tell shows up -> add it to RULES.md, then encode it in the checker if a
  regex can catch it. Keep the dictionaries in the script in sync with RULES.md.
- The full memoir-specific craft lives in the BookForge voice spec; this skill
  deliberately carries only the transferable voice.
