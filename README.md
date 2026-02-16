# StarCraft Hooks for Claude Code

StarCraft sound effects for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), using [hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to play audio cues at key moments in your workflow.

Forked from [htjun/claude-code-hooks-scv-sounds](https://github.com/htjun/claude-code-hooks-scv-sounds) with expanded hook coverage, cross-platform Linux support, a dangerous-command detector, and a load monitor.

> **Don't just clone this.** This repo is a *starting point*, not a drop-in package. Everyone's workflow is different. Ask your Claude to review these hooks, suggest changes, and rewrite the config to match how *you* work. The value is in the idea — StarCraft sounds mapped to IDE events — not in this specific configuration.

## Quick Start

```bash
git clone https://github.com/evand/claude-code-hooks-scv-sounds.git
cd claude-code-hooks-scv-sounds
bash install.sh
```

Then restart Claude Code. You should hear *"SCV good to go, sir!"*

## Hooks

| Event | Sound | When it plays |
|---|---|---|
| **SessionStart** (new) | *"SCV good to go, sir!"* | Launch Claude Code |
| **SessionStart** (resume) | *"Reporting for duty"* | Resume a session |
| **UserPromptSubmit** | Random SCV ack | You send a message |
| **Stop** | *"Job's finished"* / *"Orders, cap'n?"* | Claude finishes responding |
| **SubagentStop** | *"Buckle up"* (Dropship) | Background agent completes |
| **Notification** (permission) | *"Your forces are under attack"* | Permission prompt appears |
| **PreToolUse** (Bash) | *"Nuclear launch detected"* | Dangerous command: `--force`, `rm -rf`, `reset --hard`, etc. |
| **PostToolUseFailure** | *"Can't build there"* | Any tool call fails |
| **SessionEnd** | *"In the rear with the gear"* | Exit the session |

## Additional Pylons (Load Monitor)

A background service that plays *"You must construct additional pylons"* when your system load stays above your CPU core count.

- Runs every 30 seconds via systemd timer (Linux) or launchd (macOS)
- Requires 2 consecutive high readings before alerting (ignores spikes)
- 3-minute cooldown between alerts
- Configurable threshold

The installer will offer to set this up. See [pylons/README.md](pylons/README.md) for manual setup and macOS instructions.

## Nuclear Launch Detector

The `PreToolUse` hook watches for dangerous shell commands and plays *"Nuclear launch detected"* as a warning. It does **not** block execution — Claude Code's own permission system handles that. It just makes sure you *hear* it.

Patterns detected:
- `git push --force`, `git reset --hard`, `git clean -f`
- `rm -rf`, `branch -D`, `checkout .`, `restore .`
- `--no-verify`, `DROP TABLE`, `mkfs.`

## Sounds

19 WAV files included, sourced from StarCraft and StarCraft II:

**SCV acknowledgments:** affirmative, orders-received, right-away-sir, read-you, good-to-go-sir, reporting-for-duty, jobs-finished, orders-captain, in-the-rear

**SCV personality:** cant-believe, claustrophobic, this-too, cant-build-it

**Advisor/alert sounds:** nuclear-launch-detected, under-attack, base-under-attack, additional-pylons, not-enough-minerals

**Other units:** buckle-up (Dropship)

Want different sounds? The full SC1 sound archive is available at [The Sounds Resource](https://sounds.spriters-resource.com/pc_computer/starcraft/) — every unit, every voice line, as original WAV files.

## Cross-Platform

All scripts use `scripts/play.sh` which auto-detects your audio system:

| Platform | Player |
|---|---|
| Linux (PipeWire) | `pw-play` |
| Linux (PulseAudio) | `paplay` |
| Linux (ALSA) | `aplay` |
| macOS | `afplay` |

## File Structure

```
sounds/              WAV files (copied to ~/.claude/sounds/)
scripts/
  play.sh            Cross-platform audio player
  play-random.sh     Random sound picker
  nuclear-launch-detector.sh
  tool-failure.sh
pylons/
  pylons-monitor.sh  Load monitor with hysteresis
  pylons-monitor.service/timer  systemd units
  README.md          Setup instructions
settings.json        Example hooks config
install.sh           Auto-installer
```

## Customization Ideas

- Map **Battlecruiser** *"Make it happen"* to successful test runs
- Play **Zealot** *"My life for Aiur!"* on `git push`
- Use **Adjutant** alerts for CI/CD notifications via MCP
- Add **Zerg** sounds for your coworker's machine

## Credits

- Original concept: [htjun/claude-code-hooks-scv-sounds](https://github.com/htjun/claude-code-hooks-scv-sounds)
- Sound effects from StarCraft and StarCraft II by Blizzard Entertainment
- Built with Claude Code
