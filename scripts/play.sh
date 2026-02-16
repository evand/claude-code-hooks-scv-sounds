#!/usr/bin/env bash
# Cross-platform audio player for WAV files.
# Detects available player: pw-play (PipeWire), paplay (PulseAudio), afplay (macOS).
# Usage: play.sh <file.wav>
#   Plays asynchronously (backgrounds and detaches).
# Usage: play.sh --sync <file.wav>
#   Plays synchronously (blocks until done). Needed for systemd services.

SYNC=0
if [ "$1" = "--sync" ]; then
    SYNC=1
    shift
fi

FILE="$1"
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    exit 0
fi

# Find a working player
play_cmd=""
if command -v pw-play >/dev/null 2>&1; then
    play_cmd="pw-play"
elif command -v paplay >/dev/null 2>&1; then
    play_cmd="paplay"
elif command -v afplay >/dev/null 2>&1; then
    play_cmd="afplay"
elif command -v aplay >/dev/null 2>&1; then
    play_cmd="aplay"
else
    exit 0  # No player available, fail silently
fi

if [ "$SYNC" -eq 1 ]; then
    $play_cmd "$FILE"
else
    nohup $play_cmd "$FILE" >/dev/null 2>&1 &
fi
