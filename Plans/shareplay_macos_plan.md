# SharePlay on macOS Plan

**Status:** Implemented in code; manual QA pending.

**See also:** [`Requirements/shareplay_multiplayer.md`](../Requirements/shareplay_multiplayer.md) (shipped behavior) · [`shareplay_competitive_mode_plan.md`](shareplay_competitive_mode_plan.md) (original iOS+iPad planning record)

## Summary

Enable RetroRapid's existing SharePlay competitive mode on macOS by extending the current iOS/iPad implementation seams instead of creating a parallel Mac feature.

The implementation reuses the shared state machine, deterministic traffic seed, 90-second retry flow, free-play exception, guest speed restore, SwiftUI menu/game/overlay/result UI, activation handoff coordinator, host activation controller, state notifier, timer controller, and GroupActivities transport adapter. AppKit is used only inside the macOS system sharing-controller host.

tvOS and visionOS remain no-op until their product status, system presentation, focus behavior, and manual QA are explicitly planned. watchOS remains no-op unless Apple adds Group Activities capability.

## Key Changes

- Broaden Universal SharePlay GroupActivities gates from iOS-only to iOS/macOS across the activity, messenger, coordinator, service actor, split service extensions, host activation controller, state notifier, timer controller, and sharing presenter.
- Keep `SharePlayActivationHandoffCoordinator` as the app-facing host-start owner on iOS and macOS. It owns duplicate-tap handling, sharing-controller success handoff, delayed direct-activation recovery, timeout cleanup, and typed `SharePlayHostActivationReason` logging.
- Add a macOS branch to `SharePlayActivitySharingPresenter` using `NSViewControllerRepresentable`; keep the SwiftUI-facing API identical to iOS.
- Wire macOS in `RetroRacingApp` by constructing `GroupActivitiesSharePlayMatchService`, `GroupStateObserver`, and `SharePlayActivationHandoffCoordinator` with SharePlay availability enabled.
- Pass **Play with Friends** into the macOS `MenuView` overlay and attach the hidden sharing presenter in the Mac menu background, matching the iOS flow.
- Lock the macOS settings sheet during active SharePlay matches, including `Cmd+,`.

## Future Platform Strategy

- Do not add `#if os()` to `RetroRacingShared` service logic. Shared policy types remain platform-agnostic.
- Future tvOS/visionOS enablement should reuse the existing handoff/policy/service seams unless a platform API proves incompatible.
- Before enabling tvOS, validate system invite/start UI, focus behavior in `MenuView` and `SharePlayResultView`, controller input while pause-locked, and public App Store positioning.
- Before enabling visionOS, validate windowed presentation first; immersive or spatial SharePlay behavior belongs in a separate plan.
- Keep `NoOpSharePlayMatchService` for tvOS, watchOS, visionOS, tests, and previews.

## Testing

Automated validation:

```bash
./retrorapid test package
./retrorapid check
./retrorapid test
xcrun xcodebuild build -project RetroRacing/RetroRacing.xcodeproj -scheme RetroRacingUniversal -destination "platform=macOS"
```

Manual QA before shipping public Mac SharePlay claims:

- Mac host to Mac guest.
- Mac host to iPhone/iPad guest.
- iPhone/iPad host to Mac guest.
- Ineligible Mac invite flow, cancel, and re-tap.
- Eligible FaceTime/Messages Mac direct activation.
- Sharing-controller success with delayed session delivery.
- Menu/close exit mid-match.
- `Cmd+,` settings during active SharePlay, confirming Speed is locked.
- Deterministic traffic parity and 90-second retry timeout across Mac/iOS pairs.

## Rollout Notes

- App Store screenshots and metadata remain a separate rollout decision. macOS is a shipping platform, but public SharePlay claims need coordinated ASO updates through `Plans/INDEX.md` and `AppStore/README.md`.
- Capture paired `SHAREPLAY_*` logs during manual QA for join, disconnect, invite handoff, and retry-timeout issues.
