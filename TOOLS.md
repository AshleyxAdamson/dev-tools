# Which tool for the job

For agents. `~/.claude/CLAUDE.md` imports this file, so it is in every Claude Code session on this Mac; Codex reads the same instructions through `~/.codex/AGENTS.md` and is told there to open this file. When a job below comes up, pick from its table. Don't choose by tool name, or by whichever skill description matched first.

This file holds the jobs where more than one tool fits. Every tool found on this Mac, repo by repo, with its path and how to run it, is in `~/dev-tools/TOOLS-CATALOG.md`: read that when a job isn't here, before you write a new script for it.

A number like "33 lumr" is a folder under `~/Documents/Code/10-19 Projects/`. "50/<repo>" is a repo inside `50 losing-loonies`, which holds every LosingLoonies repo. "Run from its folder" means the tool is not on PATH: the catalog has the command.

**Keeping it true:** a new tool gets its catalog row in the same change; if it overlaps a job here it gets a row here too, and its own description names the sibling to use instead. Edit both files in `~/dev-tools` and land them with `/ship`.

## Words out of a video or a recording

| Need | Tool | Cost |
|---|---|---|
| **Words only** from YouTube, to read now: talks, podcasts, battle reports | `yt-dlp` captions, no video (command below) | Seconds per video, a few MB of text |
| YouTube words **saved for a later session** as a pebbl handoff | `ytscript` (33 lumr, run from its folder) | Seconds; writes into the current project's pebbl |
| **No captions on YouTube**, or a local audio or video file | `mlx_whisper` (`~/.local/bin`) | Local and slow; downloads the audio first |
| A recording turned into **notes** (summary, takeaways, actions) | `hammy <file>` | Local transcription, then a language model writes the notes; `--llm none` gives the transcript only |
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

Heavy local image jobs share one GPU. The image-edit MCP queues by itself and needs ComfyUI running: its `status` tool says who holds the GPU and, when ComfyUI is down, the command that starts it; `free_memory` unloads idle models. Wrap any other local job over about 10 GB in `gpu_lock.py run --label <name> --gb <N> -- <command>` (in 13 proxy-magic, `products/tools/localgen/`).

| Need | Tool | Cost |
|---|---|---|
| A new image, free and private | image-edit MCP `generate_image` (local Qwen) | Free; minutes |
| A new image from a hosted model (nano-banana, gpt-image, Seedream, Flux, Ideogram, Recraft and more) | `generate` skill | Paid per call, under its budget cap |
| Change one boxed area and keep every other pixel | image-edit MCP `edit_region`, then `judge_edit` for a verdict | Free; minutes |
| Change a whole image by instruction, **relighting and recolouring included** | image-edit MCP `edit_region` with the box set to the whole image (local Qwen-Image-Edit). Other local models: `mflux-generate-flux2-edit`, `mflux-generate-flux3-edit`. Hosted: `generate --ref <image>` | Free; about a minute for a 1024-pixel image |
| Relight a painted Magic card, or change one thing on it | `prompt_writer.py --edit-from <card> --relight` in 13 (guide: `products/painting/20.03 Relight a paint.md`) | About $0.15 a card |
| **Upscale** | `upscayl-bin` inside Upscayl.app (seven 4x models) | Free and fast; `mflux-upscale-seedvr2` only when asked |
| **Cut out** a subject or remove a background | `swift ~/dev-tools/bin/cutout.swift <image> <out.png>` (macOS Vision; `--mask` or `--crop`). Card art has its own: `pipeline cutout` in 29, `breakout_scalpel.py clip` in 13 | Free; about a second |
| Inpaint by mask, control by edge or depth, variations, try-on, train a style | `mflux-generate-fill`, `-controlnet`, `-depth`, `-redux`, `-in-context-catvton`, `mflux-train` | Free, but their weights are not downloaded: tens of GB on first use, ask first |
| Convert, resize, optimise | `magick`, `sips`, `cwebp`, `pngquant`, `ffmpeg` | Instant |
| Tag a folder of images, or search images and text by meaning | `tag_images.py` and `search.py` in 13 (`products/themes/rick-and-morty/tools/`) | Tagging defaults to a paid model; search is local |
| Magic proxy card art, sketch to print | `pipeline` (29 proxy-pipeline, run from its folder) | Stops for the owner's pick; paid and GPU steps are opt-in |

