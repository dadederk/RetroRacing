# RetroRacing Scripts

Swift-first repository automation for RetroRapid. Run commands from any directory
inside the repository; each executable discovers the repository root before doing
work.

Engineering standards: [CONVENTIONS.md](CONVENTIONS.md).

## Developer CLI

Preferred entry point from the repository root (matches Xarra’s `./xarraCli`):

```bash
./retroRapidCli --help
./retroRapidCli list
./retroRapidCli check
./retroRapidCli test package
./retroRapidCli test parallel-canary --dry-run
```

`./retroRapidCli` and `./retrorapid` are equivalent. Both forward to `swift run --package-path Scripts retrorapid`. With **no arguments** on an interactive terminal they open a numbered menu; use `--help` for static reference.

## Commands

| Command | Purpose | Mutation safety |
|---|---|---|
| `run-tests` | Runs the shared and universal iOS unit-test targets | `--dry-run` prints the resolved commands; `--destination <value>` overrides the simulator; `--only-testing <filter>` runs a specific test class or method |
| `run-xcodebuild-parallel-canary` | Runs shared and universal unit tests with parallel xcodebuild workers as a canary | `--dry-run`; `--workers <n[,n]>`; `--destination <value>` |
| `check-documentation` | Validates markdown links and App Store metadata sync | Exits non-zero on errors |
| `generate-road-dash-masks` | Renders the lane and lap-strip mask assets | `--check` compares every generated PNG and `Contents.json` without writing |
| `sync-screenshot-studio-localizations` | Synchronizes Screenshot Studio copy, manifests, and shared locale images | `--check` reports plist, manifest, and image drift without writing |
| `capture-app-store-screenshots` | Captures localized iPhone, iPad, Mac, or Apple Watch screenshots via UI tests, stages them, installs each capture into Screenshot Studio as it completes, then syncs manifests | `--platform iphone|ipad|mac|watch` (default `iphone`); `--all-platforms` runs iphone → ipad → mac → watch sequentially (incompatible with `--platform`, `--destination`, and `--staging-dir`). iPad resolves the newest available `iPad Pro 13-inch` simulator (prefers M5 on the latest iOS runtime, falls back to M4); Mac uses landscape window capture to PNG; Watch uses Ultra 3 and five slides. All platforms default to eleven Screenshot Studio locales: UI tests capture seven source locales and duplicate derived variants (`en-GB`/`en-AU`/`en-CA` from `en-US`, `es-MX` from `es-ES`). `--install-only` moves an existing staging dir; `--staging-dir`, `--locales`, `--slides`, `--destination`, `--retries`, `--force`, `--appearance light|dark` (default `light`), `--no-status-bar-override`, `--status-bar-override`, `--dry-run`, and `--check` filter or validate runs. Re-runs skip staged files and only capture missing ones; `--force` recaptures every requested target even when staging already has files. iPhone/iPad apply marketing status bar `9:41` via `simctl` by default; Watch leaves the clock alone by default (pass `--status-bar-override` only if you intentionally want the disruptive host-clock marketing time). |
| `generate-metadata-docs` | Generates metadata copy and validation documents from the canonical JSON catalog | `--check` verifies generated documents without writing |
| `apply-retrorapid-metadata` | Applies validated metadata through Helm | `--dry-run` reports the plan without changing App Store Connect |
| `apply-iap-localizations` | Uploads EU Unlimited Plays IAP localizations through Helm, with App Store Connect API fallback | `--check` validates CSV bundles without ASC calls; `--dry-run` plans without writes; `--asc-api` skips Helm file upload |
| `apply-game-center-eu-localizations` | Uploads EU Game Center achievement and leaderboard localizations via App Store Connect API | `--check` validates catalogs without ASC calls; `--dry-run`; `--achievements-only`; `--leaderboards-only` |
| `print-game-center-eu-localizations` | Prints EU Game Center achievement copy for manual ASC entry | Read-only |
| `submit-testflight-build` | Archives iOS/macOS builds and configures TestFlight via Helm | `--dry-run` prints archive, upload, lookup, and TestFlight configuration commands |
| `swap-app-store-screenshots` | Swaps two screenshot positions in App Store Connect through Helm | `--check` verifies both positions exist without uploading; `--dry-run` plans the Helm upload; `--platform iphone|ipad|mac|watch` limits device sets |

