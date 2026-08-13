# Debug Simulation

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** DEBUG-only StoreKit and play-limit simulation for testing free vs Unlimited Plays flows.
- **Must not break:** Release builds use real StoreKit entitlements only; Debug UI is hidden outside `BuildConfiguration.shouldShowDebugFeatures`; freemium simulation forces play-limit behavior even on devices with cached Unlimited Plays.
- **Key files:** `BuildConfiguration`, `StoreKitService`, `UserDefaultsPlayLimitService`, `ThemeManager`, shared Settings debug section.

## Behavior Contract

- `StoreKitService.DebugPremiumSimulationMode` has three modes:
  - `.productionDefault`: use real StoreKit entitlements.
  - `.unlimitedPlays`: force Unlimited Plays behavior.
  - `.freemium`: force free-tier behavior.
- Simulation is enabled only when `StoreKitService` is created with `isDebugSimulationEnabled == true`; the default comes from `BuildConfiguration.isDebug`.
- Attempts to set simulation in production must revert to `.productionDefault`.
- `BuildConfiguration.shouldShowDebugFeatures` controls the Settings Debug section and is false in Release builds.
- `.freemium` writes the `PlayLimit.debugForceFreemium` override so play-limit checks ignore any stored unlimited-access flag.
- `.unlimitedPlays` makes premium gating, gated theme access, purchased-state checks, and paywall UI behave as owned without making StoreKit transactions.
- Simulation changes must notify effective premium gating observers so theme selection availability matches Settings UI state.
- `.productionDefault` must be the default mode on a fresh Debug install. Debug persists a valid explicit simulation choice across service recreation and app launches.

## Production Safety

- Production behavior must not depend on hidden UI state, TestFlight state, or prior debug simulation choices. Release ignores the persisted Debug simulation mode without deleting it.
- Release builds must hide the Settings Debug section and use live StoreKit entitlements for `hasPremiumAccess`.
- Returning purchasers may use the premium cache during initial entitlement resolution, but simulation must not make new Release users appear premium.
- Keep the debug override key prefixed under `PlayLimit.` and clear/sync it whenever simulation mode changes.
- The separate `debugGameplay.alternateAppIconsEnabled` rollout flag defaults on in Debug, accepts a Debug Settings override, and always resolves false when Debug features are disallowed. A stored true value must never expose Release UI or paywall copy.
- Disabling alternate icons hides feature surfaces without changing the installed system icon.

## UI and Localization

- The Settings Debug section is last in the Settings list.
- The picker label is “Simulate Unlimited Plays” and user-facing options are production default, Unlimited Plays, and freemium.
- Debug strings live in the shared string catalog with the other Settings strings.
- **Show SpriteKit FPS and node count** reactively applies SpriteKit's built-in `.showsFPS` and `.showsNodeCount` debug options to the gameplay `SpriteView`.
- Configured iPhone/iPad builds expose **Enable alternate app icons** even if UIKit currently reports icon changes as unsupported. Other platform targets do not show it.

## Testing

- Unit tests cover:
  - production mode changes reverting to `.productionDefault`
  - `hasPremiumAccess` and `hasPurchased(_:)` in all three modes
  - `PlayLimit.debugForceFreemium` synchronization
  - effective premium gating callbacks for theme access
  - Debug simulation persistence, invalid-value fallback, and Release isolation from stored choices
  - Release/production simulation isolation
  - Settings visibility through `BuildConfiguration.shouldShowDebugFeatures`
  - SpriteKit frame-stat option mapping for enabled and disabled states
  - alternate-icon fresh-install default, stored Debug override, and Release isolation
- Run targeted isolation tests before release-risk changes:

```bash
swift run --package-path Scripts run-tests \
  --only-testing RetroRacingSharedTests/DebugSimulationProductionIsolationTests
```

## Related

- [monetization.md](monetization.md) — Unlimited Plays and daily play-limit contract.
- [testing.md](testing.md) — general test conventions and validation commands.
