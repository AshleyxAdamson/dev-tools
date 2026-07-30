---
name: activity-check
description: Deep-dive Mac activity diagnostic. Checks CPU, memory pressure, swap, sleep prevention assertions, thermal state, and hot processes. Use when the Mac is warm, slow, fans loud, or draining battery.
allowed-tools: Bash
---

Run a full Mac activity diagnostic and identify what's causing heat, slowness, or unexpected wakefulness.

## Collected System Data

**Top processes by CPU (3-sample average):**
!`top -l 3 -n 20 -stats pid,command,cpu,mem,power 2>/dev/null | grep -A 25 "^PID"`

**Memory pressure:**
!`vm_stat | head -20`

**Swap usage:**
!`sysctl vm.swapusage 2>/dev/null || echo "unavailable"`

**Thermal / CPU speed-limit status:**
!`pmset -g therm 2>/dev/null || echo "unavailable"`

**Sleep prevention assertions (what's blocking sleep/idle):**
!`pmset -g 2>/dev/null | grep -A 40 "pid"`

**Recent sleep/wake/assertion activity (last 2 hours):**
!`pmset -g log 2>/dev/null | grep -E "Wake|Sleep|DarkWake|Assertions|PreventSleep" | tail -30`

**Open files for top CPU consumers (first 3 PIDs):**
!`pids=$(ps axo pid,%cpu -r | awk 'NR>1 && NR<=4 {print $1}' | tr '\n' ' '); for pid in $pids; do echo "=== PID $pid: $(ps -p $pid -o comm= 2>/dev/null) ==="; lsof -p $pid 2>/dev/null | awk '{print $NF}' | grep -v "^/System\|^/usr/lib\|^/private/var/folders\|^/$" | sort | uniq -c | sort -rn | head -8; done`

**Disk I/O activity:**
!`iostat -d 1 3 2>/dev/null | tail -5 || echo "iostat unavailable"`

**Network activity summary:**
!`nettop -l 1 -P 2>/dev/null | head -20 || netstat -ib 2>/dev/null | head -10`

---

Analyze all of the above and produce a structured report with:

1. **Heat map** — List the top 5 processes by CPU/power impact with % and what they're doing
2. **Sleep blockers** — Any processes preventing idle sleep, display sleep, or holding wake assertions longer than expected (flag anything over 1 hour)
3. **Memory pressure** — Assess free memory, compressor size, swap usage; flag if critical
4. **Root cause summary** — Your best diagnosis of what's making the machine warm
5. **Recommended actions** — Specific, actionable fixes (e.g. "killall Finder", "quit WhatsApp", "close Firefox tab playing audio")

Keep the report concise and scannable. Use bold for process names and specific numbers.