The catalog lists all 44 `mflux` commands by job. The weights already downloaded are Flux 2 klein, Flux 3 klein, ERNIE-Image Turbo, Qwen-Image 2.1 Turbo (pass `-m qwen-image-2.1-turbo`: the default model of that command is not downloaded) and Qwen-Image-Edit 2511. Use an `mflux` text-to-image command only when the owner names the model. ComfyUI (26 comfyui) holds Qwen-Image 2512 and Qwen-Image-Edit 2511 and is started by hand; the image-edit MCP and `scripts/qwen_edit.py` in 29 both drive it.

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
| Send email from any owner account | Himalaya with an explicit account and matching `From` address. Follow the steps below before composing or sending. |
| Read or search email | Himalaya with the appropriate account configuration |
| The owner's Google Calendar and Drive | The Calendar and Drive connectors |
| Google Drive from the command line | `rclone` (remotes `gdrive` and `park-drive`) |
| Park mail, Drive and records | `bin/mail` (Himalaya), `bin/drive`, and `bin/park` inside 36 |

Before an email send, check this section first. Himalaya is the only sending route. A signed-in browser, mail app, or connector never selects the sender or substitutes for Himalaya.

1. Resolve the sender from the owner's request or an explicit project convention. If neither establishes the address, ask which address to use. A recipient's address, the browser login, and the only configured account are each insufficient to choose the sender.
2. Run `account list` for the relevant Himalaya configuration and confirm the exact `From` address. With Himalaya 2, `message compose` without `--send` or `--save` can print a draft locally for this check. Pass the selected `--account` when sending and check that the message's `From` and recipients match the request.
3. Send only when the owner has authorized the message. If the intended sender cannot be verified or its account cannot send, stop and report the missing account or connection. Keep the draft for the intended sender.

On the Studio, the verified Himalaya configuration is the `park` account through `bin/mail` inside `36 Mobile-Home-Parks`. See that project's `CLAUDE.md` for its address. The wrapper is for park mail. Plain `himalaya` has no default config here, and a personal or Nimbus sending route still needs to be verified before use.

## Language models and other agents

Read `~/Documents/Code/10-19 Projects/35 local-models/MODELS.md` before picking a local model, and load one big model at a time. Ollama (`127.0.0.1:11434`) is the default runner; `llama-server` is for the models MODELS.md says are not in Ollama.

`codex`, `opencode`, `claude-local`, `claude-glm`, `claude-kimi` and firstmate (25, a crew of agents with its own merge flow) are other ways to run an agent: start them only when the owner asks for that one.

## Loom 3: landing work, long runs and the guard

Loom 3 is the owner's pipeline; its source is `~/factory/agentbox` (`LOOM3.md`). The catalog lists every piece, `/state`, `/longrun` and `/checkup` included.

| Need | Tool |
|---|---|
| Land finished work on main | `/ship`, the only door. "Loom" means Loom 3. The old `loom` queue (32) is retired and its skills are gone; firstmate's merge flow is not used for the owner's repos |
| A command was blocked | That is the guard hook on every shell command and file write. It stops pushes and PRs the owner didn't ask for, destructive git and delete commands, admin commands and reads of key files. Don't route around it: write the friction line from the global instructions and carry on |
| A change inside `~/factory/agentbox` | `make test` there before `/ship` |
| A public link to something running locally | `secure-public-url` skill; `scripts/studio-public-url.sh` in 41 is for DropList only |
| A fal, Gemini or OpenAI key for a command | `products/tools/with-keys <command>` in 13 proxy-magic reads it from the Keychain; `set-key <NAME>` stores one. Never paste a key into a file |

## Notes, links and documents in

There is no general store where a note or a document goes in and is found later. Pick by what it is, and say so if none fits:

