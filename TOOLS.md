# Which tool for the job

For agents. `~/.claude/CLAUDE.md` imports this file, so it is in every session on this Mac. When a job below comes up, pick from its table. Don't choose by tool name, or by whichever skill description matched first.

This file holds the jobs where more than one tool fits. Every tool found on this Mac, repo by repo, with its path and how to run it, is in `~/dev-tools/TOOLS-CATALOG.md`: read that when a job isn't here, before you write a new script for it.

A number like "33 lumr" is a folder under `~/Documents/Code/10-19 Projects/`. "Run from its folder" means the tool is not on PATH: the catalog has the command.

**Keeping it true:** a new tool gets its catalog row in the same change; if it overlaps a job here it gets a row here too, and its own description names the sibling to use instead. Edit both files in `~/dev-tools` and land them with `/ship`.

## Words out of a video or a recording

| Need | Tool | Cost |
|---|---|---|
| **Words only** from YouTube, to read now: talks, podcasts, battle reports | `yt-dlp` captions, no video (command below) | Seconds per video, a few MB of text |
| YouTube words **saved for a later session** as a pebbl handoff | `ytscript` (33 lumr, run from its folder) | Seconds; writes into the current project's pebbl |
| **No captions on YouTube**, or a local audio or video file | `mlx_whisper` (`~/.local/bin`) | Local and slow; downloads the audio first |
| A recording turned into **notes** (summary, takeaways, actions) | `hammy` (33 lumr, run from its folder) | Local transcription plus a language model |
| A park **meeting** recording | `bin/park transcribe`, inside 36 Mobile-Home-Parks only | Local; files the audio with the meeting |
| A local video the owner is **editing** | lumr-studio plugin (`transcribe`, then its skills) | Local; first use downloads two models, ask first |

Words only, captions without the video:

```bash
yt-dlp --skip-download --write-auto-subs --write-subs --sub-langs "en.*,en" --sub-format vtt -o "%(id)s.%(ext)s" -- <video-id>
```

Read the `.en-orig.vtt` file. It repeats each line as the captions roll, so strip the tags and drop repeated lines before reading. After four or five videos in a row YouTube answers 429; wait a minute and rerun the ones that failed.

No captions: `yt-dlp -x --audio-format m4a -o "%(id)s.%(ext)s" -- <video-id>`, then `mlx_whisper <file> --language en --output-format txt`.

All of these mishear names (units, products, people), so map them to the right spelling before you quote anything. Members-only videos can't be fetched by any of them: list the ones you skipped and tell the owner.

Keep downloads in the session scratchpad, never in a repo: they are other people's work. Commit only your paraphrased notes.

## Screens out of a video, and making video

| Need | Tool | Cost |
|---|---|---|
| **Screens** from YouTube: app demos, UI teardowns, onboarding flows | `video-grab` skill | Downloads the whole video; minutes and hundreds of MB per long video |
| Notes with screenshots from the owner's **own screen recording** with spoken feedback | lumr-studio `ui-feedback` skill | Local |
| **Cut or tighten** one existing video, join takes | lumr-studio plugin skills | Local |
| A long video into **vertical shorts** in a batch | `clipforge` (33 lumr, run from its folder) | Local model by default |
| **Record a web page or prototype** clicking through as a video | the reel recorders in 12 portfolio (`tools/explorer-reel`) | Local; Node and ffmpeg |
| A **new video from a prompt** | `generate` skill | Paid per call, under its budget cap |
| A video **rendered from code** (canvas, SVG, 3D) with narration | `code-video` skill in 35 local-models | Local; not yet proven end to end, and its default voice sends the text to Microsoft |

## Images

| Need | Tool | Cost |
|---|---|---|
| A new image, free and private | image-edit MCP `generate_image` (local Qwen) | Free; minutes, waits its turn for the GPU |
| A new image from a hosted model, or quality the Mac can't reach | `generate` skill | Paid per call, under its budget cap |
| Change one area of an existing image and keep every other pixel | image-edit MCP `edit_region` | Free; minutes |
| A named local model (Flux, Z-Image, Krea), or an upscale | `mflux-*` commands in `~/.local/bin` | Free; only when the owner names the model |
| Magic proxy card art, sketch to print | `pipeline` (29 proxy-pipeline, run from its folder) | Stops for the owner's pick; paid and GPU steps are opt-in |

