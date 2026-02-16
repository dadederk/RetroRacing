# Debug Simulation System

**Status**: ✅ Implemented  
**Last Updated**: 2026-02-16  
**Owner**: Dani Devesa  

## Overview

The debug simulation system allows developers to test premium and freemium scenarios without making actual in-app purchases. This feature is **strictly limited to DEBUG builds** and is automatically disabled in production/release builds.

## Goals

1. **Enable Testing**: Allow developers to test both free and premium user experiences
2. **Production Safety**: Ensure simulation code cannot run in production builds
3. **Real Scenario Testing**: Verify that production scenarios work correctly
4. **Debug Convenience**: Provide easy UI controls for switching between scenarios

## Design Principles

### 1. Production Safety First

- **Compiler Enforcement**: Uses `#if DEBUG` compilation flags to ensure code is excluded from release builds
- **Runtime Guards**: Double protection with `isDebugSimulationEnabled` parameter defaulting to `BuildConfiguration.isDebug`
- **Automatic Fallback**: In production builds, any attempt to change simulation mode is automatically reverted to `.productionDefault`

### 2. No Performance Impact

- **Zero Cost in Production**: Debug simulation code is completely stripped from release builds by the compiler
- **Minimal Overhead in Debug**: Simple enum comparison and boolean checks

### 3. Explicit and Testable

- **Injectable Configuration**: `isDebugSimulationEnabled` can be passed explicitly for testing both debug and production scenarios
- **Observable State**: Simulation mode is an observable property that updates UI automatically
- **Comprehensive Tests**: Dedicated test suite verifies both debug and production behaviors

## Architecture

### Key Components

#### 1. BuildConfiguration (`BuildConfiguration.swift`)

Utility for detecting build configuration at compile time.

```swift
public enum BuildConfiguration {
    /// Returns true if running in a DEBUG build
    public static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Returns true when debug-only UI/features should be visible
    /// Enabled in DEBUG builds only
    public static var shouldShowDebugFeatures: Bool {
        isDebug
    }
}
```

**Key Points:**
- Uses Swift's `#if DEBUG` compilation condition
- `isDebug` is `public` so it can be used as a default parameter value
- `shouldShowDebugFeatures` controls UI visibility

#### 2. StoreKitService Debug Simulation

Provides three simulation modes for testing different premium access scenarios.

##### Simulation Modes

```swift
public enum DebugPremiumSimulationMode: Int, CaseIterable, Sendable {
    case productionDefault  // Uses real StoreKit entitlements
    case unlimitedPlays     // Simulates premium access (always returns true)
    case freemium          // Simulates free tier (always returns false)
}
```

**Mode Behaviors:**

| Mode | `hasPremiumAccess` | Use Case |
|------|-------------------|----------|
| `.productionDefault` | Real entitlements | Default mode, tests actual StoreKit integration |
| `.unlimitedPlays` | Always `true` | Test premium features without purchase |
| `.freemium` | Always `false` | Test free tier limitations even if purchased |

##### Implementation

```swift
private let isDebugSimulationEnabled: Bool

public var debugPremiumSimulationMode: DebugPremiumSimulationMode = .productionDefault {
    didSet {
        guard isDebugSimulationEnabled else {
            // Production builds: always revert to production default
            if debugPremiumSimulationMode != .productionDefault {
                debugPremiumSimulationMode = .productionDefault
                return
            }
            syncPlayLimitDebugMode()
            return
        }
        syncPlayLimitDebugMode()
    }
}

public var hasPremiumAccess: Bool {
    guard isDebugSimulationEnabled else {
        // Production: always use real entitlements
        return !purchasedProductIDs.isEmpty
    }
    
    switch debugPremiumSimulationMode {
    case .productionDefault:
        return !purchasedProductIDs.isEmpty
    case .unlimitedPlays:
        return true
    case .freemium:
        return false
    }
}

public init(
    userDefaults: UserDefaults = InfrastructureDefaults.userDefaults,
    isDebugSimulationEnabled: Bool = BuildConfiguration.isDebug
) {
    self.userDefaults = userDefaults
    self.isDebugSimulationEnabled = isDebugSimulationEnabled
    syncPlayLimitDebugMode()
}
```

**Protection Layers:**
1. **Compile-time**: Default parameter uses `BuildConfiguration.isDebug`
2. **Runtime**: `didSet` guard prevents mode changes in production
3. **Access Control**: `hasPremiumAccess` checks simulation flag before applying mode

