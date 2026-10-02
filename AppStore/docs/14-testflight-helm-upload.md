# Local TestFlight Uploads With Helm CLI

Use this for local iOS with embedded Watch and macOS archives. Start with the [release candidate workflow](21-release-candidate-workflow.md) for version, SDK eligibility, metadata, acceptance, and App Store handoff. Xcode Cloud builds enter this runbook after processing; see [17-xcode-cloud-releases.md](17-xcode-cloud-releases.md).

## Preflight

- Confirm the intended app and Helm account: `helm-asc auth list --agent`, then `helm-asc apps 6758641625 testFlightGroups --agent`. The team is `PV9S9FTZF2`; resolve group IDs anew rather than relying on an old copy.
- Resolve the installed Helm path with `command -v helm-asc`. The current machine uses `/opt/homebrew/bin/helm-asc`; older installs may use the Helm app helper. Pass `--agent` for machine-readable results.
- Check `xcode-select -p`, `xcodebuild -version`, and [Apple's current App Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/). A beta Xcode can be accepted for TestFlight before it is accepted for public App Store submission. Verify the notice for the specific platform and SDK.
- Confirm project marketing/build numbers before archiving. The upload helper's `--version` and `--build-number` filter App Store Connect lookups; they **do not** update the Xcode project.
- Keep `AppStore/testflight/beta-notes/<locale>/whats-new.txt` complete for every supported locale. These are TestFlight What to Test notes, separate from the App Store What's New in the metadata catalog.

## Automation and its limits

```bash
./retrorapid testflight --help
./retrorapid testflight all --version <version> --build-number <build> --developer-dir <Xcode.app/Contents/Developer> --helm <helm-asc-path> --dry-run
```

- Always pass version and build number explicitly. The helper currently defaults to historical `1.5` (34).
- `archive` and `all` archive **both** platforms using one `--developer-dir`. Use separate Xcode commands when iOS and Mac require different eligible toolchains.
- `upload-ios`, `upload-mac`, and `all` export/upload, poll for the build, set no non-exempt encryption, apply the locale note files, and attach the configured **external** TestFlight group. Helm's `attach` auto-submits an eligible external build for beta review. Use these helper commands only when that external step is intended.
- Archives live at `build/testflight-<version>/RetroRacingUniversal-{iOS,macOS}.xcarchive`. The path omits build number. Preserve the existing archive before making another build for the same marketing version.
- The export options are in `AppStore/testflight/ExportOptions-upload.plist`. Xcode export/upload requires valid team credentials in **Xcode → Settings → Accounts** even when archive/signing succeeded and Helm is authenticated. `Failed to Use Accounts` / missing `Xcode-Username` is an Xcode account gate; refresh that team sign-in, then retry the export. Helm credentials do not repair Xcode's keychain entry.

## Controlled per-platform sequence

1. Archive iOS and macOS with their verified Xcode installations, using the Release scheme and generic device destinations described in [archive and distribution](15-archive-and-distribution.md). Check the archive Info.plist, code signature, embedded Watch, and SDK before upload. Keep the path and Xcode build in the candidate record.
2. Export/upload each archive with the Xcode installation intended for that platform. Example for an archive that already exists:

```bash
DEVELOPER_DIR=<Xcode.app/Contents/Developer> xcrun xcodebuild -exportArchive \
  -archivePath <absolute-path-to-platform.xcarchive> \
  -exportOptionsPlist <absolute-path-to-AppStore/testflight/ExportOptions-upload.plist> \
  -allowProvisioningUpdates
```

3. Look up the processed build by exact platform, version, and number. Use the returned build ID for every later command:

```bash
helm-asc apps 6758641625 builds --platform iOS --version <version> --number <build> --agent
helm-asc apps 6758641625 builds --platform macOS --version <version> --number <build> --agent
```

4. Set export compliance only after confirming the app's encryption declaration. For the current build, no non-exempt encryption is used:

```bash
helm-asc build <build-id> update --uses-non-exempt-encryption false --agent
```

5. Apply all TestFlight note files. `helm-asc build <id> update --path <directory> --dry-run --agent` accepts `<directory>/<locale>/whats-new.txt`; then rerun without `--dry-run`. If Helm cannot read the repository path, run `helm-asc paths --agent`, stage the locale folders under its `uploadsInbox`, and pass the staged absolute path. Individual `--locale <locale> --whats-new <text>` updates also work. Check every update response: the Helm CLI currently provides no note readback.
6. Attach the intended group. **Default `attach` auto-submits eligible external builds for beta review.** Decide whether to submit and notify before this command:

```bash
helm-asc build <build-id> attach --groups <external-group-id> --no-submit --agent
helm-asc build <build-id> attach --groups <external-group-id> --auto-notify false --agent
```

Use the first form for attachment only, or the second when external beta review is authorized and testers should not receive automatic approval notifications. If already attached with `--no-submit`, use `helm-asc build <id> submit-for-review --auto-notify false --agent`. Re-list the build and record `WAITING_FOR_BETA_REVIEW`, `IN_BETA_TESTING`, or the actual state. An Internal Testing group can reject attachment with a 422; do not assume it is interchangeable with an external group.

## Alternate Helm file upload

`helm-asc apps <app-id> builds upload --file <ipa-or-pkg> --platform <platform> --version <version> --number <build>` accepts exported `.ipa` and `.pkg` files. First run `helm-asc paths --agent` and stage agent-created artifacts under the reported `uploadsInbox`. Use `--wait-for-processing` when later steps need the processed build ID. Do not infer file access from shell access; `FILE_ACCESS` means Helm's sandbox cannot read the path. `cd` does not grant access.

## Error handling

| Result | Action |
|---|---|
| `PRO_REQUIRED` | Restore Helm Pro; do not switch accounts as a workaround. |
| `FILE_ACCESS` | Stage under Helm's `uploadsInbox`, upload through Xcode, or grant Helm file access. |
| Xcode `Failed to Use Accounts` / missing `Xcode-Username` | Refresh Xcode's team sign-in; the signed archive may still be valid. |
| `MISSING_EXPORT_COMPLIANCE` | Set the correct encryption answer on the processed build. |
| `partial_failure` | Record successful locale/group IDs and retry only failed items. |
| Build not found after upload | Confirm exact platform/version/number and processing state before retrying the upload; avoid duplicate submissions. |
