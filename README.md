# ClaudeUsage

A macOS menu bar app that shows your Claude.ai subscription usage limits at a glance.

![Screenshot placeholder](screenshot.png)

## Requirements

- macOS 13+
- Xcode 15+

## Build

```bash
xcodebuild -scheme ClaudeUsage -destination 'platform=macOS' build
```

The built app will be at:
```
~/Library/Developer/Xcode/DerivedData/ClaudeUsage-*/Build/Products/Debug/ClaudeUsage.app
```

## Setup

You need two values from claude.ai:

### Session Key
1. Open https://claude.ai in your browser
2. Open Developer Tools (⌘⌥I)
3. Go to **Application** → **Cookies** → `https://claude.ai`
4. Copy the value of the `sessionKey` cookie

### Organization ID
Find it in the claude.ai URL — it's the UUID after `/chat/`:
```
https://claude.ai/chat/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Or call the API:
```bash
curl -s 'https://claude.ai/api/organizations' \
  -H 'Cookie: sessionKey=YOUR_KEY' | python3 -m json.tool
```

Paste both values into the app's Settings panel.

## Notes

- This uses an **unofficial, undocumented** Claude.ai API endpoint — it may break at any time
- The session key is stored in the macOS Keychain; the org ID is stored in UserDefaults
- Usage data refreshes every 5 minutes
- The menu bar shows the highest utilization percentage across all limits and the next reset time
