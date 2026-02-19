#!/usr/bin/env bash
# Not Enough Minerals — RAM Monitor
# Plays "Not enough minerals" when MemAvailable drops below safe thresholds.
#
# Design: alert on TRANSITIONS, not states.
#
#   Tier system (MemAvailable as % of MemTotal):
#     OK        >20%    Full reset — episode over
#     Low       10-20%  Alert once on entry, then silence
#     Critical   5-10%  Alert on entry + keep alerting if still declining
#     Emergency  <5%    Alert on entry + keep alerting if still declining
#
#   Hysteresis: requires 2 consecutive readings at a worse tier before alerting.
#   This filters out momentary spikes (e.g., file cache flush then refill).
#
#   Re-trigger (Critical/Emergency only): if MemAvailable is still DECLINING
#   between checks, re-alert on cooldown. If MemAvailable has stabilized
#   (swap absorbed the overflow, or a process released memory), hush.
#
#   "Swap has it covered": if MemAvailable stops declining, the kernel found
#   an equilibrium. No point nagging — the user can't do anything the kernel
#   hasn't already tried.
#
# State file: /tmp/minerals-state (sourced as bash vars)
#
# Future refinements:
#   - Different sounds per tier (escalating urgency)
#   - OOM killer proximity detection (check /proc/pressure/memory for PSI stalls)
#   - Per-process memory hogs in alert output (who's eating the minerals?)
#   - Desktop notification with details alongside the sound
#   - Swap throughput rate (pages/sec) as a thrashing detector
#   - Integration with cgroups memory.high events for container-aware alerting

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$HOME/.claude/sounds"
SOUND="$SOUNDS_DIR/not-enough-minerals.wav"
STATE_FILE="/tmp/minerals-state"

# --- Configuration ---
# Tier thresholds: MemAvailable as percentage of MemTotal.
# Tune these for your workload. Machines with lots of RAM can use lower values.
TIER_OK=20
TIER_LOW=10
TIER_CRITICAL=5
# Below TIER_CRITICAL = Emergency

# Stability: if MemAvailable changed by less than this (percentage points)
# between checks, consider it stabilized. On a 32GB machine, 1% = ~320MB.
STABILITY_THRESHOLD=1

# Cooldown for re-alerts at Critical/Emergency (seconds).
# Only applies when still declining — stable readings suppress indefinitely.
COOLDOWN_SECONDS=180
# ---------------------

# --- Read /proc/meminfo ---
mem_total=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
mem_available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)

if [ -z "$mem_total" ] || [ "$mem_total" -eq 0 ]; then
    exit 1  # Can't read meminfo
fi

pct_available=$(awk "BEGIN { printf \"%.1f\", ($mem_available / $mem_total) * 100 }")

# --- Determine current tier ---
classify_tier() {
    awk "BEGIN {
        pct = $1
        if (pct > $TIER_OK) print \"ok\"
        else if (pct > $TIER_LOW) print \"low\"
        else if (pct > $TIER_CRITICAL) print \"critical\"
        else print \"emergency\"
    }"
}
current_tier=$(classify_tier "$pct_available")

# Tier severity: higher = worse
tier_sev() {
    case "$1" in
        ok)        echo 0 ;;
        low)       echo 1 ;;
        critical)  echo 2 ;;
        emergency) echo 3 ;;
    esac
}

# --- Load state ---
ALERTED_TIER="ok"
PREV_AVAILABLE_PCT=100
CONSEC_COUNT=0
LAST_PLAYED=0

if [ -f "$STATE_FILE" ]; then
    # shellcheck source=/dev/null
    source "$STATE_FILE"
fi

current_sev=$(tier_sev "$current_tier")
alerted_sev=$(tier_sev "$ALERTED_TIER")
now=$(date +%s)
should_play=0

# --- Decision logic ---

if [ "$current_tier" = "ok" ]; then
    # All clear — full reset
    ALERTED_TIER="ok"
    CONSEC_COUNT=0

elif [ "$current_sev" -gt "$alerted_sev" ]; then
    # Entering a WORSE tier than we've alerted for
    CONSEC_COUNT=$((CONSEC_COUNT + 1))
    if [ "$CONSEC_COUNT" -ge 2 ]; then
        should_play=1
        ALERTED_TIER="$current_tier"
        CONSEC_COUNT=0
    fi

elif [ "$current_sev" -eq "$alerted_sev" ] && [ "$current_sev" -ge 2 ]; then
    # Staying in Critical or Emergency — check if still declining
    # Compare with previous reading to detect stabilization
    delta=$(awk "BEGIN { printf \"%.1f\", $pct_available - $PREV_AVAILABLE_PCT }")
    is_declining=$(awk "BEGIN { print ($delta < -$STABILITY_THRESHOLD) ? 1 : 0 }")

    if [ "$is_declining" -eq 1 ]; then
        # Still getting worse — re-alert on cooldown
        elapsed=$((now - LAST_PLAYED))
        if [ "$elapsed" -ge "$COOLDOWN_SECONDS" ]; then
            should_play=1
        fi
    fi
    # Stable or improving at Critical/Emergency — suppress (swap has it covered)
    CONSEC_COUNT=0

else
    # Recovering (better tier) but not yet OK, or staying in Low — suppress.
    # Reset consecutive counter so a re-decline needs fresh hysteresis.
    CONSEC_COUNT=0
fi

# --- Play if needed ---
if [ "$should_play" -eq 1 ]; then
    LAST_PLAYED=$now
    bash "$SCRIPT_DIR/../scripts/play.sh" --sync "$SOUND"
fi

# --- Save state ---
PREV_AVAILABLE_PCT=$pct_available
cat > "$STATE_FILE" <<EOF
ALERTED_TIER="$ALERTED_TIER"
PREV_AVAILABLE_PCT=$PREV_AVAILABLE_PCT
CONSEC_COUNT=$CONSEC_COUNT
LAST_PLAYED=$LAST_PLAYED
EOF
