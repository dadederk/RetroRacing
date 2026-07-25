# Game Center localization (App Store Connect)

Canonical EU catalogs:

- Achievements: [`achievements-eu-localizations.json`](achievements-eu-localizations.json) (`de-DE`, `nl-NL`, `it`, `fr-FR`)
- Leaderboards: [`leaderboards-eu-localizations.json`](leaderboards-eu-localizations.json) (12 shipping-platform boards × 4 locales)

English/Spanish/Catalan achievement payloads remain in [`Requirements/achievements_rollout_checklist.md`](../../Requirements/achievements_rollout_checklist.md).

## Upload via App Store Connect API

Requires the same credentials as IAP upload (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`).

```bash
./retrorapid asc game-center --dry-run
./retrorapid asc game-center
./retrorapid asc game-center --check
```

Flags:

- `--achievements-only` — 22 achievements × 4 locales (88 rows)
- `--leaderboards-only` — 12 leaderboards × 4 locales (48 rows)
- `--dry-run` — plan without writes

After text upload, the command copies **en-US achievement images** to each EU locale that is missing an image (same artwork, no text). Leaderboard images copy when an en-US source image exists.

## Image naming (en-US source files)

Upload artwork to the **en-US** localization row in App Store Connect. Filenames are for your reference only (ASC stores its own copy); keep them consistent so re-uploads and debugging are easy.

**Leaderboards** — `Leaderboard{Platform}{Level}.png` (1024×1024):

| Platform | Cruise | Fast | Rapid |
|---|---|---|---|
| iPhone | `LeaderboardIphoneCruise.png` | `LeaderboardIphoneFast.png` | `LeaderboardIphoneRapid.png` |
| iPad | `LeaderboardIpadCruise.png` | `LeaderboardIpadFast.png` | `LeaderboardIpadRapid.png` |
| macOS | `LeaderboardMacCruise.png` | `LeaderboardMacFast.png` | `LeaderboardMacRapid.png` |
| watchOS | `LeaderboardAppleWatchCruise.png` | `LeaderboardAppleWatchFast.png` | `LeaderboardAppleWatchRapid.png` |

**Achievements** — `Achievement{ReferenceName}.png` (matches ASC reference name, e.g. `AchievementRunOvertakes100.png` for `runOvertakes100`).

The upload script reads en-US images via the App Store Connect API and duplicates them into EU locales; you do **not** need separate artwork per translated language.

**Important:** `--dry-run` prints the plan only. Leaderboard rows show `[dry-run] CREATE` until you run without `--dry-run`:

```bash
swift run --package-path Scripts apply-game-center-eu-localizations --leaderboards-only
```

Print a manual checklist:

## Helm CLI status

The installed `helm-asc` build exposes IAP/version localization upload, but **does not yet ship public `gameCenterAchievement` commands**. Use the ASC API command above instead of Helm file upload for EU Game Center metadata.

## Leaderboard scope

Leaderboard catalog covers shipping platforms only (`iPhone`, `iPad`, `macOS`, `watchOS`). **Display names** are built at upload time:

- **Platform prefix** matches the existing en-US row in App Store Connect (e.g. `iPhone`, `Mac`, `Apple Watch`). ASC caps display names at **30 characters**; longer EU strings shorten automatically (`Miglior punteggio` → `Top score`, `Apple Watch` → `Watch` when needed).
- **“High Score”** is translated per EU locale (`Bestpunktzahl`, `Highscore`, `Miglior punteggio`, `Meilleur score`).
- **Speed levels** follow in-app naming: `Cruise` and `Rapid` stay as product terms; `Fast` uses the same localized labels as Settings (`Schnell`, `Snel`, `Veloce`, `Rapide`).
- **Descriptions** explain ranking in one run (overtakes); built at upload time from the en-US ASC row when present, otherwise EU defaults.

Example: `iPhone Bestpunktzahl - Cruise` (de-DE), `iPhone Meilleur score - Rapide` (fr-FR, Fast board).

The JSON `name` fields are legacy placeholders; score suffixes in the catalog remain authoritative. tvOS boards are omitted from the EU catalog because tvOS is not publicly listed.