#### 3. Play Limit Integration

The simulation system coordinates with `UserDefaultsPlayLimitService` to enforce freemium limits even for users with real premium access.

##### Debug Storage Keys

```swift
enum DebugStorageKeys {
    static let forceFreemiumPlayLimit = "PlayLimit.debugForceFreemium"
}
```

##### Synchronization

```swift
private func syncPlayLimitDebugMode() {
    let shouldForceFreemium = isDebugSimulationEnabled && debugPremiumSimulationMode == .freemium
    userDefaults.set(
        shouldForceFreemium,
        forKey: DebugStorageKeys.forceFreemiumPlayLimit
    )
}
```

##### Play Limit Service Integration

```swift
private func hasUnlimitedAccessEnabled() -> Bool {
    let forceFreemium = userDefaults.bool(forKey: Keys.debugForceFreemium)
    return userDefaults.bool(forKey: Keys.hasUnlimitedAccess) && !forceFreemium
}
```

**Behavior:**
- When `.freemium` mode is active, `forceFreemium` flag is `true`
- Play limit service checks this flag and **disables** unlimited access
- This allows testing free tier behavior even if user has purchased unlimited plays

#### 4. Settings UI

Debug simulation controls appear in Settings only when `BuildConfiguration.shouldShowDebugFeatures` is `true`.

```swift
if BuildConfiguration.shouldShowDebugFeatures {
    Section {
        Picker(
            selection: Binding(
                get: { storeKit.debugPremiumSimulationMode },
                set: { storeKit.debugPremiumSimulationMode = $0 }
            )
        ) {
            Text("Production Default")
                .tag(StoreKitService.DebugPremiumSimulationMode.productionDefault)
            Text("Unlimited Plays")
                .tag(StoreKitService.DebugPremiumSimulationMode.unlimitedPlays)
            Text("Freemium")
                .tag(StoreKitService.DebugPremiumSimulationMode.freemium)
        } label: {
            Text("Simulate Premium Access")
        }
    } header: {
        Text("Debug")
    } footer: {
        Text("Test premium and freemium scenarios without making purchases. Production builds always use real entitlements.")
    }
}
```

**Key Points:**
- Section only rendered when `shouldShowDebugFeatures` is `true`
- Uses `@Observable` for automatic UI updates
- Footer explains the feature and production behavior

## Testing Strategy

### Test Coverage

Comprehensive test suite in `DebugSimulationProductionIsolationTests.swift` covers:

#### 1. Production Build Behavior

- ✅ Simulation mode always reverts to `.productionDefault`
- ✅ `hasPremiumAccess` always uses real entitlements
- ✅ Debug key remains unset even when attempting to set freemium
- ✅ Real unlimited access works regardless of simulation attempts

#### 2. Debug Build Behavior

- ✅ Can set and maintain all three simulation modes
- ✅ `.unlimitedPlays` returns `true` for premium access
- ✅ `.freemium` returns `false` for premium access
- ✅ `.productionDefault` uses real entitlements

#### 3. Play Limit Integration

- ✅ Freemium simulation enforces limits even with real unlimited access
- ✅ Production default respects real unlimited access
- ✅ Production builds ignore freemium simulation attempts

#### 4. Synchronization

- ✅ Debug key syncs correctly when switching modes
- ✅ Debug key remains unset in production builds

#### 5. Build Configuration

- ✅ `BuildConfiguration.isDebug` matches compilation conditions
- ✅ `shouldShowDebugFeatures` matches expected visibility

### Running Tests

```bash
# Run debug simulation isolation tests
cd RetroRacing && xcrun xcodebuild test \
  -scheme RetroRacingSharedTests \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing:RetroRacingSharedTests/DebugSimulationProductionIsolationTests

# Run all related tests
cd RetroRacing && xcrun xcodebuild test \
  -scheme RetroRacingSharedTests \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -only-testing:RetroRacingSharedTests/StoreKitServiceTests \
  -only-testing:RetroRacingSharedTests/PremiumAccessIntegrationTests \
  -only-testing:RetroRacingSharedTests/PlayLimitServiceTests \
  -only-testing:RetroRacingSharedTests/DebugSimulationProductionIsolationTests
```

## Usage Guide

### For Developers

#### Testing Premium Features

1. Launch app in DEBUG mode (Run from Xcode)
2. Navigate to Settings
3. Scroll to "Debug" section (only visible in DEBUG builds)
4. Select "Simulate Premium Access" → "Unlimited Plays"
5. Premium features are now enabled

