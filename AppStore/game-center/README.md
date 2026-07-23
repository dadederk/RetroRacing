# Game Center localization (App Store Connect)

Canonical EU achievement copy: [`achievements-eu-localizations.json`](achievements-eu-localizations.json) (`de-DE`, `nl-NL`, `it`, `fr-FR`).

English/Spanish/Catalan payloads remain in [`Requirements/achievements_rollout_checklist.md`](../../Requirements/achievements_rollout_checklist.md).

## Helm CLI status

The installed `helm-asc` build exposes IAP/version localization upload, but **does not yet ship public `gameCenterAchievement` commands** in its help tree (API types exist internally; no `helm-asc gameCenterAchievement …` route today).

Until Helm adds Game Center achievement upload:

1. **App Store Connect UI** — Game Center → Achievements → each achievement → add localization per locale.
2. **`asc` CLI** (optional) — if you install [App Store Connect CLI](https://github.com/swerner/App-Store-Connect-CLI):
   ```bash
   asc game-center achievements list --app 6758641625
   asc game-center achievements localizations create \
     --achievement-id "ACHIEVEMENT_ID" \
     --locale de-DE \
     --name "Serie 100" \
     --before-earned-description "Überhole 100 Autos in einer Runde." \
     --after-earned-description "Du hast 100 Autos in einer Runde überholt."
   ```

## Repo helper

Print a per-achievement checklist from the JSON catalog:

```bash
swift run --package-path Scripts print-game-center-eu-localizations
```

When Helm adds Game Center achievement localization upload, wire it here the same way as IAP (`AppStore/iap-localizations/` + `swift run --package-path Scripts apply-iap-localizations`).
