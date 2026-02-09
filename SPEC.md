# Claude Usage Menu Bar App — Spec

## Overview

A native macOS menu bar app that displays Claude.ai subscription usage limits (session + weekly) at a glance. Polls the unofficial `claude.ai/api/organizations/{orgId}/usage` endpoint.

## Data Source

**Endpoint:** `GET https://claude.ai/api/organizations/{orgId}/usage`  
**Auth:** `sessionKey` cookie (30-day TTL, echoed back in Set-Cookie but not rotated)  
**Response:**
```json
{
  "five_hour": { "utilization": 17.0, "resets_at": "2026-02-08T18:59:59Z" },
  "seven_day": { "utilization": 11.0, "resets_at": "2026-02-14T16:59:59Z" },
  "seven_day_sonnet": { "utilization": 0.0, "resets_at": null },
  "seven_day_opus": { "utilization": 5.0, "resets_at": "..." },
  "seven_day_oauth_apps": null,
  "seven_day_cowork": null,
  "extra_usage": null
}
```

## Menu Bar Icon

A **circular progress ring** that shows the highest current utilization:

- Ring fills proportionally (e.g. 40% used = ring 40% filled)
- Color coded:
  - **Green** — < 50%
  - **Yellow** — 50–79%
  - **Red** — ≥ 80%
- Next to the circle: **reset time in local timezone** (e.g. `11:00 PM`)
  - Shows the reset time for whichever limit is highest (session or weekly)

**Examples:**
```
🟢⌓ 11:00 PM     ← 16% session, resets at 11pm
🟡◑ Sat 10:59 AM  ← 65% weekly, resets Saturday
🔴◕ 2:30 PM       ← 90% session, resets at 2:30pm
```

## Click-to-Expand Popover

```
┌─────────────────────────────┐
│  Session         ◑    16%   │
│  ████░░░░░░░░░░░░░░░░       │
│  Resets at 11:00 PM         │
│                             │
│  Weekly          ◔    11%   │
│  ██░░░░░░░░░░░░░░░░░░       │
│  Resets Sat 10:59 AM        │
│                             │
│  Sonnet                 0%  │
│  ░░░░░░░░░░░░░░░░░░░░       │
│                             │
│  Opus                   0%  │
│  ░░░░░░░░░░░░░░░░░░░░       │
│                             │
│  Updated 2m ago     🔄  ⚙️  │
└─────────────────────────────┘
```

Each limit shows:
- Name + circular progress ring + percentage
- Horizontal bar
- Reset time in user's local timezone
- Only shown if the field is present in the response (some are null)

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI + `MenuBarExtra` (macOS 13+)
- **Networking:** URLSession (native, no deps)
- **Storage:** UserDefaults for settings, Keychain for session key
- **Min target:** macOS 13 Ventura

## Features (MVP)

- [ ] Menu bar circular progress ring with color coding
- [ ] Local timezone reset time next to icon
- [ ] Click to expand popover with all usage bars
- [ ] Poll every 5 minutes
- [ ] Reset countdown timers in local timezone
- [ ] Settings: enter session key + org ID
- [ ] Store session key in Keychain
- [ ] Handle session key refresh from Set-Cookie responses
- [ ] Graceful error states (expired session, network error)
- [ ] Launch at login option

## Auth Flow

1. **First launch:** User pastes `sessionKey` cookie value from browser dev tools
2. **Storage:** Session key stored in macOS Keychain (encrypted at rest)
3. **Refresh:** Every response checked for `Set-Cookie: sessionKey=...` — if new value, Keychain updated automatically
4. **Expiry:** If 401/403 received, show error badge on icon + prompt to re-auth in settings
5. **Org ID:** User provides manually (no discovery endpoint available)

## Polling Strategy

- Default: every 5 minutes
- Manual refresh button always available
- Pause on network error, retry with backoff

## File Structure

```
ClaudeUsage/
├── ClaudeUsageApp.swift          # App entry, MenuBarExtra
├── Views/
│   ├── UsagePopover.swift        # Main popover content
│   ├── UsageBar.swift            # Single usage bar component
│   ├── CircleProgress.swift      # Circular progress ring
│   └── SettingsView.swift        # Settings sheet
├── Models/
│   ├── UsageData.swift           # Codable model for API response
│   └── AppSettings.swift         # User preferences
├── Services/
│   ├── UsageService.swift        # API client + polling
│   └── KeychainService.swift     # Keychain read/write
└── Info.plist
```

## Open Questions

- **Rate limiting:** Does claude.ai rate-limit the usage endpoint? Monitoring via CLI watch
- **TOS:** This uses an unofficial internal API — could break or be blocked at any time