#### Testing Freemium Limitations

1. Launch app in DEBUG mode
2. Navigate to Settings
3. Select "Simulate Premium Access" → "Freemium"
4. Daily play limits are now enforced
5. Purchase UI appears in appropriate places

#### Testing Production Behavior

1. Launch app in DEBUG mode
2. Navigate to Settings
3. Select "Simulate Premium Access" → "Production Default"
4. App behaves exactly as it would in production
5. Uses real StoreKit entitlements

#### Testing a Purchased State

To test the real purchase flow without spending money:

1. Use StoreKit Configuration file (`Configuration.storekit`) in Xcode
2. StoreKit Testing in Settings allows local purchases
3. Set simulation to "Production Default" to test real integration
4. Delete app to reset local purchases

### For Testers

**TestFlight Builds**: Debug simulation is **NOT available** in TestFlight builds. Only available when running from Xcode in DEBUG mode.

**Production Builds**: Debug simulation is **completely removed** from production builds. The Settings section won't appear, and all simulation code is stripped by the compiler.

## Production Build Verification

### Pre-Release Checklist

Before submitting to App Store:

1. ✅ Verify `BuildConfiguration.shouldShowDebugFeatures` returns `false` in release build
2. ✅ Verify debug section does not appear in Settings
3. ✅ Run production build on device and confirm no debug UI
4. ✅ Test real purchase flow in sandbox environment
5. ✅ Verify premium access works with real entitlements

### How to Verify

#### 1. Build Configuration

```bash
# Build in Release mode
xcodebuild -scheme RetroRacingUniversal \
  -configuration Release \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  build
```

#### 2. Check Compiled Binary

The debug simulation code should be completely absent from release builds:

```bash
# Build release archive
xcodebuild archive -scheme RetroRacingUniversal \
  -configuration Release \
  -archivePath ./build/RetroRacing.xcarchive

# Search for debug symbols (should return nothing)
nm -g ./build/RetroRacing.xcarchive/Products/Applications/RetroRacing.app/RetroRacing | \
  grep -i "debugPremiumSimulation"
```

Expected: No results (symbol not present in release build)

#### 3. Runtime Verification

In release builds:
- Settings "Debug" section is not rendered
- `isDebugSimulationEnabled` is `false`
- `debugPremiumSimulationMode` is always `.productionDefault`
- `hasPremiumAccess` always uses real entitlements

## Edge Cases & Considerations

### 1. Switching from Debug to Production

**Scenario**: User builds in DEBUG, changes simulation mode, then builds in RELEASE.

**Behavior**: 
- Debug UserDefaults keys persist between builds
- Production build ignores these keys
- No impact on production behavior

**Resolution**: None needed. Debug keys are harmless and ignored.

### 2. TestFlight vs. Local Debug

**TestFlight**:
- `BuildConfiguration.isDebug` returns `false`
- Debug simulation not available
- Tests real StoreKit sandbox

**Local Debug**:
- `BuildConfiguration.isDebug` returns `true`
- Debug simulation available
- Can use StoreKit Configuration file or real sandbox

### 3. Freemium Simulation with Real Purchase

**Scenario**: User has real unlimited access purchase. Developer sets `.freemium` mode.

**Debug Build Behavior**:
- `storeKit.hasPremiumAccess` returns `false`
- Play limits are enforced (forceFreemium flag set)
- Purchase was not revoked, only overridden

**Production Build Behavior**:
- Simulation ignored
- Real unlimited access works normally

### 4. App Store Reviewer Testing

App Store reviewers test in production builds and cannot access debug simulation. This is intentional:

- Reviewers see the real free tier experience
- They can make real sandbox purchases to test premium
- No confusion from debug-only features

### 5. Coordinated State Management

The simulation mode coordinates state across multiple services:

```
┌─────────────────────┐
│  StoreKitService    │
│  simulationMode     │
└──────────┬──────────┘
           │
           ├─► hasPremiumAccess (computed)
           │
           └─► syncPlayLimitDebugMode()
                       │
                       ▼
           ┌───────────────────────┐
           │  UserDefaults         │
           │  forceFreemiumFlag    │
           └───────────┬───────────┘
                       │
                       ▼
           ┌───────────────────────────┐
           │  UserDefaultsPlayLimit    │
           │  hasUnlimitedAccess       │
           └───────────────────────────┘
```

