# Logging

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** Canonical `AppLog` structured logging grammar, domains, outcomes, and privacy rules.
- **Must not break:** Machine-queryable shape; privacy-safe fields; stable domain emojis; errors use structured fields.
- **Key files:** `AppLog` and feature log call sites.

## Message Shape

```text
<emoji> <DOMAIN> <EVENT_NAME>: outcome=<state> key=value key=value
```

- Use `AppLog` structured APIs for runtime logs.
- Domain is an uppercase stable token from `AppLog.Domain`.
- Event name is uppercase snake case.
- `outcome=` is first when present.
- Use compact fields: booleans, numbers, enums, short IDs, redacted metadata.

## Outcomes

Allowed outcomes: `requested`, `started`, `succeeded`, `completed`, `failed`, `blocked`, `ignored`, `skipped`, `deferred`, `cancelled`.

- Failure-like outcomes include `reason=<snake_case>`.
- Errors prefer `AppLog.Field.error(_:)` or equivalent domain/code/description fields.

## Domains

Core domains include assets, sound, font, localization, theme, game, leaderboard, achievement, monetization, input, accessibility, lifecycle, store, rating, and SharePlay/lifecycle diagnostics where implemented.

- Keep emoji/domain mappings stable once log consumers depend on them.
- Use one primary emoji/domain; add secondary only for true cross-domain overlap.

## Privacy

Use redaction helpers for:

- player display names
- URLs
- filesystem paths
- long or sensitive identifiers

Never log raw player names, full URLs, full local paths, or App Store credential material.

## Bug Capture

- Start with the smallest relevant domain/emoji filter.
- Widen only when the filtered capture lacks the needed context.
- Keep user-facing capture instructions short and task-specific.

Examples:

```bash
log stream --predicate 'eventMessage CONTAINS "LEADERBOARD"' --level debug
log stream --predicate 'eventMessage CONTAINS "SHAREPLAY"' --level debug
```
