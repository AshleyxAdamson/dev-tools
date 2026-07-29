#!/usr/bin/env bash
# ~/.claude/statusline.sh — Claude Code session status line (aesthetic edition)
#
# 三行輸出：
#   第一行：◆ 模型 │ 漸層進度條 百分比 │ 費用 │ 時間 │ 速率限制
#   第二行：⎇分支* │ +增/-減 │ 目錄
#   第三行：❯ 提示符（顏色跟上下文用量連動）
#
# 環境變數：
#   CLAUDE_STATUSLINE_ASCII=1     退回純 ASCII
#   CLAUDE_STATUSLINE_NERDFONT=1  啟用 Nerd Font 圖示
#   CLAUDE_STATUSLINE_POWERLINE=1 啟用 Powerline 分隔符（預設跟隨 NERDFONT）
#   COLORTERM=truecolor|24bit     系統自動設定，啟用真彩色漸層

set -euo pipefail

# ═══════════════════════════════════════════════════════════════
# 環境偵測
# ═══════════════════════════════════════════════════════════════

USE_ASCII="${CLAUDE_STATUSLINE_ASCII:-0}"
USE_NERDFONT="${CLAUDE_STATUSLINE_NERDFONT:-0}"
# Cache 保溫窗口（秒）：訂閱制預設 1 小時；API key 用 300。超額用信用額度時實際會掉到 5 分鐘。
CACHE_TTL_SECONDS="${CLAUDE_STATUSLINE_CACHE_TTL:-3600}"
USE_POWERLINE="${CLAUDE_STATUSLINE_POWERLINE:-$USE_NERDFONT}"
USE_TRUECOLOR=0
if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
  USE_TRUECOLOR=1
fi

# ═══════════════════════════════════════════════════════════════
# 色彩與符號
# ═══════════════════════════════════════════════════════════════

RST='\033[0m'
CYAN='\033[36m'
BLUE='\033[34m'
GRAY='\033[90m'
DIM='\033[2m'
YELLOW='\033[33m'
GREEN='\033[32m'
RED='\033[31m'
MAGENTA='\033[35m'

# Anthropic 品牌紫 (#7266EA)
if (( USE_TRUECOLOR )); then
  PURPLE='\033[38;2;114;102;234m'
else
  PURPLE='\033[35m'
fi

# 符號集
if [[ "$USE_ASCII" == "1" ]]; then
  S_BRAND="<>"
  S_BRANCH=">"
  S_WARN="!"
  S_PROMPT=">"
  S_TIME=""
  S_COST=""
  S_CACHE="cache "
  S_TTL=""
  S_RATE=""
  S_CACHE_TOK=""
  SEP=" | "
elif [[ "$USE_NERDFONT" == "1" ]]; then
  S_BRAND="◆"
  S_BRANCH=" "
  S_WARN=" 󰀦"
  S_PROMPT="❯"
  S_TIME="🕐 "
  S_COST=" "
  S_CACHE="󰆼 "
  S_TTL="🕯️ "
  S_RATE="📅 "
  S_CACHE_TOK="⚡"
  if [[ "$USE_POWERLINE" == "1" ]]; then
    SEP="  "
  else
    SEP=" │ "
  fi
else
  S_BRAND="◆"
  S_BRANCH="⎇"
  S_WARN=" ⚠"
  S_PROMPT="❯"
  S_TIME="🕐 "
  S_COST=""
  S_CACHE="◈ "
  S_TTL="🕯️ "
  S_RATE="📅 "
  S_CACHE_TOK="⚡"
  if [[ "$USE_POWERLINE" == "1" ]]; then
    SEP="  "
  else
    SEP=" │ "
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 降級輸出
# ═══════════════════════════════════════════════════════════════

fallback_prompt() {
  printf '%b' "${GRAY}${1:-─}${RST}"
  exit 0
}

command -v jq &>/dev/null || fallback_prompt "─ │ jq not found"

