# Xcode Cloud Releases

Agent playbook for validating and archiving RetroRapid! with Xcode Cloud. Local TestFlight upload remains available in [14-testflight-helm-upload.md](14-testflight-helm-upload.md), but Xcode Cloud is the preferred release path once the workflows are configured.

## Rules

- Xcode Cloud workflows are configured in Xcode's Report navigator (Cloud tab) or App Store Connect's Xcode Cloud tab, not in committed project files. Repo-side `ci_scripts/` is only for custom shell scripts, and no custom script is currently required for the release lane.
- Use an Xcode 26 release environment. Prefer the explicit latest Xcode 26 option when Xcode Cloud offers one; otherwise use **Latest Release** only while Apple's latest public release is still Xcode 26. Do not use **Latest**, because it can include beta toolchains.
- The release workflow archives only public shipping payloads: iOS/iPadOS with the embedded watchOS app, and macOS. Do not add tvOS or visionOS archive actions until their public status changes.
- Build numbers (`CURRENT_PROJECT_VERSION`) should be managed by Xcode Cloud for the release workflow once enabled. Before the first real run, set Xcode Cloud's **Next Build Number** above the current maximum uploaded build across iOS and macOS.
- Release workflow post-actions distribute only to **TestFlight Internal Testing**. External TestFlight group attachment, beta review submission, App Store version attachment, App Store review submission, phased release, and manual release stay deliberate human or Helm steps.
- A successful internal TestFlight upload should be valid to promote: Release configuration, App Store distribution signing, no non-exempt encryption, current metadata/review notes, and both iOS and macOS build records available in App Store Connect.

## Workflows

Use two workflows: one gate for merge confidence, one lane for distributable archives.

### Master Merge Gate

This workflow exists so changes are tested before they merge into `master`, and so the post-merge `master` commit is verified too.

| Setting | Value |
|---|---|
| Start conditions | Pull Request Changes targeting `master`; Branch Changes on `master` |
| Required status | Require this workflow, or its Test action, in GitHub branch protection for `master` |
| Xcode version | Xcode 26 release environment |
| Auto-cancel | Enabled for pull requests; optional for `master` branch changes |

| Action | Scheme | Platform / Destination | Notes |
|---|---|---|---|
| `Test - iOS Unit` | `RetroRacingUniversal` | iOS 26 Simulator | Runs shared and universal unit tests from the shared scheme. Pin an explicit iOS 26 runtime instead of selecting by simulator name only. |
| `Test - watchOS Unit` | `RetroRacingWatchOS` | watchOS 26 Simulator | Catches watch-only regressions outside the embedded iOS archive path. Pin an explicit watchOS 26 runtime. |

Keep screenshot UI capture out of this workflow. Regular UI screenshot tests skip unless `RETRORAPID_SCREENSHOT_CAPTURE=1`, and release screenshot capture remains manual through [06-screenshots.md](06-screenshots.md).

### Release

This workflow produces the TestFlight builds that can later be promoted.

| Setting | Value |
|---|---|
| Start condition | Manual |
| Xcode version | Xcode 26 release environment |
| Manage build number | Enabled |
| Environment | Clean build preferred for distribution post-actions |

| Action | Scheme | Platform | Distribution Preparation |
|---|---|---|---|
| `Archive - iOS + watchOS` | `RetroRacingUniversal` | iOS | TestFlight (Internal Testing) Only |
| `Archive - macOS` | `RetroRacingUniversal` | macOS | TestFlight (Internal Testing) Only |

Post-actions are workflow-level entries. Add one `TestFlight Internal Testing` post-action for each archive artifact.

| Post-action | Artifact | Groups |
|---|---|---|
| `TestFlight Internal Testing` (iOS) | `Archive - iOS + watchOS` | Internal Testing |
| `TestFlight Internal Testing` (macOS) | `Archive - macOS` | Internal Testing |

## Release Sequence

1. Confirm local validation is green before starting the cloud release:

```bash
./retrorapid test package
./retrorapid check
./retrorapid test
```

When local machines have multiple simulator runtimes with the same device names, pin the destination to an iOS 26 simulator instead of relying on name matching.

2. Bump `MARKETING_VERSION` if this is a new marketing version. Once Xcode Cloud manages build numbers, do not bump `CURRENT_PROJECT_VERSION` for release numbering.
3. Confirm the next Xcode Cloud build number is above the current maximum uploaded build:

```bash
/Applications/Helm.app/Contents/Helpers/helm-asc apps 6758641625 builds --agent
```

4. Start the **Release** workflow once from Xcode or App Store Connect.
5. Wait for both archive actions and both internal TestFlight post-actions to complete.
6. Poll for processed builds and set export compliance/What to Test copy through Helm, continuing from step 3 of [14-testflight-helm-upload.md](14-testflight-helm-upload.md).
7. Attach the internal group automatically through the Xcode Cloud post-action result. Attach external groups and submit for beta review only when ready to invite external testers.
8. After internal/external feedback is good, attach the selected iOS and macOS builds to the App Store version, complete review notes and metadata checks, then submit for App Store review manually or through a dedicated Helm/App Store Connect API step.

## One-Time Setup

1. Open `RetroRacing/RetroRacing.xcodeproj` in Xcode 26.
2. Product -> Xcode Cloud -> Create Workflow..., sign in with an account that has Admin or App Manager access for RetroRapid! in App Store Connect.
3. Authorize the Xcode Cloud GitHub App for the RetroRacing repository when prompted. This is interactive and must be done by a human.
4. Create the **Master Merge Gate** workflow with the start conditions and Test actions above.
5. Configure GitHub branch protection for `master` so the Master Merge Gate must pass before merging.
6. Create the **Release** workflow manually. Delete any default Build action if Xcode proposes one; distributable uploads require Archive actions.
7. Add the two Archive actions and two TestFlight Internal Testing post-actions listed above.
8. Enable managed build numbers and set the next number above the highest uploaded iOS/macOS build.

## Stop Conditions

- GitHub App authorization appears: stop and hand off; agents cannot complete it non-interactively.
- Xcode Cloud offers only beta Xcode versions for the workflow: stop rather than producing a release build with a beta SDK.
- A merge reaches `master` without the Master Merge Gate passing: treat branch protection as incomplete and fix setup before relying on the lane.
- A Release action is type Build instead of Archive: replace it. Build actions do not produce distributable TestFlight artifacts.
- TestFlight post-action has no artifact: verify the post-action's Artifact picker targets the matching Archive action.
- `ITMS-90061` or duplicate/higher build number errors: fix Xcode Cloud's Next Build Number; do not patch `CURRENT_PROJECT_VERSION` to chase cloud-managed numbering.
- iOS archive lacks `Watch/RetroRacingWatchOS.app`: fix the `RetroRacingUniversal` scheme/archive embedding before distributing.
- macOS or iOS build processes in App Store Connect but cannot be attached to a version: verify export compliance, signing, platform availability, and App Store version state before inviting external testers.

## References

- Apple: [Xcode Cloud workflow reference](https://developer.apple.com/documentation/xcode/xcode-cloud-workflow-reference)
- Apple: [Writing custom build scripts](https://developer.apple.com/documentation/xcode/writing-custom-build-scripts)
- Apple: [Environment variable reference](https://developer.apple.com/documentation/xcode/environment-variable-reference)
