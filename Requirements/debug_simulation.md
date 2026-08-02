# Debug Simulation

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** DEBUG-only StoreKit and play-limit simulation for testing free vs Unlimited Plays flows.
- **Must not break:** Release builds use real StoreKit entitlements only; Debug UI is hidden outside `BuildConfiguration.shouldShowDebugFeatures`; freemium simulation forces play-limit behavior even on devices with cached Unlimited Plays.
- **Key files:** `BuildConfiguration`, `StoreKitService`, `UserDefaultsPlayLimitService`, shared Settings debug section.

## Behavior Contract

- `StoreKitService.DebugPremiumSimulationMode` has three modes:
  - `.productionDefault`: use real StoreKit entitlements.
  - `.unlimitedPlays`: force Unlimited Plays behavior.
  - `.freemium`: force free-tier behavior.
- Simulation is enabled only when `StoreKitService` is created with `isDebugSimulationEnabled == true`; the default comes from `BuildConfiguration.isDebug`.
- Attempts to set simulation in production must revert to `.productionDefault`.
- `BuildConfiguration.shouldShowDebugFeatures` controls the Settings Debug section and is false in Release builds.
- `.freemium` writes the `PlayLimit.debugForceFreemium` override so play-limit checks ignore any stored unlimited-access flag.
- `.unlimitedPlays` makes premium gating, purchased-state checks, and paywall UI behave as owned without making StoreKit transactions.
- `.productionDefault` must be the default mode for fresh services and app launches.

## Production Safety

- Production behavior must not depend on hidden UI state, TestFlight state, or prior debug simulation choices.
- Release builds must hide the Settings Debug section and use live StoreKit entitlements for `hasPremiumAccess`.
- Returning purchasers may use the premium cache during initial entitlement resolution, but simulation must not make new Release users appear premium.
- Keep the debug override key prefixed under `PlayLimit.` and clear/sync it whenever simulation mode changes.

## UI and Localization

- The Settings Debug section is last in the Settings list.
- The picker label is “Simulate Unlimited Plays” and user-facing options are production default, Unlimited Plays, and freemium.
- Debug strings live in the shared string catalog with the other Settings strings.

## Testing

- Unit tests cover:
  - production mode changes reverting to `.productionDefault`
  - `hasPremiumAccess` and `hasPurchased(_:)` in all three modes
  - `PlayLimit.debugForceFreemium` synchronization
  - Release/production simulation isolation
  - Settings visibility through `BuildConfiguration.shouldShowDebugFeatures`
- Run targeted isolation tests before release-risk changes:

```bash
swift run --package-path Scripts run-tests \
  --only-testing RetroRacingSharedTests/DebugSimulationProductionIsolationTests
```

## Related

- [monetization.md](monetization.md) — Unlimited Plays and daily play-limit contract.
- [testing.md](testing.md) — general test conventions and validation commands.
