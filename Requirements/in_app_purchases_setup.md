# In‑App Purchases – Manual Setup Guide (RetroRacing)

This guide describes all **manual steps** required to set up and maintain the **Unlimited Plays** in‑app purchase for RetroRacing, across:

- **Apple Developer account & certificates**
- **App Store Connect**
- **Xcode project configuration**
- **Testing (sandbox & TestFlight)**

It assumes the implementation in `RetroRacingShared` is already present (StoreKit 2, `StoreKitService`, `PlayLimitService`).

---

## 1. Prerequisites

### 1.1 Apple Developer Account

- Ensure the app’s Apple ID is part of an **active Apple Developer Program**.
- You need:
  - Access to **App Store Connect**
  - Access to the **Developer portal** (Certificates, Identifiers & Profiles)
  - Permission to **edit In‑App Purchases** for the RetroRacing app.

### 1.2 Bundle Identifier

- Confirm the app’s **bundle identifier** in Xcode matches the one in App Store Connect, e.g.:
  - `com.yourcompany.RetroRacing` (example – use your actual identifier).
- The **primary app target** (RetroRacingUniversal) must be registered in:
  - Developer portal → **Certificates, Identifiers & Profiles** → **Identifiers**
  - App Store Connect → **Apps**

### 1.3 Agreements, Tax, and Banking

In App Store Connect:

1. Go to **App Store Connect → Agreements, Tax, and Banking**.
2. Ensure the **Paid Apps** agreement is **active**:
   - Accept any pending agreements.
   - Fill out **tax** and **banking** information as required.
3. Without this, you won’t be able to submit IAPs for review.

---

## 2. App Store Connect – Product Creation

### 2.1 Create the Non‑Consumable Product

1. Go to **App Store Connect → Apps → RetroRacing**.
2. Select the **app record** (the correct platform bundle).
3. Open the **In‑App Purchases** section:
   - In the left sidebar: **Features → In‑App Purchases** (or under the “Monetization” section in the new UI).
4. Click **+** → **New In‑App Purchase**.

Configure:

- **Type**: `Non‑Consumable`
- **Reference Name**: `Unlimited Plays`
  - Internal only, but keep it clear and consistent.
- **Product ID**: `com.retroRacing.unlimitedPlays`
  - Must exactly match the ID used in code:  
    `StoreKitService.ProductID.unlimitedPlays = "com.retroRacing.unlimitedPlays"`.
- **Cleared for Sale**: Enabled.

### 2.2 Pricing

1. In the **Price Schedule** section:
   - Choose an appropriate **price tier** (e.g. **Tier 2** ≈ $1.99 USD).
2. Consider:
   - Price should feel **impulse‑friendly** (low friction).
   - Align with your other apps if you want a consistent pricing story.

You can adjust the price later, but be aware:

- Price changes affect **future purchases**.
- Existing purchases remain valid; users keep their entitlement.

### 2.3 Localized Display Name & Description

For each supported language (at least EN, ES, CA):

- **English (US)**
  - Display Name: `Unlimited Plays`
  - Description:  
    `Unlock unlimited games every day and support RetroRacing development!`

- **Spanish (Spain)**
  - Display Name: `Partidas Ilimitadas`
  - Description:  
    `¡Desbloquea partidas ilimitadas cada día y apoya el desarrollo de RetroRacing!`

- **Catalan (Valencià)**
  - Display Name: `Partides Il·limitades`
  - Description:  
    `Desbloqueja partides il·limitades cada dia i dóna suport al desenvolupament de RetroRacing!`

**Recommendations:**

- Keep descriptions **short and benefit‑focused**:
  - Unlimited plays
  - Supporting the game
  - No subscription / one‑time purchase.
- Avoid **technical details** (StoreKit, receipts, etc.) – that’s for docs, not users.

### 2.4 Screenshot for the Product

Apple requires at least one **IAP screenshot**:

- Suggested screenshot:
  - The **paywall screen** showing:
    - “Unlock Unlimited Games”
    - Coffee/support copy
    - Product card and button.
- Format:
  - At least **640×920 px**, portrait.
  - High‑contrast, legible text; avoid tiny fonts.

**Tip:** Use the same style as your **App Store screenshots** for visual consistency.

### 2.5 App Review Notes for IAP

When you submit an app version that includes this IAP, in the **App Review Notes** (under app version submission):

Include:

```text
RetroRacing uses a freemium model:
- Free users: 5 games per day (resets at midnight).
- Premium users: Unlimited games forever (one-time purchase).

In-app purchase:
- Product ID: com.retroRacing.unlimitedPlays
- Type: Non-consumable (Unlimited Plays)

To test Premium:
1. Launch the app.
2. Play 5 games to reach the daily limit.
3. The paywall will appear.
4. Use a sandbox account to purchase Unlimited Plays.
5. After purchase, there is no daily limit and the Theme picker in Settings becomes configurable.
```

This helps reviewers understand the flow and how to trigger the paywall.

---

## 3. Xcode – Project Configuration

### 3.1 In‑App Purchase Capability

For each main app target that should **sell or honor** the IAP (at minimum RetroRacingUniversal; optionally tvOS/watchOS if they share the entitlement):

1. In Xcode:
   - Select the **target** → **Signing & Capabilities**.
2. Click **+ Capability**.
3. Add **In‑App Purchase**.

This:

- Ensures the app is allowed to call StoreKit APIs in production.
- Should match the bundle ID used in App Store Connect.

