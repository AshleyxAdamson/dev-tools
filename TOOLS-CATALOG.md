# Tool catalog

For agents. Every tool found on this Mac, by where it lives. `~/dev-tools/TOOLS.md` says which one to pick when several fit; this file says what exists and how to run it. Read it before writing a new script for a job that may already be solved.

`P/` is `~/Documents/Code/10-19 Projects/`. "Anywhere" means on PATH, a skill in `~/.claude/skills`, an enabled plugin, or a registered MCP server. "Folder" means run it from its project folder with the command shown. Last swept 2026-11-16.

## Usable anywhere

### Skills

| Skill | Source | Does |
|---|---|---|
| `activity-check` | `~/dev-tools/skills` | Diagnose a hot, slow or draining Mac |
| `anti-ai-prose` | `~/dev-tools/skills` | Draft or edit prose in Ashley's voice. `python3 ~/.claude/skills/anti-ai-prose/anti_ai_checker.py <file>` gives a pass, warn or rewrite verdict with the flagged patterns |
| `design-spike` | `~/dev-tools/skills` | Several design directions as HTML mockups, critiqued |
| `flare-strategy` | `~/dev-tools/skills` | Advice on forward-looking retrieval for an agent |
| `generate` | `~/dev-tools/skills` | Paid image and video generation with a budget cap: `python3 ~/.claude/skills/generate/scripts/generate.py --model M --prompt "..." [--ref IMAGE --n N --aspect 1:1 --budget B --max-cost C --out DIR --dry-run]`. Images: nano-banana, nano-banana-pro, nano-banana-2, gpt-image-2, ideogram-v3, seedream-4.5, seedream-5-pro, flux-2-pro, flux-3, flux-kontext-multi (needs `--ref`), recraft-v3, qwen-image, hidream, z-image. Video: kling, seedance. Keys come from the environment, then the Keychain. No upscale or relight job |
| `research-planner` | `~/dev-tools/skills` | Multi-phase research with checked citations. Inside it: `render_pdf.py` (a folder of numbered Markdown files into one designed PDF: `DYLD_FALLBACK_LIBRARY_PATH=$(brew --prefix)/lib uv run --with weasyprint --with markdown python ~/.claude/skills/research-planner/render_pdf.py --dir "<folder>" --title "..." [--theme care\|default --out FILE --no-open]`), `verify-citations.md` (fresh agents re-check every source), `packaging.md` (report skeleton and folder rules). It makes no slide decks |
| `skill-builder` | `~/dev-tools/skills` | Build or audit a skill |
| `video-grab` | `~/dev-tools/skills` | Screens, transcript and file from a YouTube video. `scripts/grab.py search "<query>"`, `fetch <url> --out <dir>`, `at <video-folder> <times>` (exact frames from a video already fetched) |
| `learn-later`, `socratic-tutor` | `P/38 life-management/00-09 System/01 Tools/01.02 Learn later/skills` | Learning queue; structured tutoring |
| `ship`, `state`, `longrun`, `checkup` | `~/.claude/skills` | Land work on main; show leftovers; long runs; weekly pipeline repair |
| `secure-public-url` | `~/.claude/skills` | Publish a local service through Tailscale Funnel, sandboxed |
| `grilling` (`grill-me` calls it), `tdd`, `pr`, `retro`, `show-me`, `writing-for-agents` | `~/.claude/skills` | Interview a plan; test-first work; PR body; retrospective; visual explainer; docs for agents |
| `assemble-takes`, `splice-clips`, `tight-cut`, `ui-feedback`, `what-to-cut` | lumr-studio plugin | Video editing on one source video |
| `anti-ai-writing`, `deal-chart`, `doctorg`, `longevity-scholar`, `aubrai-longevity`, `docx`, `pdf`, `pptx`, `xlsx`, `docs`, `google-workspace`, `skill-creator` and the rest | `~/.claude/skills/synced` | Skills synced from the Claude account. Their scripts include PDF form filling (`pdf`), deck text and thumbnails (`pptx`), tracked changes and comments (`docx`), formula recalculation (`xlsx`), a contract table builder (`deal-chart`). LibreOffice, pandoc and the Python and Node libraries they import are not installed on this Mac |

### MCP servers and plugins

