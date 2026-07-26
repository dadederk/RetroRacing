# Game Center localization (App Store Connect)

**Add-language checklist:** [`../docs/08-locale-expansion.md`](../docs/08-locale-expansion.md)

## Catalogs

| File | Coverage |
|---|---|
| [`achievements-eu-localizations.json`](achievements-eu-localizations.json) | 22 achievements × 10 locales |
| [`leaderboards-eu-localizations.json`](leaderboards-eu-localizations.json) | 12 boards (iPhone/iPad/Mac/Watch × Cruise/Fast/Rapid) × 10 locales |

Locales: `de-DE`, `nl-NL`, `it`, `fr-FR`, `es-ES`, `ca`, `ja`, `ko`, `pt-BR`, `zh-Hant`. **No** `en-GB`/`en-AU`/`en-CA` — ASC falls back to `en-US`.

English reference tables: [`Requirements/achievements_rollout_checklist.md`](../../Requirements/achievements_rollout_checklist.md).

## Apply

Credentials: Keychain `RetroRapid ASC *` or `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_PRIVATE_KEY`. **No Helm Game Center commands** — ASC API only.

```bash
./retrorapid asc game-center --check
./retrorapid asc game-center --dry-run
./retrorapid asc game-center
```

Flags: `--achievements-only`, `--leaderboards-only`. After text upsert, copies **en-US** artwork into locales missing images.

## Leaderboard display names

Built at upload time (JSON `name` is a placeholder). Score suffixes in the catalog are authoritative.

- Platform prefix from en-US ASC row; **30-character** cap (shortens “High Score” / `Apple Watch` → `Watch` when needed).
- Translate “High Score”; keep `Cruise`/`Rapid`; localize `Fast` like Settings (`Rápido`, `Ràpid`, …).
- Descriptions: overtakes in one run (locale defaults in `GameCenterLeaderboardDescriptionBuilder`).

## Artwork naming (en-US source only)

| Kind | Pattern |
|---|---|
| Leaderboards | `Leaderboard{Iphone\|Ipad\|Mac\|AppleWatch}{Cruise\|Fast\|Rapid}.png` (1024×1024) |
| Achievements | `Achievement{ReferenceName}.png` (e.g. `AchievementRunOvertakes100.png`) |
