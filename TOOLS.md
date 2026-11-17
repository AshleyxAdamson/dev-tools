# Which tool for the job

For agents. `~/.claude/CLAUDE.md` imports this file, so it is in every session on this Mac. When a job below comes up, pick from its table. Don't choose by tool name, or by whichever skill description matched first.

Skills and MCP servers describe themselves in every session, so they are not listed one by one. This file holds only two things: jobs where more than one tool fits, and command-line tools nothing else advertises.

**Keeping it true:** a new tool that overlaps a job here gets its row in the same change, and its own description names the sibling to use instead. The real file is `~/dev-tools/TOOLS.md`; edit it there and land it with `/ship`.

## Video and audio in: pick by what the recording carries

| Need | Tool | Cost |
|---|---|---|
| **Words only** from YouTube: talks, podcasts, battle reports, rules or strategy discussions | `yt-dlp` captions, no video (command below) | Seconds per video, a few MB of text |
| **Screens** from YouTube: app demos, UI teardowns, onboarding flows, anything you must see | `video-grab` skill | Downloads the whole video to cut frames and contact sheets; minutes and hundreds of MB per long video |
| **No captions on YouTube**, or a local audio or video file you only need the words of | `mlx_whisper` (`~/.local/bin`) | Local and slow; downloads the audio first |
| A local video the owner is **editing** (cuts, reels, takes) | lumr-studio plugin (`transcribe`, then its skills) | Local; first use downloads two models, ask first |

Words only, captions without the video:

```bash
yt-dlp --skip-download --write-auto-subs --write-subs --sub-langs "en.*,en" --sub-format vtt -o "%(id)s.%(ext)s" -- <video-id>
```

Read the `.en-orig.vtt` file. It repeats each line as the captions roll, so strip the tags and drop repeated lines before reading. After four or five videos in a row YouTube answers 429; wait a minute and rerun the ones that failed.

No captions: `yt-dlp -x --audio-format m4a -o "%(id)s.%(ext)s" -- <video-id>`, then `mlx_whisper <file> --language en --output-format txt`.

All of these mishear names (units, products, people), so map them to the right spelling before you quote anything. Members-only videos can't be fetched by any of them: list the ones you skipped and tell the owner.

Keep downloads in the session scratchpad, never in a repo: they are other people's work. Commit only your paraphrased notes.

## Images out

| Need | Tool | Cost |
|---|---|---|
| A new image, free and private | image-edit MCP `generate_image` (local Qwen) | Free; minutes, waits its turn for the GPU |
| A new image or video from a hosted model, or quality the Mac can't reach | `generate` skill | Paid per call, under its budget cap |
| Change one area of an existing image and keep every other pixel | image-edit MCP `edit_region` | Free; minutes |
| A named local model (Flux, Z-Image, Krea, an upscale) | `mflux-*` commands in `~/.local/bin` | Free; only when the owner names the model |

ComfyUI (project 26) is a node editor the owner drives by hand: use it only when asked.

## Text off a page or a picture

| Need | Tool | Cost |
|---|---|---|
| A PDF that already holds real text | `pdftotext` (poppler) | Instant |
| Scans, phone photos, long documents where layout matters | Unlimited OCR 2 (run line in `35 local-models/MODELS.md`) | Minutes; fails if Ollama has a model loaded |
| One screenshot or photo | Read the image yourself | Nothing |
| Text or mana cost on a Magic card | image-edit MCP `read_text`, `read_mana` | Free; minutes |

## Local language models

Read `~/Documents/Code/10-19 Projects/35 local-models/MODELS.md` before picking one, and load one big model at a time. `claude-local`, `claude-glm` and `claude-kimi` start Claude Code on Ollama, GLM and Kimi: run them only when the owner asks for that backend.

## Writing checks

| Need | Tool |
|---|---|
| Draft or edit prose so it sounds like Ashley | `anti-ai-prose` skill |
| A pass, warn or rewrite verdict on a finished passage | `anti-ai-writing` plugin skill |
| Stress-test a plan by interview | `grilling` skill (`grill-me` is an older copy of the same job) |

## Design

| Need | Tool |
|---|---|
| Draw or change a screen | Paper MCP |
| The owner names Figma or gives a figma.com link | Figma MCP |
| Several directions compared before a design is settled | `design-spike` skill |

## Mail and files

| Need | Tool |
|---|---|
| Google mail, calendar, Drive | The Gmail, Calendar and Drive connectors |
| Microsoft 365 | `moff` (project 23); `moff schema` lists what works today |
| Park mail, Drive and records | `bin/park`, `bin/mail`, `bin/drive` inside project 36 only |

## Where tools live

Project numbers are folders under `~/Documents/Code/10-19 Projects/`.

| Repo | Holds |
|---|---|
| `~/dev-tools` | This file; skills `activity-check`, `anti-ai-prose`, `design-spike`, `flare-strategy`, `generate`, `research-planner`, `skill-builder`, `video-grab`; the status line |
| `~/factory/agentbox` | `claude-local`, `claude-glm`, `claude-kimi` |
| 11 MTG-Deck-Builder | mtg-cards MCP; skills `commander-deck`, `print-deck` |
| 13 proxy-magic | image-edit MCP (`products/tools/localgen`) |
| 21 lore-builder | skills `lore-setup`, `lore-build`, `lore-check`, `lore-pass` |
| 23 moff | `moff`, Microsoft 365 from the command line |
| 33 lumr | lumr-studio plugin; `bookforge`, `hammy`, `clipforge`; `anti-ai-writing` |
| 34 pebbl | `pebbl`, project memory |
| 35 local-models | `MODELS.md`, Unlimited OCR 2, Code2Video |
| 36 Mobile-Home-Parks | `bin/park`, `bin/mail`, `bin/drive` |
| 44 learn-later | `learn`; skills `learn-later`, `socratic-tutor` |
