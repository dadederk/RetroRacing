# RetroRacing Scripts

Swift-first repository automation for RetroRapid. Run commands from any directory
inside the repository; each executable discovers the repository root before doing
work.

Engineering standards: [CONVENTIONS.md](CONVENTIONS.md).

## Commands

| Command | Purpose | Mutation safety |
|---|---|---|
| `run-tests` | Runs the shared and universal iOS unit-test targets | `--dry-run` prints the resolved commands; `--destination <value>` overrides the simulator; `--only-testing <filter>` runs a specific test class or method |
| `check-documentation` | Validates markdown links and App Store metadata sync | Exits non-zero on errors |
| `generate-road-dash-masks` | Renders the lane and lap-strip mask assets | `--check` compares every generated PNG and `Contents.json` without writing |
| `sync-screenshot-studio-localizations` | Synchronizes Screenshot Studio copy, manifests, and shared locale images | `--check` reports plist, manifest, and image drift without writing |
| `generate-metadata-docs` | Generates metadata copy and validation documents from the canonical JSON catalog | `--check` verifies generated documents without writing |
| `apply-retrorapid-metadata` | Applies validated metadata through Helm | `--dry-run` reports the plan without changing App Store Connect |
| `apply-iap-localizations` | Uploads EU Unlimited Plays IAP localizations through Helm | `--dry-run` plans the upload without changing App Store Connect |
| `print-game-center-eu-localizations` | Prints EU Game Center achievement copy for manual ASC entry | Read-only |
| `submit-testflight-build` | Archives iOS/macOS builds and configures TestFlight via Helm | `--dry-run` prints archive, upload, lookup, and TestFlight configuration commands |

## Recommended Recipes

Run the complete script test suite:

```bash
swift test --package-path Scripts
```

Verify generated repository content:

```bash
swift run --package-path Scripts generate-road-dash-masks --check
swift run --package-path Scripts sync-screenshot-studio-localizations --check
swift run --package-path Scripts generate-metadata-docs --check
swift run --package-path Scripts check-documentation
```

Preview and run app tests:

```bash
swift run --package-path Scripts run-tests --dry-run
swift run --package-path Scripts run-tests
```

Run debug simulation isolation checks before App Store submission:

```bash
swift run --package-path Scripts run-tests \
  --only-testing RetroRacingSharedTests/DebugSimulationProductionIsolationTests
```

Edit and apply App Store metadata:

```bash
swift run --package-path Scripts generate-metadata-docs
swift run --package-path Scripts apply-retrorapid-metadata --dry-run
swift run --package-path Scripts apply-retrorapid-metadata
```

Optional metadata flags:

- `--keywords-only` updates only hidden keywords.
- `--include-app-info` explicitly retries shared name/subtitle fields.
- `--helm <path>` overrides the Helm CLI path.

Upload EU Unlimited Plays IAP localizations:

```bash
swift run --package-path Scripts apply-iap-localizations --dry-run
swift run --package-path Scripts apply-iap-localizations
```

Print EU Game Center achievement copy for manual App Store Connect entry:

```bash
swift run --package-path Scripts print-game-center-eu-localizations
```

Upload the current TestFlight build:

```bash
swift run --package-path Scripts submit-testflight-build --help
swift run --package-path Scripts submit-testflight-build all --dry-run
swift run --package-path Scripts submit-testflight-build all
```

Optional TestFlight flags include `--version`, `--build-number`, `--helm`,
`--developer-dir`, `--external-group`, `--poll-attempts`, and `--poll-interval`.

## Historical Migrations

The June 2026 Python metadata migration helper was removed after the migration.
Recover it from git history only if the migration itself needs investigation.
