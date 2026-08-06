# Game Center localization (App Store Connect)

**Add-language checklist:** [`../docs/08-locale-expansion.md`](../docs/08-locale-expansion.md)

## Catalogs

| File | Coverage |
|---|---|
| [`achievements-eu-localizations.json`](achievements-eu-localizations.json) | 22 achievements × 10 locales |
| [`leaderboards-eu-localizations.json`](leaderboards-eu-localizations.json) | 15 boards (iPhone/iPad/Mac/Apple TV/Watch × Cruise/Fast/Rapid) × 10 locales |
| [achievements-rollout.md](achievements-rollout.md) | ASC achievement rollout constraints and sandbox checks |

Locales: `de-DE`, `nl-NL`, `it`, `fr-FR`, `es-ES`, `ca`, `ja`, `ko`, `pt-BR`, `zh-Hant`. **No** `en-GB`/`en-AU`/`en-CA` — ASC falls back to `en-US`.

Runtime achievement behavior: [`Requirements/achievements.md`](../../Requirements/achievements.md).

## Apply

Credentials: Keychain `RetroRapid ASC *` or `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_PRIVATE_KEY`. **No Helm Game Center commands** — ASC API only.

```bash
./retrorapid asc game-center --check
./retrorapid asc game-center --dry-run
./retrorapid asc game-center
./retrorapid asc game-center --leaderboards-only --ensure-leaderboards --dry-run
./retrorapid asc game-center --leaderboards-only --ensure-leaderboards
```

Flags: `--achievements-only`, `--leaderboards-only`, and `--ensure-leaderboards` (leaderboards only). After text upsert, copies **en-US** artwork into locales missing images.

The three Apple TV entries inherit localization copy and leaderboard configuration from their matching iPhone template entries. `--ensure-leaderboards` scopes processing to template-backed entries, creates missing boards, checks existing boards for configuration drift, ensures an en-US localization, and creates missing live releases. It does not patch the existing iPhone, iPad, Mac, or Apple Watch boards. The workflow does not synthesize Apple TV artwork; add an en-US source image before expecting image propagation to other locales.

## Leaderboard display names

Built at upload time (JSON `name` is a placeholder). Score suffixes in the catalog are authoritative.

- Platform prefix from en-US ASC row; **30-character** cap (shortens “High Score” / `Apple Watch` → `Watch` when needed).
- Translate “High Score”; keep `Cruise`/`Rapid`; localize `Fast` like Settings (`Rápido`, `Ràpid`, …).
- Descriptions: overtakes in one run (locale defaults in `GameCenterLeaderboardDescriptionBuilder`).

## Artwork naming (en-US source only)

| Kind | Pattern |
|---|---|
| Leaderboards | `Leaderboard{Iphone\|Ipad\|Mac\|AppleTV\|AppleWatch}{Cruise\|Fast\|Rapid}.png` (1024×1024) |
| Achievements | `Achievement{ReferenceName}.png` (e.g. `AchievementRunOvertakes100.png`) |
