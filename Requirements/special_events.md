# Special Events – Temporary Unlimited Play

## Overview

RetroRacing supports time-limited **special events** that grant unlimited play to all users — including free-tier users — for the duration of the event, without requiring the Unlimited Plays purchase.

Events are used for:
- Major motorsport weekends (Miami Grand Prix, Monaco GP, etc.)
- Seasonal promotions
- Apple In-App Events (App Store discoverability campaigns)

## Current Events

### Miami Grand Prix 2026

| Field | Value |
|-------|-------|
| **Name** | Miami Grand Prix |
| **Active window** | May 1, 2026 00:00 UTC — May 4, 2026 00:00 UTC (exclusive) |
| **User-facing dates** | May 1 – May 3, 2026 |
| **Platforms** | iOS, iPadOS, macOS, tvOS, visionOS |

## Business Rules

- During an active event, **all users** (free and paid) can play unlimited games.
- Event plays are **not counted** against the user's daily play quota. When the event ends, daily limits resume from their normal state for that calendar day (which is typically a fresh day since events end at midnight UTC).
- The "Buy Unlimited Plays" support CTA in the menu remains **visible during events** so users can still support development whenever they want.
- The paywall is **never shown** during an active event.
- The **premium purchase remains independent**: users who purchase Unlimited Plays during or after an event retain their permanent entitlement.

## Play-Gating Decision Chain

Both `MenuView` (Play button) and `GameView` (Restart button after game over) use this three-step chain in order:

```
1. StoreKitService.hasPremiumAccess   → play (permanent purchase)
2. SpecialEventService.isEventActive  → play (event bypass)
3. PlayLimitService.canStartNewGame   → check daily limit → paywall if limit reached
```

Premium is always checked **first** and is **completely isolated** from the event check. A bug in event logic cannot affect premium users.

## Architecture

### `SpecialEventService` Protocol

**File:** `RetroRacingShared/Services/Protocols/SpecialEventService.swift`

```swift
public protocol SpecialEventService {
    func isEventActive(on date: Date) -> Bool
    func eventInfo(on date: Date) -> SpecialEventInfo?
}

public struct SpecialEventInfo {
    public let name: String            // Display name ("Miami Grand Prix")
    public let startDate: Date         // Inclusive start, midnight UTC
    public let inclusiveEndDate: Date  // Last event day at midnight UTC (for display)
}
```

### `DateRangeSpecialEventService` Implementation

**File:** `RetroRacingShared/Services/Implementations/DateRangeSpecialEventService.swift`

- Driven by a UTC date range: `[startDate, exclusiveEndDate)` where `exclusiveEndDate = inclusiveEndDate + 1 day`.
- `isEventActive(on:)` returns `true` when the given date falls within the active window.
- `eventInfo(on:)` returns `SpecialEventInfo` when active, `nil` otherwise.
- Uses UTC boundaries so all users worldwide experience the same event window.
- Static event factories use explicit UTC date components (`year`, `month`, `day`) rather than raw epoch literals to reduce year-mismatch risk.

### Play Recording Bypass

**Files:** `RetroRacingShared/Views/GameViewModel+Scene.swift`, `RetroRacingShared/Views/GameViewModel+Gameplay.swift`

When a new game session is created **or restarted after game over**, `recordGamePlayed` is skipped during an active event:

```swift
let now = Date()
if specialEventService?.isEventActive(on: now) != true {
    playLimitService?.recordGamePlayed(on: now)
}
```

### Settings Banner

**File:** `RetroRacingShared/Views/SettingsView.swift`

The **Play Limit** section is shown for free users. During an active event, the section content is replaced with an event banner:

- **Title:** "Unlimited Plays"
- **Subtitle:** "Unlimited until [end date], celebrating [event name] 🏎"
- The subtitle end date is formatted using a UTC/Gregorian reference so it always reflects the event's canonical May 1–3 window.
- The daily limit footer is hidden during the event.

After the event, the section reverts to showing remaining plays and reset time.

## Dependency Injection

