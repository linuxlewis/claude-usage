# CLAUDE.md — Claude Usage Menu Bar App

## Project Overview
A native macOS menu bar app that displays Claude.ai subscription usage limits.
See SPEC.md for full specification and prd.json for user stories.

## Tech Stack
- Swift + SwiftUI
- macOS 13+ (MenuBarExtra)
- Xcode project (MenuBarExtra requires app bundle)
- URLSession for networking
- Keychain for secure storage

## Build & Test
```bash
xcodebuild -scheme ClaudeUsage -destination 'platform=macOS' build    # Build the app
xcodebuild test -scheme ClaudeUsage -destination 'platform=macOS'     # Run unit tests
```

## Key Architecture Decisions
- Xcode project with ClaudeUsage app target and ClaudeUsageTests test target
- MenuBarExtra with .menuBarExtraStyle(.window) for popover
- LSUIElement=true (no dock icon) — set via Info.plist in bundle
- Session key stored in macOS Keychain (Security framework)
- Polls https://claude.ai/api/organizations/{orgId}/usage every 5 min

## API Details
- **Endpoint:** GET https://claude.ai/api/organizations/{orgId}/usage
- **Auth:** Cookie header with sessionKey
- **Headers:** anthropic-client-platform: web_claude_ai
- **Session key TTL:** ~30 days, echoed in Set-Cookie but not rotated
- See prd.json US-002 notes for sample JSON response

## Conventions
- Keep files small and focused
- Models in ClaudeUsage/Models/
- Views in ClaudeUsage/Views/
- Services in ClaudeUsage/Services/
- Tests in ClaudeUsageTests/
