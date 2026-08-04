---
name: generate
description: Generate images and video through pay-as-you-go aggregators (kie.ai, fal.ai, wavespeed) with hard budget caps and local prompt logging - a subscription-free Higgsfield alternative. Use when the user wants images, ads, product shots, video, or visual assets, says "/generate", or asks to make media without a monthly subscription.
---

# generate

## Cardinal rules

1. **Cost before pixels.** `--dry-run` first, confirm the spend, then run with
   `--budget` (session cap) and `--max-cost` (per-call cap). The script refuses
   to exceed either.
2. **Save locally.** Outputs land in `<out>/` with a sidecar `.json` and a line
   in `prompts.jsonl`. Provider URLs expire (kie's in ~24h).
3. **Cheapest that works.** `auto` routes kie -> fal -> wavespeed, first key set.

## Steps

1. **Scope:** media type, variations, aspect, reference images, budget.
2. **Pick a model** by logical name. `REGISTRY` at the top of
   `scripts/generate.py` is the source of truth. Never invent a slug.
3. **Dry-run.** It prints the exact request body plus the estimate. Read the body -
   cheapest way to catch a bad field. Show the user, get a go-ahead.
4. **Generate.** One prompt across models pins a style; `--n` varies one model.

## Run

```bash
python3 ~/.claude/skills/generate/scripts/generate.py \
  --model nano-banana --prompt "green apple studio splash ad" \
  --n 3 --aspect 1:1 --budget 3 --out ./generations --dry-run
```

Flags: `--model` `--prompt` (required); `--provider auto|kie|fal|wavespeed`;
`--n`; `--aspect`; `--ref URL_or_path` (repeatable); `--seed`; `--out`;
`--budget`; `--max-cost`; `--dry-run`; `--timeout`.

`--aspect`, `--seed` and `--ref` are translated per model, and `--ref` switches
to the model's edit variant. Don't hand-build bodies to work around that.

Needs one key in the env: `KIE_API_KEY` (cheapest), `FAL_KEY` (most reliable,
only one taking local ref files), `WAVESPEED_API_KEY` (niche). None set: stop and
ask. Never write a key into a repo file.

## Reference

- `references/models.md` - adding a model, cost caveats.
- `references/providers.md` - endpoints, quirks, verifying a slug, 4xx triage.
- Gallery, on request: a self-contained `gallery.html` in `<out>/`, responsive
  grid of every output with its prompt from `prompts.jsonl`.
