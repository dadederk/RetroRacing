# IAP Pricing Strategy

Part of [ASO & growth plans](README.md). Index: [retrorapid_aso_growth_plan.md](../retrorapid_aso_growth_plan.md).

Last updated: 2026-07-03
**See also:** [Monetization requirements](../../Requirements/monetization.md)

---

## Agent summary

> Narrow tasks may stop here; open the full plan before changing App Store Connect or Helm pricing.

- **Scope:** RetroRapid Unlimited Plays country pricing through Helm/App Store Connect.
- **Must not break:** Keep `Unlimited Plays` as one non-consumable product; do not introduce subscriptions; do not require a binary release for price-only changes.
- **Key refs:** [Monetization requirements](../../Requirements/monetization.md), [portfolio pricing strategy](../../../Xarra/Plans/aso/04-pricing-strategy.md).

## Baseline

- Keep the current one-time `Unlimited Plays` US/base price at **2.99**.
- Do not run a global 2.99 -> 1.99 -> 2.99 promo window in the same pass as country PPP pricing; it would make the country-pricing read harder to interpret.
- Keep user-facing positioning simple: play free every day, or unlock Unlimited Plays once; no subscription.

## Helm Country Pricing Default

Use the shared portfolio rule from Xarra's pricing plan:

| Helm field | Value |
|---|---|
| Price Calculation Strategy | Purchasing Power Parity Index |
| Index | Netflix, then targeted Spotify, then targeted IMF |
| Fallback Handling | Apple Equalization only after all three datasets miss a territory |
| Preferred Ending | `.99` |
| Upper Bound | Current base price for Unlimited Plays in App Store Connect |
| Lower Bound | None |
| Is Temporary | Off |

Rationale: the Mestre audit on 2026-07-03 showed Netflix PPP produced a fairer spread than IMF for the outlier markets we checked. IMF left Afghanistan and Sri Lanka uncovered, while Netflix covered Afghanistan, Sri Lanka, and Venezuela and raised Russia out of the bottom of the table. For RetroRapid, the lower coverage risk is more important than preserving an older test window because Unlimited Plays is a single future-purchase price, not a subscription migration.

Do not rely on Apple Equalization for known Netflix gaps when a Helm dataset covers the territory. Run targeted fallback passes only for territories missing from the previous index:

1. Netflix first for all territories.
2. Spotify for territories missing from Netflix.
3. IMF for territories still missing from Netflix and Spotify.
4. Apple Equalization only if all three datasets miss the territory.

The 2026-07-03 coverage audit found Netflix missing `CHN`, `RUS`, and `XKS`; Spotify covers `XKS`; IMF covers `CHN` and `RUS`. The three-index pass covers all 175 App Store territories.

### Helm Execution Notes

Resolved App Store Connect IDs on 2026-07-03:

| Resource | ID |
|---|---|
| App | `6758641625` |
| Unlimited Plays IAP | `6759012658` |

Pass Helm's bundled CSV paths directly to avoid CLI alias-loading issues:

```bash
/usr/local/bin/helm-asc inAppPurchase 6759012658 prices set \
  --strategy ppp \
  --ppp-index /Applications/Helm.app/Contents/Resources/netflix-helm-dataset.csv \
  --ppp-fallback equalization \
  --base-territory USA \
  --base-price 2.99 \
  --maximum-price 2.99 \
  --preferred-ending x99 \
  --all-territories \
  --dry-run \
  --agent
```

Only remove `--dry-run` after the preview returns `status: "ok"`, `pricePointCount: 175`, and an empty `skippedTerritories` list.

For targeted fallback passes, replace the index path and territories:

```bash
--ppp-index /Applications/Helm.app/Contents/Resources/spotify-helm-dataset.csv --territory XKS
--ppp-index /Applications/Helm.app/Contents/Resources/imf-helm-dataset.csv --territory CHN --territory RUS
```

Applied result on 2026-07-03:

- CSV-backed Netflix PPP recorded Helm PPP metadata, updated 175 current price points, skipped no territories, left no upcoming schedule, kept United States at `USD 2.99`, and produced representative local prices including United Kingdom `GBP 1.99`, Germany `EUR 1.99`, Switzerland `CHF 2.40`, Brazil `BRL 6.99`, Türkiye `TRY 42.99`, South Africa `ZAR 26.99`, Philippines `PHP 69`, and Nigeria `NGN 990`.
- Targeted fallback corrections applied immediately: Kosovo `EUR 0.99` from Spotify, China Mainland `CNY 10` from IMF, and Russia `RUB 95` from IMF.
- The Kosovo dry-run with `--maximum-price 2.99` hit Apple's price-point equalization endpoint with a 403; rerunning without the cap produced `EUR 0.99`, which is below the US base ceiling, and the live write succeeded.

## Product Rule

- Product ID stays unchanged: `com.accessibilityUpTo11.RetroRacing.unlimitedPlays`.
- Type stays non-consumable.
- Existing purchasers keep entitlement automatically; price changes affect future purchases only.
- Keep all paywall/UI price copy powered by StoreKit `displayPrice`; do not hard-code local price copy.
- Do not add extra price rows, subscriptions, or country-specific product IDs.

## Validation Checklist

Before saving in Helm:

- Preview generated prices for:
  - United States
  - United Kingdom
  - Germany
  - Switzerland
  - India
  - Brazil
  - Mexico
  - Turkey
  - South Africa
  - Philippines
  - Nigeria
- Confirm no generated price exceeds the current base price.
- Confirm lower-income markets receive meaningful reductions, not only currency equalization.
- Confirm the Netflix-missing territories use the targeted fallback sources: `XKS` from Spotify, then `CHN` and `RUS` from IMF.
- Confirm the product remains cleared for sale after scheduling.

After rollout:

- Product page conversion rate
- IAP conversion rate per first-time installer
- Net proceeds per 1,000 product page views
- D1 and D7 retention split by purchaser/non-purchaser
- Refunds and support complaints by territory

## Future Price Tests

- A flat 1.99 global promo can still be tested later, after the PPP pass has at least 28-56 days of data.
- Keep 2.99 if it wins net proceeds per 1,000 views.
- Consider a 1.99 global or territory-specific promotion only if:
  - IAP conversion lifts materially (target +30% or better), and
  - net proceeds per 1,000 views do not decline.
