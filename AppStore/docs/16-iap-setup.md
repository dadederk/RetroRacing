# Unlimited Plays IAP Setup

Operational reference for maintaining the Unlimited Plays non-consumable in App Store Connect.

## Product Contract

| Field | Value |
|---|---|
| Type | Non-consumable |
| Product ID | `com.accessibilityUpTo11.RetroRacing.unlimitedPlays` |
| Reference name | `Unlimited Plays` |
| User-facing name | `Unlimited Plays` |

- The product ID must match `StoreKitService.ProductID.unlimitedPlays`.
- Pricing is managed through Helm/App Store Connect, not app code. See [../../Plans/aso/04-pricing-strategy.md](../../Plans/aso/04-pricing-strategy.md).
- UI must use StoreKit `displayPrice`.

## Localizations

IAP localization source is managed by the Scripts ASC workflow. Validate before upload:

```bash
./retrorapid asc iap --check
./retrorapid asc iap --dry-run
./retrorapid asc iap --asc-api
```

Prefer `--asc-api` from agent shells. Credentials come from Keychain `RetroRapid ASC *` or `ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_PRIVATE_KEY`.

## Capabilities and Review

- Ensure Paid Apps agreement, tax, and banking are active.
- Ensure the selling app target has the In-App Purchase capability.
- Keep at least one IAP screenshot showing the paywall or purchase section.
- App Review notes should explain:
  - first play day: 9 free rounds
  - later days: 3 free rounds
  - paywall appears after the free limit
  - purchase removes solo daily limits forever

## Sandbox Checks

- Fresh free install reaches the paywall at the expected limit.
- Sandbox purchase unlocks Unlimited Plays immediately and persists after app restart.
- Restore after reinstall restores entitlement and clears the play limit.
- Refund/revocation returns the user to free-tier behavior after StoreKit entitlements refresh.
- Release/TestFlight builds do not expose debug simulation controls.
