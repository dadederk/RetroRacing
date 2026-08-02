# Special Events

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Time-limited events that grant temporary unlimited solo play without IAP.
- **Must not break:** UTC event boundaries; active events bypass play limits and paywall; event plays are not counted; permanent Unlimited Plays remains independent.
- **Key files:** `SpecialEventService`, `DateRangeSpecialEventService`, `MenuView`, `GameView`, `GameViewModel`, `SettingsView`.

## Current Event

| Field | Value |
|---|---|
| Name | Miami Grand Prix |
| Active window | 2026-05-01 00:00 UTC through 2026-05-04 00:00 UTC exclusive |
| User-facing dates | May 1-3, 2026 |
| Platforms | iOS, iPadOS, macOS, tvOS, visionOS |

## Behavior Contract

- During an active event, all users can play unlimited solo rounds.
- Event rounds do not call `PlayLimitService.recordGamePlayed`.
- The paywall is never shown because of play limits during an active event.
- The support/Unlimited Plays CTA may remain visible so users can still support development.
- Permanent Unlimited Plays is checked before event state and remains independent.
- When the event ends, free users return to normal daily limits.

## Gating Order

Menu Play and game-over Restart use this order:

1. Unlimited Plays entitlement: play.
2. Active special event: play without recording.
3. Daily play limit: play or show paywall.

## Service Contract

- `SpecialEventService.isEventActive(on:)` returns whether a date is inside the event window.
- `SpecialEventService.eventInfo(on:)` returns display metadata only while active.
- `DateRangeSpecialEventService` uses `[startDate, exclusiveEndDate)` UTC boundaries.
- Static event factories use explicit UTC date components, not raw epoch literals.
- Services are injected from composition roots, consistent with `PlayLimitService`.

## UI and Localization

- Free-user Settings Play Limit content becomes an event banner during active events.
- Banner title uses “Unlimited Plays”.
- Subtitle includes the event name and canonical event end date.
- The daily-limit footer is hidden while the event banner is shown.
- Event strings live in the shared string catalog.

## Operations

- App Store in-app event submission is separate from the app update and belongs in `AppStore/` or `Plans/aso/` when an event campaign is active.
- Do not add App Store Connect step-by-step instructions to this requirement.

## Testing

- Unit tests cover before/start/mid/end/exclusive-end dates, `eventInfo`, year-drift regression, gating bypass, and record-skip behavior.
- Manual QA for each active event covers free user, Unlimited Plays user, post-event reset, Settings banner, paywall suppression, and support CTA visibility.
