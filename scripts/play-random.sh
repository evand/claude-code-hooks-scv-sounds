#!/usr/bin/env bash
# Play a random WAV file from the arguments.
# Usage: play-random.sh <file1.wav> <file2.wav> ...
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

sounds=("$@")
if [ ${#sounds[@]} -eq 0 ]; then exit 0; fi
chosen="${sounds[$((RANDOM % ${#sounds[@]}))]}"
bash "$SCRIPT_DIR/play.sh" "$chosen"
