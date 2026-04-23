# Logging

## Purpose

Define the canonical runtime logging contract for RetroRacing across shared code and platform targets.

## Behavior Contract

- Runtime logs must use `AppLog` structured APIs only.
- Log lines must follow canonical grammar and be machine-queryable.
- Log levels and domain emojis must stay consistent across features.
- Logs must be privacy-safe: no raw player names, full URLs, or full filesystem paths.
- Bug capture should start with emoji/domain filtering and only widen scope when needed.

## Canonical Message Shape

```text
<emoji> <DOMAIN> <EVENT_NAME>: outcome=<state> key=value key=value
```

Rules:
- `<emoji>`: required; one primary domain emoji, optional secondary emoji for true cross-domain overlap.
- `<DOMAIN>`: required; uppercase snake-case domain token from `AppLog.Domain`.
- `<EVENT_NAME>`: required; uppercase snake-case stable event name.
- `outcome=` should be first body field when present.
- Use compact key/value fields (booleans, numbers, enums, short IDs, redacted metadata).

## Outcomes

Allowed outcomes:
- `requested`
- `started`
- `succeeded`
- `completed`
- `failed`
- `blocked`
- `ignored`
- `skipped`
- `deferred`
- `cancelled`

Failure-like outcomes should include `reason=<snake_case>`.

## Domains & Emoji Map

Core domains:
- `ASSETS` `🖼️`
- `SOUND` `🔊`
- `FONT` `🔤`
- `LOCALIZATION` `🌐`
- `THEME` `🎨`
- `GAME` `🎮`
- `LEADERBOARD` `🏆`
- `ACHIEVEMENT` `🏅`
- `MONETIZATION` `💰`
- `INPUT` `🎛️`
- `ACCESSIBILITY` `♿`
- `LIFECYCLE` `📱`
- `STORE` `🛒`
- `RATING` `⭐`

## Level Policy

- `debug`: high-frequency traces and diagnostics (input deltas, cache hits, graph dirty/rebuild internals).
- `info`: normal lifecycle transitions and successful operations.
- `warning`: recoverable or deferred paths (ignored/blocked/skipped that are expected but noteworthy).
- `error`: operation failures.
- `critical`: invariant or system-breaking failures requiring immediate attention.

## Redaction Policy

Use `AppLog` redaction helpers for sensitive fields:
- `AppLog.shortID(_:)`
- `AppLog.redactedURL(_:)`
- `AppLog.redactedPath(_:)`
- `AppLog.redactedPlayer(_:)`

Never log raw values for:
- player display names,
- full URL strings (`absoluteString`),
- full local paths.

For errors, prefer structured domain/code fields via `AppLog.Field.error(_:)`.

## Bug-Capture Workflow

1. Start with the smallest emoji/domain set relevant to the issue.
2. Capture filtered logs first; widen only if needed.
3. Keep user instructions targeted and minimal.

Examples:

```bash
# Leaderboard / Game Center
log stream --predicate 'eventMessage CONTAINS "🏆"' --level debug

# Input / controls
log stream --predicate 'eventMessage CONTAINS "🎛️"' --level debug

# Audio
log stream --predicate 'eventMessage CONTAINS "🔊"' --level debug
```
