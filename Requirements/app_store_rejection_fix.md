# App Store Rejection Fix – Premium Access Issue

## Issue Summary

**Date**: 2026-02-11  
**Status**: ✅ **FIXED**

The app was **rejected by App Store review** because reviewers saw the app as if they already had premium access (unlimited plays), preventing them from:
- Testing the free tier (6 games per day limit)
- Testing the purchase flow
- Seeing the paywall

## Root Cause

In `StoreKitService.swift`, the `debugPremiumEnabled` property was initialized with a default value of `true`:

```swift
public var debugPremiumEnabled: Bool = true  // ❌ BAD: Everyone starts with premium!
```

This meant **all users** (including App Store reviewers using Release builds) started with premium access automatically, because:

```swift
public var hasPremiumAccess: Bool {
    if debugPremiumEnabled {  // This was always true!
        return true
    }
    return !purchasedProductIDs.isEmpty
}
```

Even though the Debug section was hidden in Release builds (via `BuildConfiguration.shouldShowDebugFeatures`), the **default value** was still `true`, so reviewers couldn't experience the free tier.

## The Fix

### 1. Changed Default Value to `false`

**File**: `RetroRacingShared/Services/StoreKitService.swift`

```swift
/// Debug premium toggle – available in DEBUG and TestFlight builds.
/// Defaults to false so App Store reviewers experience the free tier.
public var debugPremiumEnabled: Bool = false  // ✅ FIXED
```

### 2. Load Products on App Launch

**Files**: `RetroRacingUniversal/App/RetroRacingApp.swift`, `RetroRacingTvOS/App/RetroRacingTvOSApp.swift`

Added `.task` modifier to load products and check entitlements on app launch:

```swift
NavigationStack {
    rootView
        .environment(storeKitService)
        .task {
            await storeKitService.loadProducts()
        }
}
```

This ensures:
- Premium users see their status **immediately** in Settings
- Entitlements are loaded **before** navigation to any view
- No delay waiting for PaywallView to trigger the load

### 3. Updated Tests

**File**: `RetroRacingSharedTests/StoreKitServiceTests.swift`

Updated tests that assumed the default was `true`:

- `testGivenInitialStateWhenCheckingDefaultsThenDebugIsDisabledAndNoPremium()`
  - Now verifies `debugPremiumEnabled` defaults to `false`
  - Verifies `hasPremiumAccess` returns `false` initially

- `testGivenDebugEnabledWhenTogglingOffThenPremiumAccessIsDenied()`
  - Now explicitly enables debug mode before testing the toggle-off behavior

### 4. Updated Documentation

**File**: `Requirements/monetization.md`

Added note that `debugPremiumEnabled` defaults to `false` to ensure reviewers experience the free tier.

## Behavior After Fix

| Build Type | `debugPremiumEnabled` Default | Debug Section Visible? | Result |
|------------|-------------------------------|------------------------|--------|
| **Debug** (Xcode) | `false` | ✅ Yes | Developers can toggle it on for testing |
| **TestFlight** | `false` | ✅ Yes | Beta testers can toggle it on if needed |
| **Release** (App Store) | `false` | ❌ No | Reviewers/users start as free tier |

## Testing

✅ All 14 tests pass:
- 7 `StoreKitServiceTests`
- 7 `PremiumAccessIntegrationTests`

## Impact on Users

### App Store Reviewers
- ✅ Will now see the **free tier** by default
- ✅ Can test the **6-game daily limit**
- ✅ Can see the **paywall** after 6 games
- ✅ Can test the **purchase flow**

### Debug/TestFlight Users
- ✅ Can still enable **"Simulate Premium Access"** via Settings → Debug
- ✅ Debug section remains visible in Debug and TestFlight builds
- ✅ No change to developer workflow

### Production Users
- ✅ Start with **free tier** by default
- ✅ Must purchase to get premium (as intended)
- ✅ Debug section hidden (secure, professional)

## Prevention

To prevent similar issues in the future:

1. **Default to the production state**: Boolean flags should default to the **most restrictive/production state** (`false` for debug features, premium access, etc.)
2. **Test with production mindset**: Always verify that Release builds behave correctly for new users
3. **Document defaults**: Explicitly document why defaults are chosen (e.g., "Defaults to false so App Store reviewers experience the free tier")
4. **Add tests for defaults**: Verify the default state in unit tests

## Checklist for Resubmission

- [x] `debugPremiumEnabled` defaults to `false`
- [x] Debug section hidden in Release builds
- [x] All tests pass
- [x] Documentation updated
- [x] App compiles without errors
- [ ] Build new release version
- [ ] Test release build as fresh install
- [ ] Verify free tier behavior (6 games → paywall)
- [ ] Verify purchase flow with sandbox account
- [ ] Resubmit to App Store

---

**Version**: 1.0  
**Last Updated**: 2026-02-11  
**Fixed By**: AI Agent  
**Issue**: App Store Rejection (reviewers saw premium access by default)  
**Solution**: Changed `debugPremiumEnabled` default from `true` to `false`