**Consistency Guarantees:**
- Simulation mode change triggers immediate sync
- Play limit service reads fresh flag value
- No async coordination needed (all on main actor)

## Security Considerations

### Why This Approach is Safe

1. **Compiler Stripping**: `#if DEBUG` completely removes code from release builds
2. **No Server Involvement**: Simulation is local-only, doesn't affect remote state
3. **Sandboxed Testing**: StoreKit testing uses sandbox environment
4. **Observable Only**: Users can't inject or modify simulation mode via deep links or external APIs

### What Could Go Wrong?

**Scenario**: Malicious user builds app with `DEBUG` flag enabled.

**Impact**: Limited. User could bypass play limits locally, but:
- No revenue loss (they're building from source)
- Can't affect other users
- Can't generate fake receipts
- StoreKit verification still required for real purchases

**Mitigation**: Apple's App Store process prevents submission of DEBUG builds.

## Localization

Localized strings in `Localizable.xcstrings`:

```json
{
  "debug_section_title": {
    "en": "Debug",
    "es": "Depuración",
    "ca": "Depuració"
  },
  "debug_simulate_premium": {
    "en": "Simulate Premium Access",
    "es": "Simular Acceso Premium",
    "ca": "Simular Accés Premium"
  },
  "debug_simulation_mode_default": {
    "en": "Production Default",
    "es": "Producción (Predeterminado)",
    "ca": "Producció (Per Defecte)"
  },
  "debug_simulation_mode_unlimited": {
    "en": "Unlimited Plays",
    "es": "Partidas Ilimitadas",
    "ca": "Partides Il·limitades"
  },
  "debug_simulation_mode_freemium": {
    "en": "Freemium (5 Daily Plays)",
    "es": "Freemium (5 Partidas Diarias)",
    "ca": "Freemium (5 Partides Diàries)"
  },
  "debug_simulate_premium_footer": {
    "en": "Test premium and freemium scenarios without making purchases. Production builds always use real entitlements.",
    "es": "Prueba escenarios premium y freemium sin realizar compras. Las compilaciones de producción siempre usan derechos reales.",
    "ca": "Prova escenaris premium i freemium sense fer compres. Les compilacions de producció sempre utilitzen drets reals."
  }
}
```

## Future Enhancements

### Potential Improvements

1. **Simulation Presets**: Quick buttons for common test scenarios
2. **Purchase History Simulation**: Mock purchase/restore flows
3. **Transaction Testing**: Simulate pending/cancelled/failed purchases
4. **Multi-Product Support**: When adding more IAPs, extend simulation

### Not Planned

- **TestFlight Debug Mode**: Intentionally excluded to test real sandbox
- **Remote Simulation Control**: Would be security risk
- **Production Debug Mode**: Contradicts safety principles

## Related Documentation

- `/Requirements/in_app_purchases_setup.md` - Overall IAP architecture
- `/Requirements/monetization.md` - Business model and pricing
- `/Requirements/premium_access_verification.md` - Premium access validation
- `/Requirements/testing.md` - Overall testing strategy
- `AGENTS.md` - Development guidelines and architecture patterns

## Change Log

### 2026-02-16 - Initial Implementation
- Added `DebugPremiumSimulationMode` enum with three modes
- Implemented `isDebugSimulationEnabled` flag with runtime guards
- Added debug settings UI section (DEBUG builds only)
- Created `DebugStorageKeys.forceFreemiumPlayLimit` coordination
- Integrated with `UserDefaultsPlayLimitService`
- Made `BuildConfiguration.isDebug` public for default parameter
- Created comprehensive test suite (`DebugSimulationProductionIsolationTests`)
- Documented architecture and safety mechanisms

## Summary

The debug simulation system provides a **safe, convenient, and comprehensive** way to test premium and freemium scenarios without making real purchases. Key guarantees:

✅ **Production Safety**: Compiler and runtime guards ensure simulation never runs in release builds  
✅ **Zero Production Impact**: Debug code is completely stripped from release binaries  
✅ **Comprehensive Testing**: Test suite verifies both debug and production behaviors  
✅ **Developer Convenience**: Easy-to-use Settings UI for quick scenario switching  
✅ **Coordinated State**: Seamless integration with play limit service  
✅ **Well-Documented**: Clear usage guide and architecture documentation  

The system follows RetroRacing's architectural principles: protocol-driven design, dependency injection, comprehensive testing, and explicit over implicit behavior.