`SpecialEventService` is constructed at the composition root and injected via `init` parameters (consistent with `PlayLimitService` injection pattern):

```swift
// RetroRacingApp.swift / RetroRacingTvOSApp.swift
specialEventService = Self.makeMiamiGrandPrixEventService()

// Injected into:
GameView(specialEventService: specialEventService, ...)
MenuView(specialEventService: specialEventService, ...)
SettingsView(specialEventService: specialEventService, ...)
GameViewModel(specialEventService: specialEventService, ...)
```

## Localization

**File:** `RetroRacingShared/Localizable.xcstrings`

| Key | English |
|-----|---------|
| `event_play_unlimited_title` | "Unlimited Plays" |
| `event_play_unlimited_subtitle %@ %@` | "Unlimited until %@, celebrating %@ 🏎" |

Localized into English, Spanish (es), and Catalan (ca).

## Apple In-App Event Submission

The App Store in-app event is a **separate submission** in App Store Connect, independent of the app update:

### Steps

1. Log in to App Store Connect → Your App → **In-App Events**
2. Create new event:
   - **Event type**: Sale or Promotion (or Challenge)
   - **Reference name**: Miami Grand Prix 2026
   - **Event period**: May 1, 2026 – May 3, 2026
3. Add event metadata:
   - **Name** (30 chars): "Miami Grand Prix Weekend"
   - **Short description** (45 chars): "Drive free all weekend, no limits!"
   - **Long description** (120 chars): "To celebrate the Miami Grand Prix, every player gets unlimited play May 1–3. Start your engines — no purchase needed!"
4. Upload assets:
   - Event badge (1024×1024)
   - Event card (2160×1080 landscape image or short video)
5. Submit for App Review (allow 7-14 days)

> ⚠️ **Submit the in-app event as soon as possible.** Apple recommends at least 2 weeks lead time before the start date (May 1, 2026).

### Timeline

| Task | Target date |
|------|------------|
| Submit app update (technical implementation) | By April 24, 2026 |
| Submit in-app event via App Store Connect | ASAP (by April 17 ideally) |
| Event goes live | May 1, 2026 |

## Testing

### Unit Tests

**File:** `RetroRacingSharedTests/SpecialEventServiceTests.swift`

Scenarios covered:

- Date before event window → `isEventActive` returns `false`
- Exact start date → `isEventActive` returns `true`
- Mid-event date → `isEventActive` returns `true`
- Last event day (23:59) → `isEventActive` returns `true`
- Exact exclusive end (May 4 00:00 UTC) → `isEventActive` returns `false`
- Date after event → `isEventActive` returns `false`
- `eventInfo` returns info with correct name and `inclusiveEndDate` during event
- `eventInfo` returns `nil` when event is inactive
- Static `miamiGrandPrix2026` factory is active on May 2, 2026 and inactive on May 2, 2025 (regression guard for year drift)

### Manual QA Checklist

To test the event locally, temporarily set the device date to May 2, 2026 (or adjust `makeMiamiGrandPrixEventService` dates to cover today):

**Free user during event:**
- [ ] Play button works without limit
- [ ] Paywall never appears
- [ ] Restart after game over works without limit
- [ ] Settings → Play Limit section shows "Unlimited Plays" banner with event subtitle ending in 🏎
- [ ] "Support" / "Back development" CTA remains visible in menu
- [ ] Plays are not counted (remaining plays same after gaming session)

**Premium user during event:**
- [ ] Play button works (premium path, unchanged)
- [ ] Settings shows premium status (unchanged)
- [ ] No regression in any premium behaviour

**After event ends (May 4+):**
- [ ] Daily limit resumes normally
- [ ] Settings Play Limit section shows remaining plays and reset time
- [ ] Paywall appears when limit reached

## Future Enhancements

- Remote configuration for event dates (toggle without app update)
- Multiple simultaneous events (protocol supports it via `eventInfo(on:)` returning any active event)
- Event-specific messaging on the paywall ("The event has ended — buy Unlimited Plays to keep going!")
- watchOS event banner in Watch complications or notification
