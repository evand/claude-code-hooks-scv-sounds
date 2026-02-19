# Not Enough Minerals — RAM Monitor

Plays "Not enough minerals" when your system's available RAM drops below safe thresholds.

## How It Works

Checks `MemAvailable` from `/proc/meminfo` every 30 seconds (via systemd timer). Unlike a simple threshold + cooldown, this monitor uses a **tier system** that alerts on transitions, not states:

| Tier | MemAvailable | Behavior |
|------|-------------|----------|
| OK | >20% | Reset — episode over |
| Low | 10-20% | Alert once on entry, then silence |
| Critical | 5-10% | Alert on entry, re-alert if still declining |
| Emergency | <5% | Alert on entry, re-alert if still declining |

**Key behaviors:**

- **Hysteresis**: Requires 2 consecutive readings at a worse tier before alerting (filters momentary spikes)
- **No nagging**: Staying at the same tier in Low doesn't re-trigger. You already know.
- **Escalation**: Dropping from Low to Critical triggers a fresh alert
- **Smart re-trigger**: At Critical/Emergency, re-alerts only if MemAvailable is still *declining* between checks
- **"Swap has it covered"**: If MemAvailable stabilizes (kernel found equilibrium via swap), alerts stop. No point nagging about a stable state.
- **Full reset**: Only when MemAvailable recovers above 20%. A fresh decline after recovery is a new episode.

## Why MemAvailable, not MemFree?

Linux aggressively uses free RAM for disk cache. `MemFree` would false-alarm constantly because 95%+ "used" RAM is normal — most of it is reclaimable cache. `MemAvailable` (added in Linux 3.14) estimates how much memory is actually available for new allocations, accounting for reclaimable buffers and cache.

## Setup

### Linux (systemd)

```bash
# Via install.sh (recommended)
cd /path/to/claude-code-hooks-scv-sounds
./install.sh  # Will prompt for minerals monitor setup

# Or manually:
cp minerals-monitor.sh ~/.claude/minerals/
cp minerals-monitor.service minerals-monitor.timer ~/.config/systemd/user/
chmod +x ~/.claude/minerals/minerals-monitor.sh
systemctl --user daemon-reload
systemctl --user enable --now minerals-monitor.timer
```

### Configuration

Edit `~/.claude/minerals/minerals-monitor.sh` to adjust:

- `TIER_OK`, `TIER_LOW`, `TIER_CRITICAL` — tier thresholds (% of total RAM)
- `STABILITY_THRESHOLD` — how much decline (% points) counts as "still declining" (default: 1%)
- `COOLDOWN_SECONDS` — minimum seconds between re-alerts at Critical/Emergency (default: 180)

### macOS

Not yet supported (`/proc/meminfo` is Linux-specific). Would need `vm_stat` or `memory_pressure` parsing. Contributions welcome!

## Checking Status

```bash
# Timer status
systemctl --user status minerals-monitor.timer

# Current state
cat /tmp/minerals-state

# Current memory
awk '/^MemTotal:|^MemAvailable:/ {printf "%s %.0f MB\n", $1, $2/1024}' /proc/meminfo

# Test manually (will alert if thresholds are met)
bash ~/.claude/minerals/minerals-monitor.sh
```

## Future Refinements

- **Escalating sounds**: Different sounds per tier (Low = informational, Emergency = alarm)
- **PSI integration**: Use `/proc/pressure/memory` to detect actual memory stalls, not just low watermarks
- **Process attribution**: Identify the top memory consumer when alerting (who's eating the minerals?)
- **Desktop notifications**: Pair the sound with a notification showing memory breakdown
- **Swap throughput**: Detect active thrashing (high pages in/out rate) vs. passive swap usage
- **Container awareness**: Integrate with cgroups `memory.high` / `memory.max` for container workloads
