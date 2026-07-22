# Product Page Optimization

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-07-23
**See also:** [Screenshot ASO variants](06-screenshots.md#screenshot-title-aso-variants-first-three-slides) · [Improvement loop](10-aso-improvement-loop.md)


---

## Product Page Optimization

Use Product Page Optimization only after the base metadata and screenshot copy are clean. Apple supports testing up to three variants of app icons, screenshots, and previews for iOS/iPadOS product pages, and results should be judged on conversion lift and confidence.

First test candidate:

- Control: current visual style with recommended 7-slide order.
- Treatment: Apple Watch/control story in slide 3, accessibility moved to slide 4.

Start with one treatment, not two, unless traffic can deliver roughly 1,000 impressions per treatment. If product-page traffic is below that level, use sequential 28-day screenshot releases and treat the result as directional rather than statistically conclusive.

Do not test name/subtitle changes through PPO; Apple does not use PPO for those fields. Treat metadata updates as versioned experiments with 28-day observation windows.

## Custom Product Pages

Use Custom Product Pages for segmented campaigns, not as a replacement for the default product page. The default screenshot funnel should stay gameplay-first; Custom Product Pages can focus on one motivated audience or traffic source.

### SharePlay Campaign Page

Status: `PLANNED`; copy and storyboard live in [SharePlay release campaign](../../Plans/aso/10-shareplay-release-campaign.md).

Use this before, or as the next evolution of, the existing Game Center page if the release
campaign leads with live friend races. Keep the default page broad and gameplay-first; route
SharePlay/event/social traffic to a focused Custom Product Page with iPhone/iPad-only claims.

Apple docs checked 2026-07-03; Custom Product Page guidance reconfirmed for SharePlay planning
on 2026-07-23:

- Custom Product Pages support different screenshots, app previews, promotional text, and keywords, and are shareable through a unique URL.
- They are visible through the page URL, or through App Store search only after assigning keywords and approval/visibility.
- Keyword assignment uses keywords from the latest approved app version, per localization.
- App Analytics exposes impressions, downloads, and conversion rate for each page after the page has at least five first-time downloads.
- Product Page Optimization tests do not apply to Custom Product Pages.

### Game Center Campaign Page

Status: source copy `READY`; Screenshot Studio export and App Store Connect setup `PLANNED`.

Screenshot Studio source:

- `AppStore/GameCenter/RetroRapidGameCenter.screenshotstudio/`
- Platforms prepared in source: iPhone, iPad, Mac
- Locales prepared in source: `en-US`, `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, `ca`

Recommended use:

- Target traffic from Game Center, achievement, challenge, friend-racing, and leaderboard messaging.
- Use the page URL in social posts, editorial follow-up, Apple Search Ads campaigns, or release-update links.
- Do not use this as the control product page: Game Center is a retention/replayability hook, while the default page still needs to explain the game loop first.
- Create the page after v1.5 is approved if possible, so the latest approved keyword set includes the Game Center-adjacent terms staged in `metadata/retrorapid-v1.5.json`.

Reference name:

- `Game Center - Friend Chase`

Promotional text candidates:

| Locale | Text |
|---|---|
| `en-US`, `en-GB`, `en-AU`, `en-CA` | `Chase friends, unlock achievements, and climb fair Game Center leaderboards in quick retro races.` |
| `es-ES` | `Persigue amigos, desbloquea logros y sube en clasificaciones justas de Game Center en carreras retro rápidas.` |
| `es-MX` | `Persigue amigos, desbloquea logros y sube en clasificaciones justas de Game Center en carreras retro rápidas.` |
| `ca` | `Persegueix amistats, desbloqueja assoliments i puja en classificacions justes de Game Center en carreres retro ràpides.` |

Slide sequence:

| # | English title | Purpose |
|---:|---|---|
| 1 | `Chase Friends On The Road` | Friend avatar marker in live gameplay. |
| 2 | `Race Through Endless Traffic` | Context for visitors who land cold from ads or links. |
| 3 | `Unlock Arcade Achievements` | Achievement breadth and replay goals. |
| 4 | `See Who Is Just Ahead` | Game-over recap gives the next friend target. |
| 5 | `Climb Fair Leaderboards` | Platform and speed-level leaderboard fairness. |

Default product page change:

- The regular seven-slide Screenshot Studio source now uses `Chase Friends On The Road` as slide 5 instead of the broader `Climb the Leaderboards` copy.
- Keep slide 5 in that position for the default page; do not move Game Center into the first three default screenshots unless a Product Page Optimization test proves it beats the gameplay/control/accessibility opening.

Export checklist:

1. Export the default product page screenshots from `AppStore/RetroRapid.screenshotstudio/` for iPhone, iPad, and Mac.
2. Export the Game Center Custom Product Page screenshots from `AppStore/GameCenter/RetroRapidGameCenter.screenshotstudio/` for iPhone, iPad, and Mac.
3. For each source, export all prepared locales: `en-US`, `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, `ca`.
4. Do not export Apple TV or Apple Vision assets for this campaign.
5. In App Store Connect, create the Custom Product Page from the default page if that gives a faster baseline, then replace screenshots and promotional text with the Game Center campaign assets.

Keyword assignment plan:

Assign only narrow replay/social terms. Keep broad acquisition terms on the default product page.

| Locale | Assign to CPP | Keep on default page |
|---|---|---|
| `en-US` | `leaderboard`, `high`, `score`, `overtake` | `arcade`, `racer`, `traffic`, `lanes`, `reflex`, `offline`, `voiceover`, `controller` |
| `en-AU` | `chase`, `leaderboard`, `high`, `score` | `quick`, `watch`, `game`, `ipad`, `mac`, `controller`, `offline` |
| `en-CA` | `scoreboard` | `watch`, `game`, `classic`, `pixel`, `lane`, `mac`, `drive` |
| `en-GB` | Assign none unless current approved keywords contain a strong social/replay term | Keep the default page for generic discovery |
| `es-ES` | `ranking`, `logros`, `record`, `puntuacion` | `coche`, `adelantar`, `reflejos`, `mando`, `infinito`, `conexion` |
| `es-MX` | `ranking`, `logros`, `record`, `puntuacion` | `rebasar`, `reflejos`, `control`, `infinito`, `internet`, `trafico` |
| `ca` | `puntuacio`, `avancaments` | `cotxe`, `reflexos`, `comandament`, `accessibilitat`, `joc`, `velocitat` |

Do not assign `traffic`, `arcade`, `racing`, `retro`, `watch`, or accessibility terms to this CPP. Those visitors need the full default funnel.

Launch log:

Record this when the page goes live:

| Field | Value |
|---|---|
| CPP reference name | `Game Center - Friend Chase` |
| Product page URL | Add after App Store Connect creates it |
| Approval date | Add after review |
| Visible date | Add after enabling visibility |
| Screenshot export batch | Add export date/path |
| Assigned keyword set | Add per locale after publishing |
| Traffic sources | Organic keyword assignment, social link, Apple Search Ads, featuring follow-up |

Measurement cadence:

| When | Check | Decision |
|---|---|---|
| Before publish | Default product page impressions, downloads, conversion rate, App Store Search downloads, relevant keyword ranks | Baseline only; do not judge CPP yet |
| After 5 first-time CPP downloads | CPP impressions, downloads, conversion rate | Metrics are now usable; keep collecting |
| 7 days after usable data | CPP conversion versus default, split by traffic source if available | Only fix obvious asset problems |
| 14 days after usable data | Same metrics plus keyword-routed impressions | Adjust assigned keywords if traffic is irrelevant |
| 28 days after usable data | Conversion, downloads, keyword traffic quality, proceeds per 1,000 impressions | Decide keep, revise, expand traffic, or disable |

Modification rules:

- If CPP conversion is higher than default but impressions are low, keep the page and send more qualified traffic through the URL or Apple Search Ads.
- If CPP impressions are high but conversion is lower than default by roughly 20% or more after 100+ impressions, revise slide 1 or promotional text first.
- If keyword-routed traffic is low, change keyword assignment before changing screenshots.
- If keyword-routed traffic converts poorly, move that keyword back to the default page.
- If the page performs well, keep the URL stable and create future edits as App Store Connect page revisions; do not delete the page.
- If the page has fewer than five first-time downloads after 28 days, treat it as an external-traffic problem, not a creative verdict.

Helm CLI note:

- Helm can inspect app/version state and upload standard version screenshots/localizations.
- The installed CLI does not currently expose a first-class Custom Product Page or Product Page Optimization command branch, so create the Custom Product Page in App Store Connect UI or via a dedicated App Store Connect API workflow unless Helm adds that branch.
- If using Helm for standard media uploads, prefer `/Applications/Helm.app/Contents/Helpers/helm-asc`; the `/usr/local/bin/helm-asc` symlink aborts on some version-scoped screenshot/localization commands in this environment.
