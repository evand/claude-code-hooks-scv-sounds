#!/usr/bin/env bash
set -euo pipefail

# StarCraft Hooks Installer for Claude Code
# Copies sounds and scripts to ~/.claude/, optionally sets up the pylons load monitor.

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SOUNDS_DIR="$CLAUDE_DIR/sounds"
SCRIPTS_DIR="$CLAUDE_DIR/scripts"
PYLONS_DIR="$CLAUDE_DIR/pylons"

echo "=== StarCraft Hooks for Claude Code ==="
echo ""

# --- Sounds ---
echo "Installing sounds to $SOUNDS_DIR/..."
mkdir -p "$SOUNDS_DIR"
cp "$REPO_DIR"/sounds/*.wav "$SOUNDS_DIR/"
echo "  Copied $(ls "$REPO_DIR"/sounds/*.wav | wc -l) sound files."

# --- Scripts ---
echo "Installing scripts to $SCRIPTS_DIR/..."
mkdir -p "$SCRIPTS_DIR"
cp "$REPO_DIR"/scripts/*.sh "$SCRIPTS_DIR/"
chmod +x "$SCRIPTS_DIR"/*.sh
echo "  Copied $(ls "$REPO_DIR"/scripts/*.sh | wc -l) scripts."

# --- Pylons ---
echo "Installing pylons monitor to $PYLONS_DIR/..."
mkdir -p "$PYLONS_DIR"
cp "$REPO_DIR"/pylons/pylons-monitor.sh "$PYLONS_DIR/"
chmod +x "$PYLONS_DIR/pylons-monitor.sh"

if [ "$(uname)" = "Linux" ] && command -v systemctl >/dev/null 2>&1; then
    echo ""
    read -p "Set up pylons systemd timer? (monitors load average) [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SYSTEMD_DIR="$HOME/.config/systemd/user"
        mkdir -p "$SYSTEMD_DIR"
        cp "$REPO_DIR"/pylons/pylons-monitor.service "$SYSTEMD_DIR/"
        cp "$REPO_DIR"/pylons/pylons-monitor.timer "$SYSTEMD_DIR/"
        systemctl --user daemon-reload
        systemctl --user enable --now pylons-monitor.timer
        echo "  Pylons monitor enabled! Edit $PYLONS_DIR/pylons-monitor.sh to adjust threshold."
    fi
fi

# --- Hooks config ---
echo ""
echo "=== Almost done! ==="
echo ""
if [ -f "$CLAUDE_DIR/settings.json" ]; then
    echo "You already have a settings.json. Merge the hooks from:"
    echo "  $REPO_DIR/settings.json"
    echo ""
    echo "Or ask Claude to do it:"
    echo '  "Merge the hooks from ~/path/to/settings.json into my ~/.claude/settings.json"'
else
    echo "Installing hooks config..."
    cp "$REPO_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    echo "  Installed to $CLAUDE_DIR/settings.json"
fi

echo ""
echo "Done! Restart Claude Code to hear \"SCV good to go, sir!\""
echo ""
echo "Remember: this is a starting point. Ask Claude to review these hooks"
echo "and customize them for YOUR workflow."
