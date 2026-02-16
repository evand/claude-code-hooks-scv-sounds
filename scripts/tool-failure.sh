#!/usr/bin/env bash
# PostToolUseFailure hook: plays "Can't build there" when a tool fails.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$HOME/.claude/sounds"
bash "$SCRIPT_DIR/play.sh" "$SOUNDS_DIR/cant-build-it.wav"
exit 0
