# Additional Pylons Load Monitor

Plays "You must construct additional pylons" when your system load is sustained above your CPU core count.

## How It Works

- Checks 1-minute load average every 30 seconds (via systemd timer)
- Requires **2 consecutive** high readings before alerting (ignores momentary spikes)
- **3-minute cooldown** between alerts (configurable in the script)
- Default threshold: `nproc` (logical CPUs). If you have hyperthreading, edit `THRESHOLD` in the script to your physical core count.

## Linux Setup (systemd)

```bash
# Copy files
cp pylons-monitor.sh ~/.claude/pylons/
cp pylons-monitor.service pylons-monitor.timer ~/.config/systemd/user/

# Edit threshold if needed
$EDITOR ~/.claude/pylons/pylons-monitor.sh  # Set THRESHOLD=<physical cores>

# Enable
systemctl --user daemon-reload
systemctl --user enable --now pylons-monitor.timer
```

## macOS Setup (launchd)

Create `~/Library/LaunchAgents/com.claude.pylons-monitor.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.claude.pylons-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${HOME}/.claude/pylons/pylons-monitor.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>30</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

Then: `launchctl load ~/Library/LaunchAgents/com.claude.pylons-monitor.plist`

> **Note:** The macOS version needs `/proc/loadavg` replaced with `sysctl -n vm.loadavg` parsing. Contributions welcome!

## Checking Status

```bash
# Linux
systemctl --user status pylons-monitor.timer
cat /tmp/pylons-last-played  # Unix timestamp of last alert

# Test manually
bash ~/.claude/pylons/pylons-monitor.sh
```