| What | Tool |
|---|---|
| A link to learn from later | `learn add "<link> <why>"`, or the `learn-later` skill |
| A note on something read or watched once (health, career, business) | A numbered note in 38 life-management, in the area it is about; its `AGENTS.md` has the format |
| A decision, a dead end or a handoff in a project | `pebbl log`, `pebbl handoff`; find it with `pebbl search` |
| A standing fact about the owner or how to work | The Claude memory files for that project |
| Park notes, meetings and recordings | `bin/park log`, `meeting new`, `transcribe` in 36 |
| Lore for a world | the `lore-build` skill and `tools/search.py` in 21 lore-builder |
| Documents with search by meaning | Only Odysseus (35 local-models) is built for it, and it is not running and its skill is not installed: ask the owner |

## Reports, decks, charts, sound and capture

| Need | Tool |
|---|---|
| A research report of several files as one designed PDF, with cover and contents | `render_pdf.py` in the `research-planner` skill (run line in the catalog) |
| The sources in a cited report checked again by fresh agents | `verify-citations.md` in the `research-planner` skill |
| A plan as a clean PDF | `print.sh` in 38 life-management (`00-09 System/01 Tools/01.01 Print to PDF/`) |
| Any HTML page as a PDF | Brave, headless, with its print-to-PDF flag; Chrome is not installed |
| A slide deck | The Slides artifact type in the Claude app; the `pptx` skill only when a PowerPoint file is asked for |
| A Word, PowerPoint, Excel or PDF file | the `docx`, `pptx`, `xlsx` and `pdf` skills. LibreOffice and their Python and Node libraries are not installed on this Mac, so their build and check scripts will not run as they stand: say so before promising one |
| A chart | Read the `dataviz` skill first, then an Artifact or the chart tool |
| An animated chart as a video with sound | `source_code/lib/animation.py` in 50/congress-trading-investigation |
| Sound effects made without samples | `audio_engine` in 50/congress-trading-investigation |
| A screenshot of one Mac window | `scripts/capture.swift` in 22 tavern |
| A rendered web page copied into Paper as layers | `to-paper.mjs` in 12 portfolio (`tools/explorer-reel`) |

## The YouTube channel

All in 33 lumr, run from its folder (commands in the catalog). The YouTube login is not set up on this Mac, so every row marked "login" fails until the owner signs in with `clipforge youtube login`; uploading and changing a live video are the owner's call.

| Need | Tool |
|---|---|
| Title, description, chapters and tags for a video | `clipforge publish prepare` writes the edited transcript into a kit folder; write the four from it, then `clipforge publish check` validates them. The lumr-studio `publish_kit` extra saves the same kit and is off by default |
| A thumbnail: pick frames from the video, add the text | `clipforge publish frames`, then `clipforge publish compose` |
| Put the kit on a video | `clipforge publish push` (login; dry run unless told to apply) |
| Upload privately with a later public date | `clipforge.youtube_upload` (login) |
| Titles that follow the channel's own patterns | `clipforge.creator_profile --learn` (login) |
| How videos performed | `dataforge`: load a YouTube Studio export with `load_analytics_csv`, then `get_top_videos` and `record_retention_audit`. No data is loaded on this Mac, and nothing here calls YouTube for analytics |
| Script and shorts structure | `youtube-narrative-guide/` and `shortform-narrative-guide/` |

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
| Stock prices and financials | The Massive wrapper `glassdoor_stock/massive.py` in 50/Glassdoor-AI-Stock-Trader (pages and retries on 429). 50/congress-trading-investigation (`source_code/lib/data_massive.py`) and 50/Satellite_Stock_Predictor (`fetch_prices.py`) have their own Massive clients: reuse one, don't write a fourth |
| Congress trades | `source_code/lib/data_quiver.py` in 50/congress-trading-investigation (paid Quiver key) |
| Whether a backtest result is real | `run_significance.py` and `research/gate.py` in 50/LSTM_AI_Stock_Predictor, before believing any strategy claim |
| Insider buys from SEC filings | `TrainingData/featuresPy/insiderbuying.py` in 50/LSTM_AI_Stock_Predictor (no key) |
| Stock tickers mentioned in text | `src/extract_tickers.py` in 50/WallStreetBets-Stock-Bot |
| Reddit history | `src/fetch_wsb_arctic_shift.py` in 50/WallStreetBets-Stock-Bot (no key) |
| Warhammer core rules, stratagems, datasheets | the `npm run fetch-*` scripts in 41 army-builder |
