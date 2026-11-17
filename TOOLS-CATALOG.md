# Tool catalog

For agents. Every tool found on this Mac, by where it lives. `~/dev-tools/TOOLS.md` says which one to pick when several fit; this file says what exists and how to run it. Read it before writing a new script for a job that may already be solved.

`P/` is `~/Documents/Code/10-19 Projects/`. "Anywhere" means on PATH, a skill in `~/.claude/skills`, an enabled plugin, or a registered MCP server. "Folder" means run it from its project folder with the command shown. Last swept 2026-11-16.

## Usable anywhere

### Skills

| Skill | Source | Does |
|---|---|---|
| `activity-check` | `~/dev-tools/skills` | Diagnose a hot, slow or draining Mac |
| `anti-ai-prose` | `~/dev-tools/skills` | Draft or edit prose in Ashley's voice |
| `design-spike` | `~/dev-tools/skills` | Several design directions as HTML mockups, critiqued |
| `flare-strategy` | `~/dev-tools/skills` | Advice on forward-looking retrieval for an agent |
| `generate` | `~/dev-tools/skills` | Paid image and video generation with a budget cap |
| `research-planner` | `~/dev-tools/skills` | Multi-phase research with checked citations |
| `skill-builder` | `~/dev-tools/skills` | Build or audit a skill |
| `video-grab` | `~/dev-tools/skills` | Screens, transcript and file from a YouTube video |
| `learn-later`, `socratic-tutor` | `P/44 learn-later/skills` | Learning queue; structured tutoring |
| `ship`, `state`, `longrun`, `checkup` | `~/.claude/skills` | Land work on main; show leftovers; long runs; weekly pipeline repair |
| `secure-public-url` | `~/.claude/skills` | Publish a local service through Tailscale Funnel, sandboxed |
| `grilling` (`grill-me` calls it), `tdd`, `pr`, `retro`, `show-me`, `writing-for-agents` | `~/.claude/skills` | Interview a plan; test-first work; PR body; retrospective; visual explainer; docs for agents |
| `assemble-takes`, `splice-clips`, `tight-cut`, `ui-feedback`, `what-to-cut` | lumr-studio plugin | Video editing on one source video |
| `anti-ai-writing`, `deal-chart`, `doctorg`, `longevity-scholar`, `aubrai-longevity`, `docx`, `pdf`, `pptx`, `xlsx`, `docs`, `google-workspace` and the rest | `~/.claude/skills/synced` | Skills synced from the Claude account |

### MCP servers and plugins

| Name | Source | Does |
|---|---|---|
| mtg-cards | `P/11 MTG-Deck-Builder` | Magic card search, rulings, tags, deck checks, art choice and print orders |
| image-edit | `P/13 proxy-magic/products/tools/localgen/server.py` | Local image generation, region edits, edit judging, reading text and mana costs |
| paper | Paper app at `127.0.0.1:29979` | Read and write designs; down when the app is closed |
| lumr-studio plugin | `P/33 lumr/studio/plugins/lumr-studio` (clone at `~/lumr-studio`) | Transcribe, cut, assemble and render one video |
| Gmail, Calendar, Drive, Figma, Claude in Chrome, built-in browser | The Claude app | Connectors; not configured in `~/.claude.json` |

### Commands on PATH

| Command | Does | State |
|---|---|---|
| `pebbl` | Project memory: decisions, handoffs, search | Runs the `~/factory/pebbl` clone; source in `P/34 pebbl` |
| `learn` | Learning queue (`add`, `list`, `done`, `friday`) | Runs `P/44 learn-later/learn.py` |
| `yt-dlp` | Download video, audio or captions | Ready |
| `mlx_whisper` | Local speech to text | Ready |
| `mflux-*` (44) | Local image models: Flux, Z-Image, Qwen, Krea, upscale, training | Ready |
| `ollama`, `llama-server`, `llama-cli` | Local language models | Ollama always running on `127.0.0.1:11434` |
| `claude-local`, `claude-glm`, `claude-kimi` | Claude Code on Ollama, GLM, Kimi | From `~/factory/agentbox/bin`; on request only |
| `codex`, `opencode` | Other agent runners | On request only |
| `rclone` | Cloud files | Remotes `gdrive`, `park-drive` (Google Drive) |
| `himalaya` | Mail from the command line | No account of its own; `P/36 Mobile-Home-Parks/bin/mail` supplies one |
| `ffmpeg`, `pdftotext` and `pdftoppm` (poppler), `jq`, `rg`, `fd`, `bat`, `tree`, `wget`, `shellcheck` | Media, PDF, search and shell helpers | Ready |
| `gh` | GitHub | Signed in |
| `tailscale` | Tailnet and Funnel | Active; use it through `secure-public-url` |
| `macmon` | Apple Silicon CPU and GPU monitor | Ready |
| `uv`, `bun`, `pnpm`, `fnm`, `rustup`, `tmux`, `direnv`, `geckodriver` | Runtimes and helpers | Ready |

