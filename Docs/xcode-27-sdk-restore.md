# Xcode 27 SDK — APIs to Restore

Last updated: 2026-06-26

Working note for toolchain migration. When TestFlight/App Store builds move to **Xcode 27+** exclusively, restore the SDK 27 audio-session path removed for **Xcode 26** compatibility.

**See also:** [Requirements/audio_haptics.md](../Requirements/audio_haptics.md) · `RetroRacingShared/Audio/AVAudioSessionActivation.swift`

---

## Why this note exists

On **2026-06-26**, build **1.5 (28)** needed archiving with **Xcode 26** (`/Applications/Xcode.app`, iOS SDK 26).

The project already used runtime `#available(iOS 27.0, …)` checks around newer AVFoundation APIs (added in commit `edab5cb`, 2026-06-24). That is not enough when the **compile SDK is 26**: Swift still type-checks `@available` bodies, and symbols that do not exist in the iOS 26 SDK fail to compile even inside `if #available(iOS 27.0, *)`.

**Temporary fix:** `AVAudioSessionActivation` now always calls `setActive(true)` (sync/async wrappers unchanged).

**Restore trigger:** Default archive toolchain is Xcode 27+ and you no longer need Xcode 26–built IPAs/PKGs.

---

## Deferred API (restore on Xcode 27+)

| API | Framework | Availability (as originally gated) | File | Benefit |
|---|---|---|---|---|
| `AVAudioSession.activate(options:completionHandler:)` | AVFoundation | iOS 27, tvOS 27, visionOS 27 (`watchOS 5.0` in original gate — verify against current SDK) | `AVAudioSessionActivation.swift` | Async activation with explicit `activated` result instead of legacy `setActive(_:)`; avoids blocking semantics and matches Apple’s newer session lifecycle |

### Call sites (unchanged — already route through the helper)

These already delegate to `AVAudioSessionActivation`; restoring the helper restores the improvement everywhere:

| Caller | Method |
|---|---|
| `AudioPlaybackReadiness` | `activateBlocking()` before engine/player playback |
| `AppBootstrap` | `activate(_:)` during initial session setup and reactivation |
| `AppBootstrap` observers | `requestAudioSessionActivation(trigger:)` on interruption/route changes |

---

## Reference implementation

Canonical pre-simplification version: git commit `edab5cb` (`AVAudioSessionActivation.swift`).

Restore shape:

```swift
#if !os(macOS)
enum AVAudioSessionActivation {
    static func activate(_ session: AVAudioSession = .sharedInstance()) async throws {
        if #available(iOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 11.0, *) {
            try await activateAsynchronously(session)
        } else {
            try await Task.detached(priority: .userInitiated) {
                try session.setActive(true)
            }.value
        }
    }

    static func activateBlocking(_ session: AVAudioSession = .sharedInstance()) throws {
        if #available(iOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 11.0, *) {
            try activateSynchronously(session)
        } else if Thread.isMainThread {
            try runOffMainThread { try session.setActive(true) }
        } else {
            try session.setActive(true)
        }
    }

    @available(iOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 11.0, *)
    private static func activateAsynchronously(_ session: AVAudioSession) async throws {
        try await withCheckedThrowingContinuation { continuation in
            session.activate(options: []) { activated, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if activated {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AudioSessionActivationError())
                }
            }
        }
    }

    @available(iOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 11.0, *)
    private static func activateSynchronously(_ session: AVAudioSession) throws {
        var activationError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        session.activate(options: []) { activated, error in
            if let error {
                activationError = error
            } else if activated == false {
                activationError = AudioSessionActivationError()
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let activationError { throw activationError }
    }
}
#endif
```

> **Note:** Replace `watchOS 11.0` with whatever the Xcode 27 SDK documents for `activate(options:completionHandler:)` on watchOS. The original gate used `watchOS 5.0`, which was likely incorrect for an iOS 27–era API.

### Dual-toolchain compile guard (only if you must support Xcode 26 and 27 simultaneously)

Runtime `#available` is not enough across compile SDKs. If both toolchains must build the same branch, wrap the iOS 27 implementation in a compile-time SDK check, for example:

```swift
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 270000
// activate(options:completionHandler:) implementation
#endif
```

Prefer dropping Xcode 26 from the release pipeline instead of maintaining dual guards long term.

---

## Related Xcode 27 work — already kept (no restore needed)

Commit `edab5cb` included other changes that are **not** gated on iOS 27 SDK symbols and remain in the tree:

| Change | Files | Purpose |
|---|---|---|
| Centralized async/blocking session activation | `AppBootstrap.swift`, `AVAudioSessionActivation.swift` | Single activation path; reactivation on interruption/route change |
| `configureAudioSessionAndWait()` | `AppBootstrap.swift`, `WatchGameView.swift` | watchOS gameplay waits for session before `scene.start()` |
| `WatchApplicationActivity` | `WatchApplicationActivity.swift`, `WatchHapticFeedbackController.swift`, `ContentView.swift` | Foreground detection via `ScenePhase` instead of deprecated `WKExtension.shared().applicationState` |
| `BrandMark` `Text` composition | `BrandMark.swift` | Xcode 27 SwiftUI warning fix |
| Game Center submit `[weak self]` | `GameCenterService.swift` | Concurrency / capture fix |

---

## Other `#available` usage (not deferred)

These use APIs available in the **Xcode 26 SDK** and do not need restore when moving to Xcode 27:

| API / pattern | Availability | File |
|---|---|---|
| `GKAccessPoint.shared.trigger(state:completionHandler:)` | iOS 26, macOS 26 | `AchievementUnlockView+Content.swift` |
| Game Center friend avatars | iOS 14+, tvOS 14+, macOS 11+ | `GameCenterFriendSnapshotService*.swift` |

---

## Restore checklist

1. Confirm archives use **Xcode 27+** (`xcodebuild -version` → 27.x).
2. Restore `AVAudioSessionActivation.swift` from this doc or `git show edab5cb:RetroRacing/RetroRacingShared/Audio/AVAudioSessionActivation.swift`.
3. Archive iOS + macOS; run `RetroRacingSharedTests/GeneratedSoundEffectPlayerTests` and gameplay smoke on device (lane cues, game-over SFX, watch audio start).
4. Delete or archive this note once Xcode 26 is no longer a supported build host.
