# RetroRapid App Store Scripts

Swift-first operational tooling for the App Store metadata catalog.

## Recipe

1. Edit `AppStore/metadata/retrorapid-v1.5.json`.
2. Generate the human-readable copy and validation documents:

   ```bash
   swift run --package-path AppStore/scripts generate-metadata-docs
   ```

3. Verify the catalog and generated documents:

   ```bash
   swift run --package-path AppStore/scripts generate-metadata-docs --check
   swift test --package-path AppStore/scripts
   ```

4. Preview the App Store Connect update without changing anything:

   ```bash
   swift run --package-path AppStore/scripts apply-retrorapid-metadata --dry-run
   ```

5. Apply version-localized metadata only after reviewing the dry run:

   ```bash
   swift run --package-path AppStore/scripts apply-retrorapid-metadata
   ```

Optional flags:

- `--keywords-only` updates only hidden keywords.
- `--include-app-info` explicitly retries shared name/subtitle fields.
- `--helm <path>` overrides the Helm CLI path.

## Historical migration

The June 2026 Python monolith-splitting helper was removed after the migration. Recover it from git history only if the migration itself needs investigation.
