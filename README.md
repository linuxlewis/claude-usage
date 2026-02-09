# ClaudeUsage

A macOS menu bar app that shows your Claude.ai subscription usage limits at a glance.

![Screenshot](screenshot.png)

## Getting Started

1. **Download** the latest release from [GitHub Releases](https://github.com/linuxlewis/claude-usage/releases/latest) — grab `ClaudeUsage.zip`
2. **Unzip** and drag `ClaudeUsage.app` to your Applications folder
3. **Open** the app (first time: right-click → Open to bypass Gatekeeper since it's not code-signed)
4. **Click the gear icon** (⚙️) in the menu bar popover to open Settings
5. **Paste your credentials** (see below) and hit Save

That's it — your usage will appear in the menu bar within seconds.

### Getting Your Credentials

You need two things from claude.ai:

**Session Key:**
1. Go to [claude.ai](https://claude.ai) and sign in
2. Open Developer Tools (`⌘⌥I`)
3. Go to **Application** → **Cookies** → `https://claude.ai`
4. Copy the `sessionKey` value (starts with `sk-ant-sid`)

**Organization ID:**
1. In the same Developer Tools, go to **Console**
2. Run: `(await (await fetch('/api/organizations')).json())[0].uuid`
3. Copy the UUID

Paste both into the Settings panel and you're good to go.

## Building from Source

Requires macOS 13+ and Xcode 15+.

```bash
git clone https://github.com/linuxlewis/claude-usage.git
cd claude-usage
xcodebuild -scheme ClaudeUsage -configuration Release -destination 'platform=macOS' build
```

The app will be at:
```
~/Library/Developer/Xcode/DerivedData/ClaudeUsage-*/Build/Products/Release/ClaudeUsage.app
```

## Notes

- Uses an **unofficial, undocumented** Claude.ai API endpoint — may break at any time
- Session key is stored in the macOS Keychain; org ID in UserDefaults
- Usage refreshes every 5 minutes
- Menu bar shows the highest utilization percentage and next reset time