# ═══════════════════════════════════════════════════════════════
# 讀取 JSON（單次 jq）
# ═══════════════════════════════════════════════════════════════

input=$(cat)

parsed=$(echo "$input" | jq -r '
  (.model.display_name // ""),
  (.context_window.used_percentage // 0 | tostring),
  (.cost.total_cost_usd // 0 | tostring),
  (.workspace.current_dir // "." | split("/") | last),
  (.worktree.branch // ""),
  (.rate_limits.five_hour.used_percentage // -1 | tostring),
  (.rate_limits.seven_day.used_percentage // -1 | tostring),
  (.agent.name // ""),
  (.workspace.current_dir // "."),
  (.cost.total_lines_added // 0 | tostring),
  (.cost.total_lines_removed // 0 | tostring),
  (.cost.total_duration_ms // 0 | tostring),
  (.context_window.context_window_size // 0 | tostring),
  (.worktree.name // ""),
  (.transcript_path // ""),
  "END"
' 2>/dev/null) || fallback_prompt "─ │ parse error"

{
  IFS= read -r model_name
  IFS= read -r ctx_pct
  IFS= read -r cost
  IFS= read -r dir
  IFS= read -r branch
  IFS= read -r rate5h
  IFS= read -r rate7d
  IFS= read -r agent_name
  IFS= read -r cwd_full
  IFS= read -r lines_add
  IFS= read -r lines_rm
  IFS= read -r duration_ms
  IFS= read -r ctx_size
  IFS= read -r wt_name
  IFS= read -r transcript_path
  IFS= read -r _sentinel
} <<< "$parsed"

# ═══════════════════════════════════════════════════════════════
# 模型
# ═══════════════════════════════════════════════════════════════

model="${model_name:-─}"

# ═══════════════════════════════════════════════════════════════
# 上下文進度條
# ═══════════════════════════════════════════════════════════════

pct_int=${ctx_pct%.*}
pct_int=${pct_int:-0}
if (( pct_int < 0 )); then pct_int=0; fi
if (( pct_int > 100 )); then pct_int=100; fi

bar_filled=$(( pct_int / 10 ))
if (( bar_filled > 10 )); then bar_filled=10; fi

# 漸層色（真彩色）：綠 → 黃 → 橘 → 紅
GRAD_R=(46 116 186 241 239 236 233 231 211 192)
GRAD_G=(204 195 186 196 161 126 101 76 66 57)
GRAD_B=(113 89 64 15 24 34 44 60 50 43)

bar=""
if [[ "$USE_ASCII" == "1" ]]; then
  # ASCII 模式
  for (( i=0; i<10; i++ )); do
    if (( i < bar_filled )); then bar+="#"; else bar+="-"; fi
  done
elif (( USE_TRUECOLOR )); then
  # 真彩色漸層：每格獨立上色
  for (( i=0; i<10; i++ )); do
    if (( i < bar_filled )); then
      bar+="\\033[38;2;${GRAD_R[$i]};${GRAD_G[$i]};${GRAD_B[$i]}m█"
    else
      bar+="\\033[38;2;60;60;60m░"
    fi
  done
  bar+="${RST}"
else
  # ANSI 退回：依整體百分比選色
  if (( pct_int >= 90 )); then bar_color="$RED"
  elif (( pct_int >= 70 )); then bar_color="$YELLOW"
  else bar_color="$GREEN"; fi

  for (( i=0; i<10; i++ )); do
    if (( i < bar_filled )); then bar+="█"; else bar+="░"; fi
  done
  bar="${bar_color}${bar}${RST}"
fi

# 百分比文字顏色（跟進度條整體色一致）
if (( pct_int >= 90 )); then pct_color="$RED"
elif (( pct_int >= 70 )); then pct_color="$YELLOW"
else pct_color="$GREEN"; fi

# 警告符號
ctx_warn=""
if (( pct_int >= 90 )); then ctx_warn="${RED}${S_WARN}${RST}"; fi

# 上下文視窗大小（僅在 model display_name 不包含 context 資訊時才顯示）
ctx_size_int=${ctx_size:-0}
ctx_label=""
if [[ "$model" != *context* && "$model" != *Context* ]]; then
  if (( ctx_size_int >= 1000000 )); then ctx_label=" ${GRAY}1M${RST}"
  elif (( ctx_size_int >= 200000 )); then ctx_label=" ${GRAY}200k${RST}"
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 費用
# ═══════════════════════════════════════════════════════════════

cost_val="${cost:-0}"
cost_fmt=$(printf '%.2f' "$cost_val" 2>/dev/null || echo "0.00")
cost_int=${cost_val%.*}
cost_int=${cost_int:-0}

if (( cost_int >= 10 )); then cost_color="$RED"
elif (( cost_int >= 5 )); then cost_color="$YELLOW"
elif [[ "$cost_fmt" == "0.00" ]]; then cost_color="$GRAY"
else cost_color="$YELLOW"; fi

# ═══════════════════════════════════════════════════════════════
# 經過時間（零值智慧隱藏）
# ═══════════════════════════════════════════════════════════════

dur_ms=${duration_ms:-0}
dur_section=""
if (( dur_ms > 0 )); then
  dur_sec=$((dur_ms / 1000))
  dur_min=$((dur_sec / 60))
  dur_s=$((dur_sec % 60))
  # 格式化後仍為 0m0s 就不顯示（session 啟動初期 dur_ms 可能是幾百毫秒）
  if (( dur_min > 0 || dur_s > 0 )); then
    dur_section="${SEP}${GRAY}${S_TIME}${dur_min}m${dur_s}s${RST}"
  fi
fi

# ═══════════════════════════════════════════════════════════════
# Git 分支與髒標記（帶快取）
# ═══════════════════════════════════════════════════════════════

GIT_CACHE="/tmp/claude-statusline-git-cache"
GIT_CACHE_MAX_AGE=5

git_branch="${branch:-}"
dirty=""

git_cache_is_stale() {
  [[ ! -f "$GIT_CACHE" ]] && return 0
  local cache_age=$(( $(date +%s) - $(stat -f %m "$GIT_CACHE" 2>/dev/null || echo 0) ))
  (( cache_age > GIT_CACHE_MAX_AGE ))
}

if [[ -n "${cwd_full:-}" && -d "${cwd_full:-}" ]]; then
  if git_cache_is_stale; then
    if git -C "$cwd_full" rev-parse --git-dir &>/dev/null; then
      cached_branch="${git_branch}"
      if [[ -z "$cached_branch" ]]; then
        cached_branch=$(git -C "$cwd_full" -c core.useBuiltinFSMonitor=false branch --show-current 2>/dev/null) || true
        if [[ -z "$cached_branch" ]]; then
          cached_branch=$(git -C "$cwd_full" rev-parse --short HEAD 2>/dev/null) || true
        fi
      fi
      cached_dirty=""
      if ! git -C "$cwd_full" -c core.useBuiltinFSMonitor=false diff --quiet 2>/dev/null || \
         ! git -C "$cwd_full" -c core.useBuiltinFSMonitor=false diff --cached --quiet 2>/dev/null; then
        cached_dirty="*"
      fi
      echo "${cached_branch}|${cached_dirty}" > "$GIT_CACHE"
    else
      echo "|" > "$GIT_CACHE"
    fi
  fi

  if [[ -f "$GIT_CACHE" ]]; then
    IFS='|' read -r cached_br cached_dt < "$GIT_CACHE"
    if [[ -z "$git_branch" ]]; then git_branch="${cached_br}"; fi
    dirty="${cached_dt}"
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 行數增減（零值智慧隱藏）
# ═══════════════════════════════════════════════════════════════

lines_add=${lines_add:-0}
lines_rm=${lines_rm:-0}
lines_section=""
if (( lines_add > 0 || lines_rm > 0 )); then
  lines_section="${GREEN}+${lines_add}${RST}/${RED}-${lines_rm}${RST}"
fi

# ═══════════════════════════════════════════════════════════════
# 速率限制（條件顯示）
# ═══════════════════════════════════════════════════════════════

rate_section=""
rate5h_int=${rate5h%.*}; rate5h_int=${rate5h_int:-0}
rate7d_int=${rate7d%.*}; rate7d_int=${rate7d_int:-0}

rate_parts=""
if (( rate5h_int >= 0 )); then
  if (( rate5h_int >= 80 )); then rate_parts+="${RED}5h:${rate5h_int}%${RST}"
  else rate_parts+="${GRAY}5h:${rate5h_int}%${RST}"; fi
fi
if (( rate7d_int >= 0 )); then
  if [[ -n "$rate_parts" ]]; then rate_parts+=" "; fi
  if (( rate7d_int >= 80 )); then rate_parts+="${RED}7d:${rate7d_int}%${RST}"
  else rate_parts+="${GRAY}7d:${rate7d_int}%${RST}"; fi
fi
if [[ -n "$rate_parts" ]]; then
  rate_section="${SEP}${S_RATE}${rate_parts}"
fi

# ═══════════════════════════════════════════════════════════════
# Prompt cache 命中率（讀取 transcript 最後一則 usage）
# ═══════════════════════════════════════════════════════════════

# 把 token 數壓成人類可讀（1234 -> 1.2k）
human_tokens() {
  local n=${1:-0}
  if (( n >= 1000 )); then
    printf '%d.%dk' $(( n / 1000 )) $(( (n % 1000) / 100 ))
  else
    printf '%d' "$n"
  fi
}

cache_section=""
if [[ -n "${transcript_path:-}" && -f "${transcript_path:-}" ]]; then
  # 只掃描尾端 200 行，取最後一筆帶 usage 的 assistant 訊息
  cache_row=$(tail -n 200 "$transcript_path" 2>/dev/null | \
    jq -rc 'select(.message.usage.cache_read_input_tokens != null)
            | [ (.message.usage.input_tokens // 0),
                (.message.usage.cache_read_input_tokens // 0),
                (.message.usage.cache_creation_input_tokens // 0) ] | @tsv' 2>/dev/null | tail -1)
  if [[ -n "$cache_row" ]]; then
    IFS=$'\t' read -r c_in c_read c_create <<< "$cache_row"
    c_in=${c_in:-0}; c_read=${c_read:-0}; c_create=${c_create:-0}
    c_total=$(( c_in + c_read + c_create ))
    if (( c_total > 0 )); then
      c_hit=$(( c_read * 100 / c_total ))
      # 顏色：高命中=綠、中=黃、冷起步=灰
      if (( c_hit >= 80 )); then c_color="$GREEN"
      elif (( c_hit >= 40 )); then c_color="$YELLOW"
      else c_color="$GRAY"; fi
      read_h=$(human_tokens "$c_read")
      create_h=$(human_tokens "$c_create")
      cache_section="${SEP}${c_color}${S_CACHE}${c_hit}%${RST} ${GRAY}${S_CACHE_TOK}${read_h}/${create_h}${RST}"
    fi
  fi
fi

# ═══════════════════════════════════════════════════════════════
# Cache 保溫窗口倒數（距離上次活動 vs TTL）
# ═══════════════════════════════════════════════════════════════
# 顯示「還剩多久窗口」：每次互動都會把計時器重置回滿，閒置才倒數。
# 掉到 0 = cache 過期，下一輪會重建（那一輪 cache% 會掉、creation 會跳）。

ttl_section=""
if [[ -n "${transcript_path:-}" && -f "${transcript_path:-}" ]]; then
  # 取尾端最後一筆有 timestamp 的事件（user/assistant 訊息都帶）
  last_ts=$(tail -n 80 "$transcript_path" 2>/dev/null | jq -r 'select(.timestamp) | .timestamp' 2>/dev/null | tail -1)
  if [[ -n "$last_ts" ]]; then
    # ISO 8601（UTC，帶毫秒+Z）→ epoch；macOS BSD date
    last_epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "${last_ts%.*}" +%s 2>/dev/null || echo "")
    if [[ -n "$last_epoch" ]]; then
      now_epoch=$(date +%s)
      elapsed=$(( now_epoch - last_epoch ))
      if (( elapsed < 0 )); then elapsed=0; fi
      remaining=$(( CACHE_TTL_SECONDS - elapsed ))
      if (( remaining > 0 )); then
        # 格式化剩餘時間
        rem_min=$(( remaining / 60 ))
        rem_sec=$(( remaining % 60 ))
        if (( rem_min >= 60 )); then
          rem_h=$(( rem_min / 60 )); rem_m=$(( rem_min % 60 ))
          rem_fmt="${rem_h}h${rem_m}m"
        elif (( rem_min > 0 )); then
          rem_fmt="${rem_min}m"
        else
          rem_fmt="${rem_sec}s"
        fi
        # 顏色：剩 >20% 綠、5-20% 黃、<5% 紅（快過期）
        warn_at=$(( CACHE_TTL_SECONDS * 20 / 100 ))
        danger_at=$(( CACHE_TTL_SECONDS * 5 / 100 ))
        if (( remaining <= danger_at )); then ttl_color="$RED"
        elif (( remaining <= warn_at )); then ttl_color="$YELLOW"
        else ttl_color="$GREEN"; fi
        # 蠟燭 icon 代表 cache 保溫；跟 session 時鐘視覺區隔
        ttl_section="${SEP}${ttl_color}${S_TTL}${rem_fmt}${RST}"
      else
        # 窗口已過，cache 大概率已冷（蠟燭熄了）
        ttl_section="${SEP}${GRAY}${S_TTL}cold${RST}"
      fi
    fi
  fi
fi

# ═══════════════════════════════════════════════════════════════
# 動態提示符（顏色跟上下文用量連動）
# ═══════════════════════════════════════════════════════════════

if (( pct_int >= 90 )); then prompt_color="$RED"
elif (( pct_int >= 70 )); then prompt_color="$YELLOW"
else prompt_color="$GREEN"; fi

# ═══════════════════════════════════════════════════════════════
# 組裝第一行
# ═══════════════════════════════════════════════════════════════

line1="${PURPLE}${S_BRAND}${RST} ${CYAN}${model}${RST}"
line1+="${SEP}${bar} ${pct_color}${pct_int}%${RST}${ctx_warn}${ctx_label}"
line1+="${SEP}${cost_color}${S_COST}\$${cost_fmt}${RST}"
line1+="${ttl_section}"
line1+="${cache_section}"
line1+="${dur_section}"
line1+="${rate_section}"

# ═══════════════════════════════════════════════════════════════
# 組裝第二行
# ═══════════════════════════════════════════════════════════════

parts=()
if [[ -n "$git_branch" ]]; then
  parts+=("${GRAY}${S_BRANCH}${git_branch}${dirty}${RST}")
fi
if [[ -n "$lines_section" ]]; then
  parts+=("${lines_section}")
fi
parts+=("${BLUE}${dir}${RST}")

# Agent / Worktree 指示器（僅在非主 session 時顯示）
if [[ -n "${wt_name:-}" ]]; then
  parts+=("${YELLOW}⚙ worktree:${wt_name}${RST}")
elif [[ -n "${agent_name:-}" ]]; then
  parts+=("${YELLOW}⚙ ${agent_name}${RST}")
fi

line2=""
for i in "${!parts[@]}"; do
  if (( i > 0 )); then
    line2+="${SEP}"
  fi
  line2+="${parts[$i]}"
done

# ═══════════════════════════════════════════════════════════════
# 輸出
# ═══════════════════════════════════════════════════════════════

# 只輸出兩行（Claude Code 有自己的輸入提示符，不需要我們的 ❯）
printf '%b\n%b' "$line1" "$line2"
