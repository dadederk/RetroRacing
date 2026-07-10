# TestFlight Uploads With Helm CLI

Agent playbook for RetroRapid! TestFlight uploads.

## Rules

- Use Xcode 26 for TestFlight/App Store archives until iOS 27 ships in September 2026. Do not submit archives built with Xcode 27 beta.
- Resolve `helm-asc` once per session; examples use `/Applications/Helm.app/Contents/Helpers/helm-asc`.
- Prefer the Swift script. It uploads with Xcode, then uses Helm for App Store Connect build metadata, groups, and beta review.
- Pass `--agent` to Helm commands. Avoid `jq`, pipelines, and command substitution in agent flows.
- Discover with app-scoped commands first; mutate with `build <build-id>` only after the ID is known.

## App Values

| Field | Value |
|---|---|
| ASC app ID | `6758641625` |
| Platforms | `iOS` with watchOS, `macOS` |
| External group | `df40f833-12c7-4411-b28d-122690045c58` |
| Internal group | `47135367-a693-4b8f-ba0b-01ed017148a2` |
| Export options | `AppStore/testflight/ExportOptions-upload.plist` |
| What to Test | `AppStore/testflight/beta-notes/en-US/whats-new.txt` |

Refresh group IDs before attach/submit:

```bash
/Applications/Helm.app/Contents/Helpers/helm-asc apps 6758641625 testFlightGroups --agent
```

## What To Test Copy

- Write one coherent copy block per marketing version, such as `1.6`, `1.7`, `1.8`.
- Match the release-note voice in `docs/07-release-notes-voice.md`: energetic, specific, grateful, and player-focused.
- Cover user-visible changes since the last submitted build; skip internal tooling unless testers need to verify it.
- When submitting another build number for the same version, compound the notes: keep still-relevant earlier changes and add the new changes so the copy remains useful as one read.

## Script

From the repo root:

```bash
swift run --package-path Scripts submit-testflight-build all
```

Useful variants:

```bash
swift run --package-path Scripts submit-testflight-build archive
swift run --package-path Scripts submit-testflight-build upload-ios
swift run --package-path Scripts submit-testflight-build upload-mac
```

Pass `--version` and `--build-number` before reusing it for later releases.

## Manual Sequence

1. Confirm Helm auth:

```bash
/Applications/Helm.app/Contents/Helpers/helm-asc auth list
```

2. Export/upload each archive with Xcode 26:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun xcodebuild -exportArchive \
  -archivePath /absolute/path/to/RetroRacingUniversal-iOS.xcarchive \
  -exportOptionsPlist /absolute/path/to/AppStore/testflight/ExportOptions-upload.plist \
  -allowProvisioningUpdates
```

3. Poll for each processed build:

```bash
/Applications/Helm.app/Contents/Helpers/helm-asc apps 6758641625 builds \
  --platform <iOS|macOS> \
  --version <marketing-version> \
  --number <build-number> \
  --agent
```

4. Configure, attach, and submit when requested:

```bash
/Applications/Helm.app/Contents/Helpers/helm-asc build <build-id> update \
  --uses-non-exempt-encryption false \
  --locale en-US \
  --whats-new "Paste the version's cumulative What to Test copy" \
  --agent
```

```bash
/Applications/Helm.app/Contents/Helpers/helm-asc build <build-id> attach \
  --groups df40f833-12c7-4411-b28d-122690045c58 \
  --agent
```

```bash
/Applications/Helm.app/Contents/Helpers/helm-asc build <build-id> submit-for-review --agent
```

Use `--uses-non-exempt-encryption false` to mark no non-exempt encryption. Do not submit for beta review unless the user asked for it.

## Direct Helm Uploads

Use `apps <app-id> builds upload --file ...` only when Helm can read the artifact. For agent-created files:

```bash
/Applications/Helm.app/Contents/Helpers/helm-asc paths --agent
```

Stage files under the returned `uploadsInbox`, pass absolute paths, and retry once. If Helm returns `FILE_ACCESS`, do not `cd`; switch to Xcode upload or ask the user to grant Helm access.

## Stop Conditions

- `PRO_REQUIRED`: stop; Helm Pro is required.
- `FILE_ACCESS`: stage under `uploadsInbox`, use Xcode upload, or ask for a one-time Helm grant.
- `MISSING_EXPORT_COMPLIANCE`: run `build <id> update --uses-non-exempt-encryption false`.
- `partial_failure`: keep successful IDs and retry only failed groups/locales/items.
- `helm-asc build <id> ...` exit `134`: uploaded builds may still list, but update/attach/submit needs Helm CLI repair/update.