| Name | Source | Does |
|---|---|---|
| mtg-cards | `P/11 MTG-Deck-Builder` | Magic card search, rulings, tags, deck checks, art choice and print orders |
| image-edit | `P/13 proxy-magic/products/tools/localgen/server.py` | `generate_image`, `edit_region`, `judge_edit` (verdict on a before and after), `read_text`, `read_mana`, `replace_mana` (redraw a card's mana cost), `plan_card_edit`, `card_edit_status`, `status` (who holds the GPU), `free_memory` |
| paper | Paper app at `127.0.0.1:29979` | Read and write designs; down when the app is closed |
| lumr-studio plugin | `P/33 lumr/studio/plugins/lumr-studio` (clone at `~/lumr-studio`) | Transcribe, cut, assemble and render one video |
| Gmail, Calendar, Drive, Figma, Claude in Chrome, built-in browser | The Claude app | Connectors; not configured in `~/.claude.json` |

### Commands on PATH

| Command | Does | State |
|---|---|---|
| `pebbl` | Project memory: decisions, handoffs, search | Runs the `~/factory/pebbl` clone; source in `P/34 pebbl` |
| `learn` | Learning queue (`add`, `list`, `done`, `friday`) | Runs `P/38 life-management/00-09 System/01 Tools/01.02 Learn later/learn.py` |
| `hammy` | A recording into a transcript and notes: `hammy <file> [--output DIR --llm claude_code\|ollama\|none --word-timestamps]` | Runs `P/33 lumr/hammy` with its Mac models; notes go to `~/Lumr/hammy/stash` unless `--output` is given |
| `yt-dlp` | Download video, audio or captions | Ready |
| `mlx_whisper` | Local speech to text | Ready |
| `mflux-*` (44) | Local image models; every command is in the section "mflux commands" below | Ready; most weights are not downloaded |
| `magick`, `pngquant`, `sips`, `cwebp`, `dwebp`, `cjpeg` | Convert, resize and compress images | Ready; rembg is only inside the 29 proxy-pipeline environment |
| `ollama`, `llama-server`, `llama-cli` | Local language models | Ollama always running on `127.0.0.1:11434` |
| `claude-local`, `claude-glm`, `claude-kimi` | Claude Code on Ollama, GLM, Kimi | From `~/factory/agentbox/bin`; on request only |
| `codex`, `opencode` | Other agent runners | On request only |
| `rclone` | Cloud files | Remotes `gdrive`, `park-drive` (Google Drive) |
| `himalaya` | Mail from the command line | Works through `P/36 Mobile-Home-Parks/bin/mail`, which passes the park account's config; plain `himalaya` has no config file |
| `ffmpeg`, `pdftotext` and `pdftoppm` (poppler), `jq`, `rg`, `fd`, `bat`, `tree`, `wget`, `shellcheck` | Media, PDF, search and shell helpers | Ready |
| `gh` | GitHub | Signed in |
| `tailscale` | Tailnet and Funnel | Active; use it through `secure-public-url` |
| `macmon` | Apple Silicon CPU and GPU monitor | Ready |
| `uv`, `bun`, `pnpm`, `fnm`, `rustup`, `tmux`, `direnv`, `geckodriver` | Runtimes and helpers | Ready |

Apps: Upscayl has a command inside it, `/Applications/Upscayl.app/Contents/Resources/bin/upscayl-bin -i IN -o OUT -m /Applications/Upscayl.app/Contents/Resources/models -n ultrasharp-4x -s 4 -f png` (models: digital-art, high-fidelity, remacri, ultramix-balanced, ultrasharp, upscayl-lite, upscayl-standard, all 4x). Brave prints HTML to PDF headless. No command of their own: Odysseus (local AI workspace, not running), Obsidian (vault holds one note), Ghostty, Spokenly.

## mflux commands

All 44, version 0.23.0. Output is `image.png` in the current folder unless `--output` is given. Common flags: `--prompt`, `--seed`, `--steps`, `--width`, `--height`, `-q 3|4|5|6|8` (less memory), `--lora-paths`, `--low-ram`. "Here" means the weights are already downloaded; every other command downloads tens of GB on first use, so ask first.

| Job | Commands | Weights |
|---|---|---|
| New image from text | `mflux-generate-flux2` (Flux 2 klein), `mflux-generate-flux3` (Flux 3 klein), `mflux-generate-ernie-image-turbo`, `mflux-generate-qwen-2.1 -m qwen-image-2.1-turbo` | Here |
| | `mflux-generate` (Flux 1), `mflux-generate-qwen`, `mflux-generate-ernie-image`, `mflux-generate-z-image`, `mflux-generate-z-image-turbo`, `mflux-generate-krea2`, `mflux-generate-boogu`, `mflux-generate-lens`, `mflux-generate-ming` (transparent design assets), `mflux-generate-ideogram4` (text in images; licence click needed), `mflux-generate-fibo` (structured prompts) | Not here |
| Edit by instruction | `mflux-generate-flux2-edit --image-paths IN --prompt "..."`, `mflux-generate-flux3-edit` (up to 10 reference images), `mflux-generate-qwen-2.1-edit -m qwen-image-2.1-turbo` | Here |
| | `mflux-generate-qwen-edit` (its default model is not here; the 2511 weights are, as `mflux-community/qwen-image-edit-2511-mflux-q8`), `mflux-generate-kontext`, `mflux-generate-in-context-edit`, `mflux-generate-fibo-edit` (also removes backgrounds) | Not here |
| Inpaint by mask | `mflux-generate-fill --image-path IN --masked-image-path MASK` | Not here |
| Control by edge or depth | `mflux-generate-controlnet`, `mflux-generate-depth`, `mflux-generate-krea2-controlnet`, `mflux-generate-z-image-controlnet`, `mflux-generate-qwen-2.1-controlnet` (a control image, an inpaint mask, or both) | Not here |
| Depth map of an image | `mflux-save-depth --image-path IN` | Not here |
| Variations and references | `mflux-generate-redux`, `mflux-generate-in-context` | Not here |
| Virtual try-on | `mflux-generate-in-context-catvton --person-image --person-mask --garment-image` | Not here |
| Upscale | `mflux-upscale-seedvr2 --image-path IN --resolution 2x`, `mflux-upscale-controlnet` | Not here |
| Concept heatmap | `mflux-concept`, `mflux-concept-from-image` | Not here |
| Prompt from an image, refine a prompt | `mflux-inspire-fibo`, `mflux-refine-fibo` | Not here |
| Train a style | `mflux-train --config FILE [--dry-run]`; `mflux-lora-library list` | No model needed to list |
| Housekeeping | `mflux-save` (save a smaller copy of a model), `mflux-info IMAGE` (how an image was made), `mflux-capabilities`, `mflux-completions` | `mflux-save` needs the model's weights; the others need no model |


## Loom 3 (source: `~/factory/agentbox`)

| Piece | Where | Does |
|---|---|---|
| `/ship` | `~/.claude/skills/ship` (`ship.sh check`, `ship.sh land`, `keep.sh`) | Commit by path, tests, a fresh reviewer fixes the diff, merge to main, push, remove the worktree and branch |
| `/state` | `~/.claude/skills/state/state.sh` | Leftover branches, worktrees, uncommitted and unpushed work across every project; `tidy` removes only what is already on main |
| `/longrun` | `~/.claude/skills/longrun` (`longrun.sh` paces it under Codex) | One goal over hours: one move per wake, landed with `/ship`, pebbl as the baton |
| `/checkup` | `~/.claude/skills/checkup` | Weekly repair from the friction log: at most three fixes, each with a test |
| guard | `claude/hooks/guard.sh`, `guard.py`; wired for Claude Code and Codex | Checks every shell command and file write; blocks are logged in `~/factory/logs/guard.log` |
| global instructions | `claude/CLAUDE.md`, live at `~/.claude/CLAUDE.md`; `~/.codex/AGENTS.md` links to it | The owner's rules, and the import of `TOOLS.md` |
| friction log | `~/factory/logs/friction.log` | One line per time the pipeline got in the way |
| installers | `claude/install.sh`, `codex/install.sh` | Dry run by default; `--apply` wires the guard, skills and instructions |
| tests | `make test` in `~/factory/agentbox` | Guard, ship, install and longrun tests; `tests/codex_live_test.sh` is separate and costs money |
| Remote Control lobby | `ops/lobby-up.sh`, launchd `com.agentbox.lobby` | Keeps a tmux session ready so phone sessions start in the Projects folder |
| health, notify | `ops/health.sh`, `ops/notify.sh` | Host checks every 5 minutes; Telegram notices, which are not configured, so messages pile up in `notify-undelivered.log` |
| retired | `P/32 loom` | The old queue, stopped 2026-11-09; never run it. Its `loom-work` and `loom-refine` skills were deleted 2026-11-16 |

## Where notes and documents are kept

| Store | Put in with | Find with | State |
|---|---|---|---|
| Learning queue | `learn add` | `learn list`; Friday digest | Works from any folder; links only |
| Life notes | a numbered note in `P/38 life-management`, in the area it is about; its `AGENTS.md` has the format | the index in its `README.md` | Works; one note per thing read or watched (health, career, business) |
| pebbl, per repo | `pebbl log`, `pebbl handoff` | `pebbl search`, `pebbl context` | Works; one-line decisions, not documents |
| Claude memory, per project | the agent writes files under `~/.claude/projects/<project>/memory/` | Loaded each session | Works; `import-memory` and `consolidate-memory` skills manage it |
| Park logs and meetings | `bin/park` in `P/36` | `park status`, `park todo` | Works; parks only |
| Lore bible | `lore-build` skill in `P/21` | `tools/search.py` | Works; one world per copy of the kit |
| Odysseus | its app: notes, documents, mail, memory | its own search | Not running; its Claude skill is not installed |
| bookforge transcript store | `bookforge/bookforge/ingest.py` in `P/33 lumr` | its search | Gone: no database on this Mac |
| Obsidian vault | `~/Documents/Obsidian Vault` | Obsidian | Holds one note |

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
| | `bin/cutout.swift` | `swift ~/dev-tools/bin/cutout.swift <image> <out.png> [--mask \| --crop]` | Remove the background from any image with macOS Vision; local, about a second |
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
| | `tools/explorer-reel/probe.mjs` | `node probe.mjs <page> [width] [--scene]` | Load a page; print its accessibility snapshot and take a screenshot |
| | `tools/explorer-reel/to-paper.mjs` | `node to-paper.mjs --file <id> --page <id> --name N <page.html#selector>` | Copy a rendered page into Paper as editable layers; Paper must be open |
| 13 proxy-magic | `products/tools/with-keys`, `set-key` | `with-keys <command>`; `set-key <NAME>` | Run a command with API keys from the Keychain; store a key |
| | `vendor/tcg-mint` (`mint`) | see its README | Render card images from card data through headless Chromium |
| | theme tools in `products/themes/rick-and-morty/tools/` | from the theme folder, e.g. `python3 -I tools/grab_episodes.py --fetch S1E6` | Episode screen grabs, reference-image search, image tagging, bible search |
| | skills `card-round`, `friend-review`, `lore-pass`; agent `card-art-director` | inside `products/` | Card painting rounds and reviews for that deck |
| | copy of `mtg` | — | Duplicate of 11; use 11 |
| | `products/tools/localgen/gpu_lock.py` | `python3 gpu_lock.py status`; `python3 gpu_lock.py run --label X --gb N -- <command>` | The machine-wide GPU queue: heavy local jobs run one at a time, in arrival order |
| | `products/tools/layout.py`, `layout_check.py` | `python3 layout.py plan`; `python3 layout_check.py <card> <layout.json>` | Plan a card's panels and draw the guide image; measure drift |
| | `proxymagic/printing/upscale.py` | through `mtg print` or the mtg-cards `print_deck` tool | Upscale card art with Upscayl to print size with bleed |
| | card painting, in `products/themes/rick-and-morty/` | `tools/card_round.py decks/<deck> "<Name>"` | The entry point for painting one card; `polish.py` adds title, mana and text and upscales; `review_board.py` is the review page |
| | `tools/prompt_writer.py` (same theme) | `--paint`; `--edit-from <card> --edit-prompt <file>`; `--edit-from <card> --relight`; `--cutout-test <art>` | Paint, edit, relight or cut out card art through fal (paid, about $0.15 a card) |
| | `tools/breakout_scalpel.py` (same theme) | `clip --segment vision` | Cut a subject out and lay it over the frame; macOS Vision is the free option |
| | `tools/tag_images.py`, `search.py`, `find_refs.py`, `print_prep.py` (same theme) | run from the theme folder | Tag reference images; search bible and images by meaning (local embeddings); find reference images; print files at 800 dpi with bleed |
| | `tools/paper_mcp.py` (same theme) | Python import | A plain client for Paper's server, so a script can write to Paper |
| 50 losing-loonies/LSTM_AI_Stock_Predictor | `run_live_signals.py`, `run_backtest_v4.py`, `research/evaluate.py` | `python <file>` | Stock forecaster and its sealed-holdout evaluation |
| | `run_significance.py`, `research/gate.py`, `research/score_holdout.py` | `python <file>` | Whether a result beats seed noise; accept or reject with a penalty for the number of tries; a once-only holdout score |
| | `TrainingData/featuresPy/insiderbuying.py` | `python insiderbuying.py` | Insider buys from SEC Form 4 filings, no key |
| | `TrainingData/sp500/download_sp500.py` | `python download_sp500.py` | S&P 500 prices by date including delisted names (Massive key) |
| 50 losing-loonies/congress-trading-investigation | `audio_engine` | `from audio_engine import Cue, render_track` | Synthesised sound effects and track mixing, no samples |
| | `source_code/lib/data_quiver.py`, `source_code/show_trades.py` | `python source_code/show_trades.py [--all] [--csv f]` | Congress trades from Quiver (paid key) |
| | `source_code/lib/animation.py` | `animate_lines`, `animate_bars`, `save_animation(..., audio_wav=)` | Animated charts as video with the sound mixed in |
| | `source_code/lib/backtest.py`, `source_code/prefetch_data.py` | Python import; `python source_code/prefetch_data.py` | Follow-the-filing backtest; cache all the trade and price data |
| 50 losing-loonies/Glassdoor-AI-Stock-Trader | `glassdoor_stock/massive.py`, `prices.py` | Python import | Prices and financials from Massive, with paging and retry |
| | `download_glassdoor_dataset.py` | `python download_glassdoor_dataset.py` | Kaggle review dataset (Kaggle login) |
| 50 losing-loonies/WallStreetBets-Stock-Bot | `src/fetch_wsb_arctic_shift.py` | `python -m src.fetch_wsb_arctic_shift --start D --end D --out f.parquet` | Subreddit history through Arctic Shift, no key |
| | `src/extract_tickers.py`, `src/ticker_universe.py` | Python import | Find stock tickers in text; the list of listed symbols |
| 50 losing-loonies/Intrinsic-Value-Monitor | notebooks `0-create_list`, `1-produce_data`, `2-backtest` | Jupyter | Graham intrinsic-value backtest |
| 21 lore-builder | `tools/build_index.py`, `search.py`, `check_pass.py` | `python3 -I tools/search.py "<q>"`; `--root` takes any lore folder | Index, search and check a lore bible |
| | skills `lore-setup`, `lore-build`, `lore-check`, `lore-pass` | inside the kit | Start, grow, audit and apply a lore bible |
| 22 tavern | `scripts/phone.sh`, `bundle.sh` | `scripts/phone.sh` | Build the Tavern app; run its iOS app in the Simulator. `phone.sh` needs `xcodegen`, which is not installed |
| | `bridge/tavern-durable` | `./setup.sh; ./run.sh <agent>` | Host one durable agent session on a local port |
| | `scripts/capture.swift` | `swift scripts/capture.swift <pid> <window-id> <out.png>` | Screenshot one Mac window |
| 23 moff | `moff` | not installed | Microsoft 365 from the command line through a signed-in Safari tab; also an MCP server |
| 50 losing-loonies/Satellite_Stock_Predictor | `fetch_prices.py` | `python fetch_prices.py [TICKERS] --start D` | Daily closes from Massive |
| | `label_tanks.py`, `measure_tanks.py` | `python <file>` | Measure oil tank fill from satellite images |
| 25 firstmate | firstmate | start an agent with this folder as its working directory | One agent that runs a crew of agents in worktrees; about 250 `bin/fm-*` scripts and 30 skills of its own |
| | `bin/fm-mail.sh`, `bin/fm-lavish-url.sh` | `bin/fm-mail.sh read`; `bin/fm-lavish-url.sh snapshot <url>` | Mail client; web page review snapshot |
| 26 comfyui | ComfyUI server | `.venv/bin/python main.py --port 8188` | Image generation with an HTTP API; started by hand. Models: Qwen-Image 2512 (new image) and Qwen-Image-Edit 2511 with a 4-step LoRA; nothing for upscale, control or video |
| 28 NerdoDivergent | `bin/pebbl-check` | Stop hook | Holds a session that changed files without a pebbl entry |
| 29 proxy-pipeline | `pipeline` | `uv run pipeline <module> <command> --theme T --deck D` | Layered Magic proxy card pipeline. Modules: `doctor`, `cards`, `theme`, `paper-art` (sketch, owner's pick, paint), `cutout` (background removal and matte), `compose` (layout, text, upscale, print finish), `frames`, `plating`, `plate-lab`, `board`, `studio` |
| | `scripts/qwen_edit.py` | `.venv/bin/python scripts/qwen_edit.py --image1 a.png --prompt "..." --out out.png` | One Qwen image edit through a running ComfyUI |
| 31 fairland-rv-census | `scripts/stac_inventory.py` | `uv run python scripts/stac_inventory.py` | Lists aerial and satellite scenes over an area, no key |
| 32 loom | `loom` | — | Frozen 2026-11-09; do not run |
| 33 lumr | `ytscript` | `uv run --project "P/33 lumr/ytscript" ytscript <url-or-id> [--timestamps --no-handoff]` | YouTube transcript saved as a file and a pebbl handoff |
| | `hammy` | `hammy <file>` (on PATH) | Transcribe a recording into notes: summary, takeaways, actions. Config in `~/.config/hammy/config.json` |
| | `clipforge` | `uv run --project "P/33 lumr/clipforge" clipforge <file-or-url> [--num-clips 3]` | Long video into vertical shorts: highlights, reframe, subtitles |
| | `bookforge` | `python3 -m bookforge.forge manuscript.md`; skill in `bookforge/skill` | Book and script writing with search over transcripts; its skill still points at `/Users/ashley` paths |
| | `anti-ai-writing/anti_ai_checker.py` | `python3 anti_ai_checker.py` | The checker behind the `anti-ai-writing` skill |
| | `youtube-narrative-guide/`, `shortform-narrative-guide/` | read | Narrative frameworks for scripts and shorts |
| | `clipforge publish`, `clipforge youtube` | `uv run --project "P/33 lumr/clipforge" clipforge publish prepare\|check\|frames\|compose\|push` | Title, description, chapters, tags and thumbnail for a video; `push` goes live only with `--apply --confirm-id <id>`. The YouTube login is not set up on this Mac |
| | `dataforge` | Python import (`sources/youtube.py`, `sources/youtube_transcript.py`) | YouTube analytics and comments; transcripts without a key |
| | `security-check.sh` | `bash security-check.sh` | Read-only audit of agent settings and editor startup files after a package scare |
| | lumr-studio extras | set `LUMR_STUDIO_EXTRAS=publish_kit,overlays` | Adds overlays and a publish kit to the plugin; off by default |
| | `clipforge publish frames`, `compose` | `clipforge publish frames <video> [--count N]`; `clipforge publish compose --video <video> --frame N --text "LINE\|LINE"` (same `uv run` prefix) | Pick sharp, varied frames into a gallery; draw a 1280x720 thumbnail with text. `compose` needs a font set in `~/.config/lumr/thumbnail_spec.json`, which is not on this Mac |
| | `clipforge.thumbnail` | `python -m clipforge.thumbnail --build-gallery DIR` (this and the two rows below: after `uv run --project "P/33 lumr/clipforge"`) | A picker page of frames; a thumbnail drawn with a font you pass (`--font`) |
| | `clipforge.youtube_upload`, `youtube_flip` | `python -m clipforge.youtube_upload FILE --title T`; `python -m clipforge.youtube_flip [--dry-run]` | Upload as private with a public date a week later; flip due videos to public. Need the YouTube login |
| | `clipforge.creator_profile` | `python -m clipforge.creator_profile --learn [--dry-run]` | Learn the channel's title patterns into a profile. Needs the YouTube login |
| | clipforge modes | `clipforge <source> --mode shorts\|edit\|both\|narrative\|editor` | Shorts, a tightened edit, a narrative cut, or the editor page. Calls `hammy` for the transcript and a local model by default |
| | `dataforge` analytics | `from dataforge.sources.youtube import load_analytics_csv, get_top_videos`; `from dataforge.reports import record_retention_audit` | Load a YouTube Studio export into a local database; top videos; a written retention audit per video. No data loaded on this Mac |
| | `bookforge.forge.companion`, `bookforge.ulyz_to_md` | Python import; `python -m bookforge.ulyz_to_md SRC` | An editor's report on a manuscript; Ulysses notes to Markdown |
| | `anti-ai-writing/voice_scorer.py` | `python3 voice_scorer.py "text"` | Voice similarity score; needs writing samples that are not on this Mac |
| | lumr-studio plugin tools | through the plugin | `transcribe`, `read_transcript`, `find_words`, `analyze_take`, `get_edit`, `set_edit`, `preview`, `render`, `look`, `frames`, `review`, `assemble`, `carry_edit`, `job_status`, `forget_taste`. The clone at `~/lumr-studio` is the current source; the copy inside `P/33 lumr/studio` is older |
| | `docs/` | read, starting at `docs/index.md` | Specs and module notes for every lumr tool |
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
| | `spike/fetch-photos.mjs` | `node spike/fetch-photos.mjs` | Photos from Wikimedia Commons, no key |
| 38 life-management | `print.sh` | `"00-09 System/01 Tools/01.01 Print to PDF/print.sh" "<Plan.md>"` | A plan's text as a letter-size PDF through headless Brave |
| | `00-09 System/01 Tools/01.02 Learn later/learn.py` | `learn` | The learning queue; Friday digest by launchd. Was project 44 |
| 39 house-hunt | `scripts/build_pdf.py`, `build_tour_pdf.py`, `build_review.py` | `scripts/.venv/bin/python scripts/build_pdf.py` | House shortlist reports as PDF; `scripts/.venv` is not built on this Mac, so install `scripts/requirements.txt` into it first |
| 40 essay-check | `eval/detector/score.py` | `.venv/bin/python -I score.py` in `eval/detector/` | Scores every essay in the eval corpus with a local AI-text detector; ranks, gives no verdict. `detector_lib.py` holds the model |
| | `server/extract/docx.ts`, `pdf.ts`; `eval/scripts/print_pdf.js` | imports; `node print_pdf.js <playwright dir> in.html out.pdf` | Text from Word and PDF files, flagging hidden text; HTML to PDF |
| 41 army-builder | `fetch-core-rules`, `fetch-stratagems`, `fetch-datasheets`, `fetch-meta` | `npm run <name>` | Warhammer rules, stratagems, datasheets and tournament stats |
| | `ocr-codex` | `npm run ocr-codex -- <pdf>` | OCR of codex photos with macOS Vision and deskew |
| | `icons`, `portraits` | `npm run icons` | Unit art into web masks and images |
| | `scripts/studio-public-url.sh`, `deploy-studio.sh` | `scripts/studio-public-url.sh [--rotate\|--off]` | Deploy DropList and publish its link |
| | `audit`, `merge-rules`, `new-codex`, `fetch-data`, `import-data` | `npm run <name>` | Rules-data scorecard; re-apply hand-written rules; import a new codex; fetch and normalise army data |
| 42 real-voice | speak app | `uv run python -m speak.app` in `prototype/` | Local text to speech at `127.0.0.1:8840`; can feed a virtual mic |
| | `likeness/add_voice.py` | `uv run python likeness/add_voice.py me <recording.m4a> --mine` | Clone a voice from about 90 seconds of audio |
| | `likeness/score.py`, `refine_voice.py` | `uv run python likeness/score.py` in `prototype/` | Score how closely a cloned voice matches and how clear its words are; find the best part of a long recording to clone from |
| 43 color-builder | `scripts/build-paints.mjs` | `npm run paints` | Paint tables into the app's data file |

No tools: 50/Astrology-Stock-Bot and 50/Copying-DJT-Trades (empty, gone from GitHub), 30 (reports only). Not yet swept: 50/Student-Loan-vs-Investing, 50/Recession-Investing-Experiment, 50/Best-MACD-Trading-Validation, 50/Truth-Social-Trading. Dead scripts, written for another machine: `P/50 losing-loonies/LSTM_AI_Stock_Predictor/run_sp500_sweep.sh`, `P/33 lumr/clipforge/render_shorts.py`, and the launchd file in `P/33 lumr/clipforge/launchd/`.

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
