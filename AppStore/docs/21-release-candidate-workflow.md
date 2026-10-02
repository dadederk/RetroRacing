# Release Candidate Workflow

Use this checklist for a new RetroRapid! marketing version. It links to the detailed [quality gate](03-submission-quality-gate.md), [local TestFlight runbook](14-testflight-helm-upload.md), [archive rules](15-archive-and-distribution.md), and [Xcode Cloud lane](17-xcode-cloud-releases.md). The [2.0 (36) record](../testflight/release-2.0-36.md) is an example of an incomplete candidate with explicit gates.

## 1. Choose the release source and toolchains

1. Read [the active release plan](../../Plans/INDEX.md), routed requirements, and shipping-platform table in [AGENTS.md](../../AGENTS.md). Select a source commit and marketing version. Reserve one new build number above the highest number already used on any shipping platform for this app; use it for the iOS archive, embedded Watch app, and macOS archive of this release candidate. Preserve existing working-tree changes.
2. Check `xcode-select -p` and `xcodebuild -version`, then verify the installed SDKs. Selecting Xcode in the system does not change the Xcode selected in Xcode Cloud. Check the intended workflow environment separately.
3. Read [Apple's current App Store Connect release notes](https://developer.apple.com/help/app-store-connect/release-notes/) before archiving. Record separately whether each Xcode/SDK pair is accepted for internal TestFlight, external TestFlight, and the public App Store. Helm's build `audience: app-store-eligible` is a TestFlight audience label; it does **not** override Apple's toolchain eligibility notice.
4. If a feature requires a beta SDK, make a TestFlight candidate with it. Plan a new shared build number from an App Store-accepted release or RC toolchain for public submission, and rebuild both shipping platform archives with that number even if one earlier beta archive is already eligible. iOS and macOS may need different Xcode installations; record each archive's provenance.

## 2. Prepare copy and draft versions

1. Create or inspect the iOS and macOS editable versions through Helm. Confirm the active AccessibilityUpTo11 account, app ID `6758641625`, each version ID, marketing version, and `MANUAL` release control before changing anything. Do not use `latest` for a build or version selection when two platforms or several candidates exist.
2. Update the canonical `AppStore/metadata/` candidate and all 20 `AppStore/testflight/beta-notes/<locale>/whats-new.txt` files. The App Store What's New and TestFlight What to Test are separate fields and separate writes. Keep platform-specific claims accurate on Mac and iOS.
3. Run `./retrorapid metadata generate`, `./retrorapid metadata apply --dry-run`, then `./retrorapid metadata apply`. The script validates and applies the catalog through Helm. Read back every affected App Store localization from both versions and compare the applied What's New with the catalog; a successful write alone is not a content audit.
4. Run `./retrorapid localization audit`, `./retrorapid check`, and the needed tests. Structural validation does not replace fluent approval of revised translations or a screenshot review.

## 3. Archive, upload, and test

1. Check `./retrorapid testflight --help` and use explicit `--version`, `--build-number`, `--developer-dir`, and `--helm` values. Its current defaults are historical (`1.5`, build `34`); `archive` and `all` process both iOS and macOS with the *same* selected Xcode. Use separate per-platform archive/export commands when eligibility differs. Do not reuse `build/testflight-<version>/` for a later build without preserving the earlier archive.
2. Verify the same marketing version and build number in both signed archives and the embedded Watch app, plus Mac architectures and signing and the expected SDK. Export/upload through Xcode or upload an exported `.ipa`/`.pkg` through Helm. Xcode archive success does not prove export or upload success: export needs a working team sign-in in **Xcode → Settings → Accounts**, independent of Helm authentication.
3. Poll `helm-asc apps 6758641625 builds --platform <iOS|macOS> --version <version> --number <build> --agent` until the correct processed build appears. Set export compliance as applicable, then apply **all** localized TestFlight notes to each build. Helm accepts a locale bundle under its `uploadsInbox`, or individual inline note updates. Inspect every response; Helm currently has no TestFlight note readback.
4. Discover the current beta group ID before attachment. `helm-asc build <id> attach --groups <id>` **automatically submits an eligible external build for beta review**. Pass `--no-submit` if only attaching; pass `--auto-notify false` when beta review is wanted but tester notifications should wait. Re-read the build state after attachment. The repository `testflight upload-*` commands attach the configured external group, so treat them as external beta submission paths.
5. Verify the user-visible features on devices or a working simulator, including platform-specific behavior, SharePlay across two devices, purchases, accessibility, and Mac controls. Capture any unresolved limitations in the candidate record.

## 4. Prepare the App Store handoff

1. Re-read both draft versions and the selected build IDs. Confirm the final iOS/Watch and macOS builds share the reserved build number, then attach **only App Store-eligible, accepted-toolchain builds** to their matching platform drafts. Keep `MANUAL` release control until the intended launch. A TestFlight build under beta review is not proof that App Review can accept it.
2. Check the [submission quality gate](03-submission-quality-gate.md): review contact and notes, export compliance, IAP, screenshots for current features, accessibility, privacy, locales, and platform availability. Do not imply public tvOS or visionOS gameplay from implemented targets.
3. For a major update, prepare the featuring nomination and a bounded [In-App Event](20-major-update-2-0-in-app-event.md) when its badge and schedule fit. Helm supports event metadata/assets and review submission; featuring nomination may require App Store Connect UI. Record nomination and event IDs, statuses, deep link, preview/start/end dates, and the relationship between the event date and likely app availability.
4. Submit each platform for App Review only after the chosen builds and manual checks are complete. App Review submission and public release are separate steps. Record submission IDs and preserve the manual release choice.

## Candidate record

Create `AppStore/testflight/release-<version>-<build>.md` with the shared build number, source commit, Xcode build and SDK per platform, archive paths, validation, exact build/version/group IDs, locale audit results, beta and App Review states, manual checks, and blockers. Update it after each external action so the next session can resume without guessing.
