# Multi-Account Support — Spec

## Overview

Add the ability to manage multiple Claude accounts in the menu bar app. Users can switch between accounts from the main dropdown and add new accounts via a "+" button in the bottom toolbar.

## Current State

- **Single account**: One `sessionKey` + one `orgId` stored in Keychain/UserDefaults
- **KeychainService**: Hardcoded keys (`sessionKey`, `orgId`) — no account multiplexing
- **UsageViewModel**: Holds one `UsageData?`, polls one account
- **Bottom toolbar**: 3 icons — refresh, settings (gear), quit (power)
- **SettingsView**: Configures the single account's session key, org ID, and launch-at-login

## Data Model Changes

### New: `Account` model

```swift
struct Account: Identifiable, Codable, Equatable {
    let id: UUID
    var email: String           // Display label for switching
    var sessionKey: String?     // nil until configured
    var orgId: String?          // nil until configured
    var isConfigured: Bool { sessionKey != nil && orgId != nil }
}
```

### New: `AccountStore`

Manages the list of accounts and the active selection. Persists to `UserDefaults` (account metadata) + Keychain (session keys per account ID).

```swift
class AccountStore: ObservableObject {
    @Published var accounts: [Account]
    @Published var activeAccountId: UUID?

    var activeAccount: Account? { accounts.first { $0.id == activeAccountId } }

    func add(email: String) -> Account        // Creates unconfigured account
    func remove(id: UUID)                      // Deletes account + keychain entry
    func setActive(id: UUID)                   // Switches active account
    func update(_ account: Account)            // Saves changes (e.g. after settings)
}
```

### KeychainService Changes

Replace the single hardcoded key with account-scoped keys:

```swift
// Before
KeychainService.save(key: .sessionKey, value: "sk-ant-...")

// After
KeychainService.save(service: "com.claudeusage.credentials", 
                     account: "\(accountId)-sessionKey", 
                     value: "sk-ant-...")
```

The `orgId` moves from a single UserDefaults key to per-account storage (either in the `Account` codable blob or as `"\(accountId)-orgId"` in UserDefaults).

### UsageViewModel Changes

- Takes an `AccountStore` dependency instead of reading Keychain directly
- Polls the **active account** only
- On `activeAccountId` change: cancel current polling, start new polling for the newly selected account
- Exposes `activeEmail: String?` for display

## UI Changes

### 1. Account Switcher (top of dropdown)

When multiple accounts exist, add an account selector at the top of the popover, above the usage bars:

```
┌─────────────────────────────┐
│  ▾ sam@example.com          │  ← Picker/Menu to switch accounts
├─────────────────────────────┤
│  Session    ████████░░ 80%  │
│  Weekly     ████░░░░░░ 40%  │
│  ...                        │
├─────────────────────────────┤
│  + Updated 2m ago   ⟳ ⚙ ⏻  │
└─────────────────────────────┘
```

- **Component**: `Picker` or `Menu` styled as a dropdown
- **Label**: Active account's email
- **Options**: All accounts listed by email
- **Behavior**: Selecting a different account calls `accountStore.setActive(id:)`, which triggers `UsageViewModel` to re-fetch

When only one account exists, the picker is hidden (no change from current UI).

### 2. "+" Button in Bottom Toolbar

Add a `plus` icon button to the far left of the bottom bar, before the status text:

```
+  Updated 2m ago   ⟳  ⚙  ⏻
```

- **Icon**: `plus.circle` or `plus`
- **Action**: Shows an inline popover or small sheet with a single text field:

```
┌─────────────────────────┐
│  Add Account             │
│                          │
│  Email: [            ]   │
│                          │
│  [Cancel]       [Add]    │
└─────────────────────────┘
```

- On **Add**: Creates a new `Account(email: input, sessionKey: nil, orgId: nil)`, switches to it, and the main view shows the "Not configured" state with an "Open Settings" button
- The user then clicks into Settings to provide session key + org ID for that account

### 3. Settings View Changes

Settings now configures **the active account**:

- **Header**: Shows the active account's email (non-editable here, or editable if we want)
- **Fields**: Same as today — session key, org ID
- **Save**: Updates the active account in `AccountStore`
- **New section**: "Accounts" list at the bottom showing all accounts with a delete (trash) button per row
  - Cannot delete the last remaining account
  - Deleting the active account switches to the next available one

### 4. Menu Bar Label

The menu bar text stays the same (shows usage % + reset time for the active account). No change needed unless we want to show which account is active — could optionally prepend a short label, but probably not worth the space.

## Migration

On first launch after update:
1. Check if old-style single credentials exist (`KeychainService.read(key: .sessionKey)`)
2. If yes, create a default `Account` with `email: "Account 1"` (or prompt for email) and migrate the credentials
3. Set it as the active account
4. Delete old-style keys

## State Flow

```
App Launch
  → AccountStore.init() loads accounts from UserDefaults
  → If no accounts exist + old credentials found → migrate
  → UsageViewModel starts polling activeAccount
  
User clicks "+"
  → Add Account sheet appears
  → User enters email, clicks Add
  → New unconfigured account created & set active
  → Main view shows "Not configured — Open Settings"
  → User opens Settings, pastes session key + org ID, clicks Save
  → UsageViewModel starts polling new account
  
User switches account via picker
  → AccountStore.setActive(newId)
  → UsageViewModel cancels old poll, starts new poll
  → UI updates with new account's cached data (or fetches fresh)
```

## File Changes Summary

| File | Change |
|------|--------|
| `Models/Account.swift` | **New** — `Account` struct |
| `Services/AccountStore.swift` | **New** — Multi-account persistence + selection |
| `Services/KeychainService.swift` | Add account-scoped read/save/delete methods |
| `Models/UsageViewModel.swift` | Depend on `AccountStore`, poll active account only |
| `Views/ContentView.swift` | Add account picker (top), "+" button (bottom bar) |
| `Views/AddAccountView.swift` | **New** — Small popover/sheet for entering email |
| `Views/SettingsView.swift` | Scope to active account, add account list section |
| `ClaudeUsageApp.swift` | Create `AccountStore` as `@StateObject`, inject into views |

## Edge Cases

- **All accounts unconfigured**: Show "Not configured" for whichever is active
- **Active account deleted**: Auto-switch to first remaining account
- **Session expired on one account**: Only that account shows the expired state; others unaffected
- **Duplicate emails**: Allow it (different orgs/sessions could share an email, though unlikely)
- **Zero accounts**: Should never happen — always have at least one. Migration creates one from existing creds, or fresh install starts with an "Add Account" prompt

## Out of Scope (for now)

- Simultaneous polling of all accounts (only active account is polled)
- Aggregate view showing all accounts at once
- Per-account polling intervals
- Account reordering
