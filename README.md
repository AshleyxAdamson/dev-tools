# claude-statusline

A two-line status line for Claude Code, customized for Ashley.

Forked from [kcchien/claude-code-statusline](https://github.com/kcchien/claude-code-statusline) and extended with a live **prompt-cache readout** (hit %, read/write tokens) and a **cache-window countdown**.

## What the line shows

```
◆ Opus 4.8 │ ██░░ 22% 1M │ $0.42 │ 🕯️ 59m │ 󰆼 99% ⚡54.9k/336 │ 🕐 52m10s │ 📅 5h:34% 7d:12%
```

| Segment | Meaning |
|---|---|
| `◆ Opus 4.8` | model |
| `██░░ 22% 1M` | context used (gradient bar) / context window size |
| `$0.42` | session cost |
| `🕯️ 59m` | **cache window left** — idle time before the prompt cache goes cold. Counts down when idle, resets to full each message. `🕯️ cold` = expired, next turn rebuilds. |
| `󰆼 99%` | **cache hit rate** for the last turn (green ≥80, yellow 40-79, gray below) |
| `⚡54.9k/336` | cache tokens **read / newly-written** last turn |
| `🕐 52m10s` | session runtime (counts up) |
| `📅 5h:34% 7d:12%` | rate-limit usage (5-hour / 7-day windows) |

The cache % and window are derived by reading the session transcript (`transcript_path`) — the standard status-line JSON payload does not carry cache data.

### Cache window (TTL)

Claude Code on a **subscription** requests a **1-hour** cache TTL automatically; on an **API key** it defaults to **5 minutes**. The `🕯️` countdown assumes 1 hour. Override:

```sh
export CLAUDE_STATUSLINE_CACHE_TTL=300   # seconds; use 300 on an API key
```

Source: [How Claude Code uses prompt caching](https://code.claude.com/docs/en/prompt-caching).

## Install

The script must live at `~/.claude/statusline.sh`. This repo is the source of truth; symlink it:

```sh
ln -sf "$PWD/statusline.sh" ~/.claude/statusline.sh
chmod +x statusline.sh
```

Wire it into `~/.claude/settings.json`:

```json
{
  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh", "timeout": 10 }
}
```

Requires `jq` (`brew install jq`).

## Options (env vars, set in `~/.zshrc`)

| Var | Effect |
|---|---|
| `CLAUDE_STATUSLINE_NERDFONT=1` | Nerd Font icons (needs a Nerd Font in the terminal) |
| `CLAUDE_STATUSLINE_ASCII=1` | plain text, no color/unicode |
| `CLAUDE_STATUSLINE_POWERLINE=1` | Powerline separators |
| `CLAUDE_STATUSLINE_CACHE_TTL=<sec>` | cache-window length (default 3600) |
