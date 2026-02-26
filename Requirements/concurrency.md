# Concurrency Guardrails

## Build settings
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` across all targets.
- `SWIFT_STRICT_CONCURRENCY = targeted` (step 1). Escalate to `complete` once clean builds/tests succeed under targeted.

## Principles
- Prefer structured concurrency; avoid `DispatchQueue` unless bridging to SDK APIs.
- Avoid `@unchecked Sendable`. If Sendable conformance is required, document invariants or move state into an actor.
- Keep UI-bound types synchronous and main-thread friendly; favour thin wrappers that schedule work on actors/tasks instead of long-lived queues.
- Cancellation required for long-running UI-tied work (SwiftUI `.task`, timers, button flashes, auth timeouts).

## Allowed patterns
- Actor-backed workers behind synchronous facades when shared mutable state needs strict isolation.
- Short-lived `Task {}` scopes for UI effects, always cancellable via stored handles or lifecycle hooks.
- `Task.sleep` for lightweight delays; store and cancel tasks when views disappear or new events supersede the work.

## Discouraged patterns
- `DispatchQueue.asyncAfter` in SwiftUI views (use cancellable `Task`).
- Force-unwraps or `@unchecked Sendable` to silence warnings.
- Long-running tasks without cancellation tokens/handles.

## Haptics, sound, and assets
- Haptics and asset loaders remain synchronous and UI-facing; they should not cross threads.
- Generated sound playback uses cancellable tasks for fade/completion timing; UI callbacks execute on the main actor.

## Testing expectations
- Add/maintain tests that cover:
  - Task cancellation for UI-timeout flows.
  - Generated sound playback wrapper (play/stop/volume) happy paths.
  - Haptic controllers remain no-op on unsupported platforms.
