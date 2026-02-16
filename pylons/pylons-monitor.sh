#!/usr/bin/env bash
# Additional Pylons Load Monitor
# Plays "You must construct additional pylons" when system load is sustained above threshold.
#
# Hysteresis:
#   - Cooldown: won't play again for COOLDOWN_SECONDS after last play
#   - Sustained: requires load above threshold on 2 consecutive checks
#     (state tracked via /tmp/pylons-load-high flag file)
#   - Threshold: configurable (default: number of physical CPU cores)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$HOME/.claude/sounds"
SOUND="$SOUNDS_DIR/additional-pylons.wav"
COOLDOWN_FILE="/tmp/pylons-last-played"
HIGH_LOAD_FLAG="/tmp/pylons-load-high"

# --- Configuration ---
# Adjust these to taste:
COOLDOWN_SECONDS=180  # Minimum seconds between alerts
THRESHOLD=$(nproc)    # Default: number of logical CPUs. Set to physical core count
                      # if you have hyperthreading (e.g., 16 cores / 32 threads → set to 16).
# ---------------------

# Get 1-minute load average
load1=$(awk '{print $1}' /proc/loadavg)

# Check if load is above threshold
is_high=$(awk "BEGIN { print ($load1 > $THRESHOLD) ? 1 : 0 }")

if [ "$is_high" -eq 0 ]; then
    rm -f "$HIGH_LOAD_FLAG"
    exit 0
fi

# Load IS high. Check if sustained (flag from previous check exists).
if [ ! -f "$HIGH_LOAD_FLAG" ]; then
    touch "$HIGH_LOAD_FLAG"
    exit 0
fi

# Sustained high load. Check cooldown.
if [ -f "$COOLDOWN_FILE" ]; then
    last_played=$(cat "$COOLDOWN_FILE")
    now=$(date +%s)
    elapsed=$((now - last_played))
    if [ "$elapsed" -lt "$COOLDOWN_SECONDS" ]; then
        exit 0
    fi
fi

# All checks passed — construct additional pylons!
date +%s > "$COOLDOWN_FILE"
bash "$SCRIPT_DIR/../scripts/play.sh" --sync "$SOUND"