### 3.2 StoreKit Configuration File (Optional but Recommended)

For easier development/testing **before** App Store Connect is fully wired:

1. In the RetroRacing Xcode project root, create a file:
   - File → New → File → **StoreKit Configuration File**.
   - Name: `RetroRacing.storekit`.
2. Add a **Non‑Consumable** product:
   - Product ID: `com.retroRacing.unlimitedPlays`
   - Reference Name / Display Name similar to App Store Connect.
3. Set the StoreKit configuration for your **local scheme**:
   - Select scheme: **RetroRacingUniversal**.
   - Edit Scheme → **Run** → Options.
   - Under **StoreKit Configuration**, pick `RetroRacing.storekit`.

This allows you to:

- Test the purchase flow locally with the simulator, without hitting App Store servers.

### 3.3 Code Checks (Quick sanity list)

Confirm these constants and strings match App Store Connect:

- `StoreKitService.ProductID.unlimitedPlays.rawValue == "com.retroRacing.unlimitedPlays"`.
- No typos in:
  - `ProductID` enum raw value.
  - Any hard‑coded IDs in test/demo code (if any).

---

## 4. Testing IAP

### 4.1 Sandbox Testers

In **App Store Connect → Users and Access → Sandbox Testers**:

1. Create at least one tester per relevant region:
   - Example:
     - US tester for USD pricing.
     - ES tester for Euro/local pricing.
2. For each tester:
   - Use a **realistic but unique email** (not an Apple ID already on a device).
   - Record the password in a secure place.

On device / simulator:

- Sign out of the real App Store account.
- When the purchase sheet appears, sign in with the **sandbox tester**.

### 4.2 Local Development (StoreKit Config vs Real Sandbox)

- **Before** the App Store product is “Ready to Submit/Approved”:
  - Prefer the **StoreKit configuration file** for early UI and flow testing.
- **After** the product exists in App Store Connect:
  - You can uncheck the StoreKit config in the scheme and test against **real sandbox**:
    - The app will connect to Apple’s sandbox servers.
    - Required for final verification before submission.

### 4.3 Test Scenarios

Recommended tests:

- **Free tier**:
  - Play 5 games in one day → verify:
    - 6th attempt shows the paywall.
    - Daily counter and Settings “Remaining X of 5” update correctly.
- **Purchase**:
  - From paywall, buy Unlimited Plays using a sandbox account:
    - Verify purchase success alert.
    - Verify daily limit is removed (even after restarting the app).
    - Verify Theme picker becomes configurable.
- **Restore Purchases**:
  - On a second device or after reinstall:
    - Tap **Restore Purchases** in Settings.
    - Confirm entitlement is restored and daily limit removed.
- **Simulate Premium**:
  - Toggle “Simulate Premium Access” in Settings:
    - Should enable premium behavior even without purchase (for testing only).

---

## 5. Developer Portal (Certificates, Identifiers & Profiles)

In most modern setups, no additional manual work is needed beyond what Xcode manages, but confirm:

1. **Identifier** is configured:
   - Developer portal → **Identifiers → App IDs**.
   - Select your RetroRacing app ID.
   - Under **Capabilities**, ensure **In‑App Purchase** is enabled (usually automatic).
2. **Provisioning Profiles**:
   - For manual signing setups, ensure profiles are regenerated if you changed capabilities.
   - For automatic signing, Xcode updates them automatically when you add the capability.

---

## 6. Recommendations & Gotchas

### 6.1 Naming & IDs

- Do **not** change the Product ID once the app is live:
  - Existing purchases are tied to that ID.
- You can change the **Display Name** and **Description** between versions if messaging needs refinement.

### 6.2 Price Changes

- If you change price tiers later:
  - Document this in internal release notes.
  - Keep marketing / docs in sync (avoid old pricing references).

### 6.3 Review Stability

- Apple often tests purchases from a **fresh install**:
  - Ensure the paywall is reachable **without needing hidden gestures** or complex flows.
  - Ensure error handling is graceful (e.g., `error_product_not_available` string).

### 6.4 Refunds and Entitlement

- StoreKit 2 automatically **revokes entitlements** after refund:
  - No special server logic is required.
  - `Transaction.currentEntitlements` will no longer contain the refunded transaction.
  - `StoreKitService` will then see `purchasedProductIDs.isEmpty` and `hasPremiumAccess == false` (unless Simulate Premium is on).

---

## 7. Quick Checklist Before Submission

- [ ] Product `com.retroRacing.unlimitedPlays` exists in App Store Connect as **Non‑Consumable**.
- [ ] Localized Display Name & Description set for EN, ES, CA.
- [ ] Price tier selected and active.
- [ ] IAP screenshot uploaded (paywall/settings).
- [ ] App target has **In‑App Purchase** capability.
- [ ] StoreKit product ID in code matches App Store Connect.
- [ ] Sandbox testers created and tested:
  - [ ] Purchase flow.
  - [ ] Restore Purchases.
- [ ] Daily limit behaves correctly pre‑purchase and disappears post‑purchase.
- [ ] Theme picker gates configuration correctly for free vs premium.
- [ ] Simulate Premium toggle works and is documented as a **debug/testing tool**.
- [ ] App Review notes include clear instructions for testing the IAP.

Once all the above are complete, you’re ready to ship or submit a build with working in‑app purchases for **Unlimited Plays** in RetroRacing.  
