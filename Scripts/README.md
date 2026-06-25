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

## Historical Migrations

The June 2026 Python metadata migration helper was removed after the migration.
Recover it from git history only if the migration itself needs investigation.
