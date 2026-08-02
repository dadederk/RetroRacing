# Achievements Rollout

App Store Connect rollout reference for the RetroRapid! achievement set. Runtime behavior lives in [../../Requirements/achievements.md](../../Requirements/achievements.md).

## Constraints

- Achievement IDs are immutable after creation.
- IDs must stay at or below 100 characters.
- Canonical IDs live in `AchievementIdentifier` / `AchievementCatalog`.
- Current set: 22 achievements, 700 of 1,000 Game Center points.

## Bundle IDs

| Target | Bundle ID |
|---|---|
| Universal | `com.accessibilityUpTo11.RetroRacing` |
| watchOS | `com.accessibilityUpTo11.RetroRacing.watchkitapp` |
| tvOS | `com.accessibilityUpTo11.RetroRacing-for-tvOS` |
| visionOS | `com.accessibilityUpTo11.RetroRacing-for-visionOS` |

Confirm each shipped app record has Game Center capability, matching achievements, and current provisioning profiles.

## Hidden Achievements

- Streak 600
- Streak 700
- Streak 800
- Overlander 200K
- GAAD Assistive Week

## Localization and Upload

- Machine-readable localized catalogs live beside this README:
  - `achievements-eu-localizations.json`
  - `leaderboards-eu-localizations.json`
- Validate and upload with:

```bash
./retrorapid asc game-center --check
./retrorapid asc game-center --dry-run
./retrorapid asc game-center
```

## Sandbox Validation

- Fresh account can unlock normal achievements and see replay sync after authentication.
- Offline/auth-delayed unlocks eventually report from the local snapshot.
- GAAD Assistive Week unlocks only during the local GAAD week window with qualifying assistive technology.
- watchOS GAAD qualification uses VoiceOver only in v1.