Apps with no command of their own: Upscayl (image upscale, used by the card print steps), Odysseus (local AI workspace), Obsidian, Ghostty, Spokenly.

## Home-root repos

| Repo | Tool | Run | Does |
|---|---|---|---|
| `~/dev-tools` | `bin/jd-check.sh` | `~/dev-tools/bin/jd-check.sh` | Checks folder names against the Johnny Decimal rules |
| | `bin/tag-check.py` | `~/dev-tools/bin/tag-check.py` | Lists Obsidian tags outside the allowed branches |
| | `bin/check-dev-tools-health.sh` | — | Broken: written for `/Users/ashley`, which is not this Mac's user |
| | `bin/vault-sync.sh` | — | Broken: needs `~/Dropbox`, which does not exist |
| | `bin/obsidian-theme.sh` | `~/dev-tools/bin/obsidian-theme.sh [--install\|--pull]` | Compares the Obsidian theme in the repo with the vault's copy; copies one over the other |
| | `bin/agent-deck-fix-session-paths.sh` | — | One-off repoint of agent-deck sessions from `/Users/ashley`; agent-deck is not installed here |
| | `statusline/statusline.sh` | — | The Claude Code status line; not linked into `~/.claude` or set in its settings on this Mac |
| | skills `loom-work`, `loom-refine` | — | Frozen with the loom queue; not linked into `~/.claude/skills` |
| `~/factory/agentbox` | `claude/hooks/guard.sh` | runs on every Bash, Write and Edit | The guard: blocks unasked PRs, `git add -A` and the like |
| | `ops/health.sh`, `lobby-up.sh`, `maintenance.sh`, `notify.sh`, `lock-screen.sh` | run by launchd | Host health, Remote Control lobby, weekly updates, Telegram notice, screen lock |
| `~/factory/model-check` | `run.sh` | run by launchd | Scheduled check of the image and embedding model picks |
| `~/factory/logs` | `friction.log` | append one line | Where pipeline trouble is recorded for `/checkup` |

## Project repos

