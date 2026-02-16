#!/usr/bin/env bash
# PreToolUse hook for Bash: plays "Nuclear launch detected" for dangerous commands.
# Reads tool input JSON from stdin, checks the command field for destructive patterns.
# Does NOT block the command — just plays the warning sound.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOUNDS_DIR="$HOME/.claude/sounds"

# Read stdin JSON
input=$(cat)

# Extract the command field from tool input
command=$(echo "$input" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
print(tool_input.get('command', ''))
" 2>/dev/null)

if [ -z "$command" ]; then
    exit 0
fi

# Dangerous patterns that warrant a warning
dangerous=0
case "$command" in
    *"push --force"*|*"push -f "*|*"push -f"$)  dangerous=1 ;;
    *"reset --hard"*)                             dangerous=1 ;;
    *"rm -rf"*|*"rm -r "*"/"*)                    dangerous=1 ;;
    *"git clean -f"*|*"git clean -df"*)           dangerous=1 ;;
    *"branch -D "*|*"branch -D"$)                 dangerous=1 ;;
    *"--no-verify"*)                              dangerous=1 ;;
    *"drop table"*|*"DROP TABLE"*)                dangerous=1 ;;
    *"> /dev/"*|*"mkfs."*)                        dangerous=1 ;;
    *"checkout -- ."*|*"checkout ."*)             dangerous=1 ;;
    *"restore ."*)                                dangerous=1 ;;
esac

if [ "$dangerous" -eq 1 ]; then
    bash "$SCRIPT_DIR/play.sh" "$SOUNDS_DIR/nuclear-launch-detected.wav"
fi

exit 0