## Recommended Recipes

Run the complete script test suite:

```bash
./retrorapid test package
```

Verify generated repository content:

```bash
./retrorapid check
```

Preview and run app tests:

```bash
./retrorapid test --dry-run
./retrorapid test
./retrorapid test parallel-canary --workers 2,4
```

Capture localized App Store screenshots (iPhone, 7 slides × 11 locales):

```bash
./retrorapid screenshots capture --dry-run
./retrorapid screenshots capture --locales de-DE,fr-FR --slides 2,3
./retrorapid screenshots capture --platform ipad --slides 2,5
./retrorapid screenshots capture --platform mac --slides 1,4
./retrorapid screenshots capture --platform watch --slides 0,1,4
./retrorapid screenshots capture --all-platforms --force
./retrorapid screenshots capture --appearance dark --platform iphone --slides 2 --force
./retrorapid screenshots capture --retries 3
./retrorapid run capture-app-store-screenshots --install-only --staging-dir .build/screenshot-capture/iphone
```

Run debug simulation isolation checks before App Store submission:

```bash
swift run --package-path Scripts run-tests \
  --only-testing RetroRacingSharedTests/DebugSimulationProductionIsolationTests
```

Edit and apply App Store metadata:

```bash
./retrorapid metadata generate
./retrorapid metadata apply --dry-run
./retrorapid metadata apply
```

Optional metadata flags:

- `--keywords-only` updates only hidden keywords.
- `--include-app-info` explicitly retries shared name/subtitle fields.
- `--helm <path>` overrides the Helm CLI path.

Upload EU Unlimited Plays IAP localizations:

```bash
./retrorapid asc iap --dry-run
./retrorapid asc iap
./retrorapid asc iap --asc-api
```

When Helm cannot read repo files or write into its Group Containers folder, use App Store Connect API credentials instead:

```bash
export ASC_KEY_ID=...
export ASC_ISSUER_ID=...
export ASC_PRIVATE_KEY=~/path/to/AuthKey_XXXX.p8
./retrorapid asc iap --asc-api
```

Upload EU Game Center achievement and leaderboard localizations:

```bash
./retrorapid asc game-center --dry-run
./retrorapid asc game-center
./retrorapid asc game-center --leaderboards-only
```

Swap screenshot positions in App Store Connect (run from Terminal.app — Helm artifact folders are not writable from Cursor's agent shell):

```bash
./retrorapid asc screenshots swap --first 3 --second 4 --check
./retrorapid asc screenshots swap --first 3 --second 4 --dry-run
./retrorapid asc screenshots swap --first 3 --second 4
./retrorapid asc screenshots swap --first 2 --second 5 --platform ipad --locale en-US --locale de-DE
```

Optional screenshot-swap flags include `--version-id`, `--app-id`, `--version`, `--asc-platform`, `--platform`, `--locale`, and `--helm`.

Print EU Game Center achievement copy for manual App Store Connect entry:

```bash
./retrorapid asc game-center print
```

Upload the current TestFlight build:

```bash
./retrorapid testflight --help
./retrorapid testflight all --dry-run
./retrorapid testflight all
```

Optional TestFlight flags include `--version`, `--build-number`, `--helm`,
`--developer-dir`, `--external-group`, `--poll-attempts`, and `--poll-interval`.

## Direct invocation (advanced)

Every command remains available without the wrapper:

```bash
swift run --package-path Scripts <executable> [flags…]
swift test --package-path Scripts
```

## Historical Migrations

The June 2026 Python metadata migration helper was removed after the migration.
Recover it from git history only if the migration itself needs investigation.