| Project | Tool | Run (from the project folder, or the folder the Tool column names) | Does |
|---|---|---|---|
| 11 MTG-Deck-Builder | `mtg` | `uv run mtg search\|card\|rulings\|ideas\|check\|update\|art\|gallery\|print` | Same functions as the mtg-cards MCP |
| | skills `commander-deck`, `print-deck` | load inside 11 or 13 | Build a Commander deck; order proxy prints |
| 12 portfolio | `tools/explorer-reel` | `node record.mjs [id]`, `node composite.mjs` | Record HTML prototypes as video; `lib.mjs` is the shared recorder |
| | `tools/deck-reel`, `tools/meridian-reel` | `node record.mjs` | Record Paper frames, or the live Meridian prototype, as video |
| 13 proxy-magic | `products/tools/with-keys`, `set-key` | `with-keys <command>`; `set-key <NAME>` | Run a command with API keys from the Keychain; store a key |
| | `vendor/tcg-mint` (`mint`) | see its README | Render card images from card data through headless Chromium |
| | theme tools in `products/themes/rick-and-morty/tools/` | from the theme folder, e.g. `python3 -I tools/grab_episodes.py --fetch S1E6` | Episode screen grabs, reference-image search, image tagging, bible search |
| | skills `card-round`, `friend-review`, `lore-pass`; agent `card-art-director` | inside `products/` | Card painting rounds and reviews for that deck |
| | copy of `mtg` | — | Duplicate of 11; use 11 |
| 15 LSTM_AI_Stock_Predictor | `run_live_signals.py`, `run_backtest_v4.py`, `research/evaluate.py` | `python <file>` | Stock forecaster and its sealed-holdout evaluation |
| 16 congress-trading-investigation | `audio_engine` | `from audio_engine import Cue, render_track` | Synthesised sound effects and track mixing, no samples |
| | `source_code/lib/data_quiver.py`, `source_code/show_trades.py` | `python source_code/show_trades.py [--all] [--csv f]` | Congress trades from Quiver (paid key) |
| 17 Glassdoor-AI-Stock-Trader | `glassdoor_stock/massive.py`, `prices.py` | Python import | Prices and financials from Massive, with paging and retry |
| | `download_glassdoor_dataset.py` | `python download_glassdoor_dataset.py` | Kaggle review dataset (Kaggle login) |
| 18 WallStreetBets-Stock-Bot | `src/fetch_wsb_arctic_shift.py` | `python -m src.fetch_wsb_arctic_shift --start D --end D --out f.parquet` | Subreddit history through Arctic Shift, no key |
| 19 Intrinsic-Value-Monitor | notebooks `0-create_list`, `1-produce_data`, `2-backtest` | Jupyter | Graham intrinsic-value backtest |
| 21 lore-builder | `tools/build_index.py`, `search.py`, `check_pass.py` | `python3 -I tools/search.py "<q>"`; `--root` takes any lore folder | Index, search and check a lore bible |
| | skills `lore-setup`, `lore-build`, `lore-check`, `lore-pass` | inside the kit | Start, grow, audit and apply a lore bible |
| 22 tavern | `scripts/phone.sh`, `bundle.sh` | `scripts/phone.sh` | Build the Tavern app; run its iOS app in the Simulator |
| | `bridge/tavern-durable` | `./setup.sh; ./run.sh <agent>` | Host one durable agent session on a local port |
| 23 moff | `moff` | not installed | Microsoft 365 from the command line through a signed-in Safari tab; also an MCP server |
| 24 Satellite_Stock_Predictor | `fetch_prices.py` | `python fetch_prices.py [TICKERS] --start D` | Daily closes from Massive |
| | `label_tanks.py`, `measure_tanks.py` | `python <file>` | Measure oil tank fill from satellite images |
| 25 firstmate | firstmate | start an agent with this folder as its working directory | One agent that runs a crew of agents in worktrees; about 250 `bin/fm-*` scripts and 30 skills of its own |
| | `bin/fm-mail.sh`, `bin/fm-lavish-url.sh` | `bin/fm-mail.sh read`; `bin/fm-lavish-url.sh snapshot <url>` | Mail client; web page review snapshot |
| 26 comfyui | ComfyUI server | `.venv/bin/python main.py --port 8188` | Node-based image generation with an HTTP API; started by hand |
| 28 NerdoDivergent | `bin/pebbl-check` | Stop hook | Holds a session that changed files without a pebbl entry |
| 29 proxy-pipeline | `pipeline` | `uv run pipeline <doctor\|cards\|theme\|paper-art\|cutout\|compose\|board\|studio> ...` | Layered Magic proxy card pipeline, sketch to print |
| | `scripts/qwen_edit.py` | `.venv/bin/python scripts/qwen_edit.py --image1 a.png --prompt "..." --out out.png` | One Qwen image edit through a running ComfyUI |
| 31 fairland-rv-census | `scripts/stac_inventory.py` | `uv run python scripts/stac_inventory.py` | Lists aerial and satellite scenes over an area, no key |
| 32 loom | `loom` | — | Frozen 2026-11-09; do not run |
| 33 lumr | `ytscript` | `uv run --project "P/33 lumr/ytscript" ytscript <url-or-id> [--timestamps --no-handoff]` | YouTube transcript saved as a file and a pebbl handoff |
| | `hammy` | `uv run --project "P/33 lumr/hammy" hammy <file>` | Transcribe a recording into notes: summary, takeaways, actions |
| | `clipforge` | `uv run --project "P/33 lumr/clipforge" clipforge <file-or-url> [--num-clips 3]` | Long video into vertical shorts: highlights, reframe, subtitles |
| | `bookforge` | `python3 -m bookforge.forge manuscript.md`; skill in `bookforge/skill` | Book and script writing with search over transcripts; its skill still points at `/Users/ashley` paths |
| | `anti-ai-writing/anti_ai_checker.py` | `python3 anti_ai_checker.py` | The checker behind the `anti-ai-writing` skill |
| | `youtube-narrative-guide/`, `shortform-narrative-guide/` | read | Narrative frameworks for scripts and shorts |
| 34 pebbl | `ops/check-memory-health.sh` | `bash ops/check-memory-health.sh` | Checks and repairs pebbl stores |
| 35 local-models | `MODELS.md` | read | Installed models and which one for what |
| | Unlimited OCR 2 | run line in `MODELS.md` | Document OCR with block positions |
| | Code2Video model | `llama-server` line in `MODELS.md` | The model that writes code for videos; not in Ollama |
| | skill `code-video` | start an agent inside `code-video-studio/` | Render a video from code to MP4, with checks and narration |
| | Odysseus | `odysseus-app/build.sh`; server on `127.0.0.1:7860` | Self-hosted chat, notes, mail and calendar workspace; its Claude skill is not installed |
| 36 Mobile-Home-Parks | `bin/park` | `bin/park status\|todo\|log\|meetings\|transcribe` | Park logs, profiles and meetings; `transcribe` wraps `mlx_whisper` |
| | `bin/mail` | `bin/mail envelope list` | `himalaya` on the park mail account; can send |
| | `bin/drive` | `bin/drive ls\|find\|text <file>` | Read-only Google Drive through `rclone`; converts files to text |
| | `bin/ocr.swift` | `swift bin/ocr.swift page.png` | Text from an image with macOS Vision |
| 37 snap-vocab | `spike/run.ts`, `server/index.ts` | `npm run spike`, `npm run dev` | Photo to vocabulary card (paid APIs) |
| 39 house-hunt | `scripts/build_pdf.py`, `build_tour_pdf.py`, `build_review.py` | `scripts/.venv/bin/python scripts/build_pdf.py` | House shortlist reports as PDF; `scripts/.venv` is not built on this Mac, so install `scripts/requirements.txt` into it first |
| 41 army-builder | `fetch-core-rules`, `fetch-stratagems`, `fetch-datasheets`, `fetch-meta` | `npm run <name>` | Warhammer rules, stratagems, datasheets and tournament stats |
| | `ocr-codex` | `npm run ocr-codex -- <pdf>` | OCR of codex photos with macOS Vision and deskew |
| | `icons`, `portraits` | `npm run icons` | Unit art into web masks and images |
| | `scripts/studio-public-url.sh`, `deploy-studio.sh` | `scripts/studio-public-url.sh [--rotate\|--off]` | Deploy DropList and publish its link |
| 42 real-voice | speak app | `uv run python -m speak.app` in `prototype/` | Local text to speech at `127.0.0.1:8840`; can feed a virtual mic |
| | `likeness/add_voice.py` | `uv run python likeness/add_voice.py me <recording.m4a> --mine` | Clone a voice from about 90 seconds of audio |
| 43 color-builder | `scripts/build-paints.mjs` | `npm run paints` | Paint tables into the app's data file |
| 44 learn-later | `learn.py` | `learn` | The learning queue; Friday digest by launchd |

No tools: 14, 20 (empty), 30 (reports only), 38, 40 (app code only).

## Scheduled jobs (launchd)

| Label | Runs | When |
|---|---|---|
| `com.agentbox.health` | `ops/health.sh` | Every 5 minutes |
| `com.agentbox.lobby` | Remote Control lobby in tmux | Every 2 minutes |
| `com.agentbox.lock` | `ops/lock-screen.sh` | At login |
| `com.agentbox.maintenance` | brew and Claude Code updates | Sunday 04:00 |
| `com.learnlater.friday` | `learn.py` Friday digest | Friday 17:00 |
| `com.proxymagic.gpu-lock-check` | GPU lock check for image-edit | Every 2 minutes |
| `com.proxymagic.model-check` | `~/factory/model-check/run.sh` | 1st of each month, 09:10 |
| `com.proxymagic.sync-refs` | reference sync in 13 | 03:30; failing, macOS blocks it from `~/Documents` |
| `sh.brew.ollama` | Ollama | Always |