ComfyUI (26 comfyui) and `scripts/qwen_edit.py` in 29, which drives it, are for when the owner asks: the server must be started by hand.

## Text off a page or a picture

| Need | Tool | Cost |
|---|---|---|
| A PDF that already holds real text | `pdftotext` (poppler) | Instant |
| One screenshot or photo | Read the image yourself | Nothing |
| Plain text from a scan or photo, quickly | macOS Vision: `swift bin/ocr.swift <image>` in 36 Mobile-Home-Parks | Seconds, offline |
| Scans or long documents where layout and block positions matter | Unlimited OCR 2 (run line in `35 local-models/MODELS.md`) | Minutes; can crash with a GPU timeout while Ollama is running a model |
| The owner's codex photos for the army builder | `npm run ocr-codex` in 41 army-builder | Local |
| A Google Drive file as text | `bin/drive text <file>` in 36 (park Drive only) | Network |
| Text or mana cost on a Magic card | image-edit MCP `read_text`, `read_mana` | Free; minutes |

## Speaking text aloud

| Need | Tool | Cost |
|---|---|---|
| Speech that stays on this Mac, or in a cloned voice | 42 real-voice (`uv run python -m speak.app` in `prototype/`) | Local after the first model download |
| Narration inside a `code-video` render | its `tts.py` | Sends the text to Microsoft; not for private text |

## Mail and files

| Need | Tool |
|---|---|
| The owner's Google mail, calendar, Drive | The Gmail, Calendar and Drive connectors |
| Google Drive from the command line | `rclone` (remotes `gdrive` and `park-drive`) |
| Park mail, Drive and records | `bin/mail`, `bin/drive`, `bin/park` inside 36 only; sending mail is the owner's call |

`himalaya` on its own has no account set up (only `bin/mail` in 36 gives it one), and `moff` (Microsoft 365, 23 moff) is not installed: don't reach for either.

## Language models and other agents

Read `~/Documents/Code/10-19 Projects/35 local-models/MODELS.md` before picking a local model, and load one big model at a time. Ollama (`127.0.0.1:11434`) is the default runner; `llama-server` is for the models MODELS.md says are not in Ollama.

`codex`, `opencode`, `claude-local`, `claude-glm`, `claude-kimi` and firstmate (25, a crew of agents with its own merge flow) are other ways to run an agent: start them only when the owner asks for that one.

## Landing, sharing and keys

| Need | Tool |
|---|---|
| Land finished work on main | `/ship`, the only door. The `loom` queue (32) and the `loom-work` and `loom-refine` skills are frozen; firstmate's merge flow is not used for the owner's repos |
| A public link to something running locally | `secure-public-url` skill; `scripts/studio-public-url.sh` in 41 is for DropList only |
| A fal, Gemini or OpenAI key for a command | `products/tools/with-keys <command>` in 13 proxy-magic reads it from the Keychain; `set-key <NAME>` stores one. Never paste a key into a file |

## Writing and design

| Need | Tool |
|---|---|
| Draft or edit prose so it sounds like Ashley | `anti-ai-prose` skill |
| A pass, warn or rewrite verdict on a finished passage | `anti-ai-writing` plugin skill |
| Draw or change a screen | Paper MCP |
| The owner names Figma or gives a figma.com link | Figma MCP |
| Several directions compared before a design is settled | `design-spike` skill |

## Data that several projects fetch

| Need | Tool |
|---|---|
| Magic cards, rulings, deck checks | mtg-cards MCP. The `mtg` command in 11 is the same code; 13 holds a copy: don't add a third |
| Stock prices and financials | The Massive wrapper `glassdoor_stock/massive.py` in 17 (pages and retries on 429). 16 (`source_code/lib/data_massive.py`) and 24 (`fetch_prices.py`) have their own Massive clients: reuse one, don't write a fourth |
| Congress trades | `source_code/lib/data_quiver.py` in 16 (paid Quiver key) |
| Reddit history | `src/fetch_wsb_arctic_shift.py` in 18 (no key) |
| Warhammer core rules, stratagems, datasheets | the `npm run fetch-*` scripts in 41 army-builder |
