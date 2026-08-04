# Models

`REGISTRY` at the top of `scripts/generate.py` is the **source of truth** for
logical names, slugs, costs and per-model field names. Read it there; this file
covers only what the code can't say for itself.

## Adding a model

A host row declares how that model spells its params, so adding one never means
editing request code:

```python
"nano-banana": {"kind": "image", "hosts": {
    "kie": {"slug": "google/nano-banana", "cost": 0.04, "aspect": "aspect_ratio",
            "seed": None, "batch": None,
            "edit": {"slug": "google/nano-banana-edit", "refs": "image_urls"}},
}},
```

- `kind` - `image` | `video`
- `aspect` - `"aspect_ratio"` | `"image_size"` (fal's `openai/*` named enum) |
  `"size_wh"` (wavespeed `"1280*720"`) | `None`
- `seed` - field name, or `None` if the model rejects seeds
- `batch` - "N at once" field name (fal: `num_images`), or `None` to loop
- `edit` - the variant used for `--ref`; omit if the model takes no image input.
  The refs field varies: `image_urls`, `image_input`, `input_urls`,
  `reference_image_urls`
- `extra` - optional fixed params

Get field names from the provider's "Copy for LLMs" button, or for fal:
`curl "https://fal.ai/api/openapi/queue/openapi.json?endpoint_id=<slug>"`.

If you're editing request code to fit a model, the row is missing a key instead.

## Costs are ceilings, not invoices

They scale with resolution and duration, so a flat number under-counts:

- `gpt-image-2` on fal spans ~$0.005 (low, 1K) to ~$0.40 (high, 4K). The row's
  0.12 is mid-range - raise it before asking for 4K or `--budget` under-counts.
- Video scales hard with `duration` and `resolution`.
- kie returns real `creditsConsumed`, recorded in each sidecar.

## Re-verify slugs before a big run

They get renamed and retired (kie's `bytedance/seedance-1.5-pro` vanished). A
stale row looks fine and fails only at spend time. Slugs and field names in the
current registry were verified 2026-08-02.
