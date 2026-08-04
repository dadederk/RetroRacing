# SharePlay Release Campaign

Last updated: 2026-07-25

**Status:** `READY_FOR_ASC` — SharePlay promo package implemented in repo (fixtures, metadata, screenshots, microsite, featuring + IAE copy). Submit featuring nomination and In-App Event in App Store Connect when launch week is set. Custom Product Page and App Preview deferred.

**Doc ownership:** Campaign strategy, nomination copy, In-App Event metadata, product-page asset plan, and microsite copy candidates live here. Shipped behavior remains in [`../../Requirements/shareplay_multiplayer.md`](../../Requirements/shareplay_multiplayer.md). Canonical staged App Store metadata is [`../../AppStore/metadata/retrorapid-v1.6.json`](../../AppStore/metadata/retrorapid-v1.6.json); the 1.5 catalog remains a historical snapshot.

**See also:** [Submitted nominations voice guide](09-featuring-nominations-submitted.md) · [Product Page Optimization](../../AppStore/docs/09-product-page-optimization.md) · [Screenshots](../../AppStore/docs/06-screenshots.md) · [Submission gate](../../AppStore/docs/03-submission-quality-gate.md)

## Purpose

Plan a bigger release moment for RetroRapid!'s SharePlay competitive mode: live 2-player races on iPhone and iPad where **friend races are free** and never consume daily plays.

## Release Positioning

Primary hook:

```text
Race friends live. Friend races are free.
```

Support points:

- Live 2-player SharePlay races on iPhone and iPad.
- System SharePlay invite flow from **Play with Friends**.
- Synchronized countdown and host-selected shared speed.
- Live friend score and lives during the round.
- First player to crash can watch the friend finish.
- Mirrored win/loss/tie result with both scores.
- Rematch starts only after both players confirm.
- SharePlay matches never use daily plays, even at zero remaining free plays.
- Each player still submits their own score through Game Center.

Do not claim:

- More than 2 players.
- macOS, watchOS, tvOS, or visionOS SharePlay support in v1.
- Game Center real-time multiplayer; this update uses SharePlay/GroupActivities.
- A free solo unlimited-play window unless a separate `SpecialEventService` window is intentionally added.

## Release Shape

Recommended package:

| Surface | Recommendation |
|---|---|
| App update | Feature-led version release for iOS/iPad, with macOS copy kept accurate. |
| In-App Event | `Friend Race Week`, attached to the featuring nomination once approved or published. |
| Featuring nomination | Primary `App Enhancements`; mention the In-App Event as the campaign wrapper if it is ready. |
| Default product page | Keep gameplay/control/accessibility first; add SharePlay copy in iOS description and What's New. |
| Custom Product Page | **Deferred** this pass — default page + featuring nomination carry SharePlay story. |
| App Preview | **Deferred** this pass. |
| Microsite | Update `BlogDadederk` RetroRapid app page and publish a short release post. |

## In-App Event Candidate

Apple constraints checked 2026-07-23 from Apple Developer docs:

- Event name: 30 characters.
- Short description: 50 characters.
- Long description: 120 characters.
- Publish date can be at most 14 days before event start.
- Event can run up to 31 days.
- In-App Events are available for iPhone and iPad apps, matching SharePlay v1 scope.

Recommended setup:

| Field | Candidate |
|---|---|
| Reference name | `SharePlay Friend Race Week 2026` |
| Badge | `Competition` |
| Backup badge | `Major Update` if review treats SharePlay as a feature launch rather than event competition. |
| Event name | `Friend Race Week` |
| Short description | `Race friends free with SharePlay` |
| Long description | `Start a SharePlay race, dodge traffic together, and rematch without using daily plays.` |
| Purchase required | No |
| Priority | High during launch week |
| Platforms | iPhone, iPad |
| Countries/regions | All current App Store availability unless support load argues for a smaller first wave. |

Copy counts:

| Field | Count | Limit |
|---|---:|---:|
| Event name | 16 | 30 |
| Short description | 32 | 50 |
| Long description | 86 | 120 |

Open decision:

- Keep the event as **friend races are always free**, or add a temporary solo unlimited-play window through `DateRangeSpecialEventService`. The cleanest story is the always-on SharePlay exception; the bigger festival story is temporarily opening solo play too.

## Featuring Nomination

Primary nomination:

| Field | Value |
|---|---|
| Nomination name | `RetroRapid! - Free SharePlay Friend Races` |
| Type | `App Enhancements` |
| Publish date | Choose a 3-7 day launch window after build approval is likely. |
| In-App Event intent | Yes, if `Friend Race Week` is approved or at least in a reliable review state. |
| Platforms | iOS (iPhone), iOS (iPad) |
| Supplemental materials | App Store product page, microsite release post, short SharePlay demo video, press kit folder if ready. |

Description candidate (884/1,000):

```text
RetroRapid! is a retro LCD-style lane racer built from the ground up for every kind of player. This update turns the chase into a live two-player race with SharePlay on iPhone and iPad.

Tap Play with Friends, invite someone through the system SharePlay flow, then start a synchronized countdown. Both players race the same host-selected speed, see live score and remaining lives, wait while a friend finishes if they crash first, and get the same win, loss, or tie result with both final scores. Rematches require both players to confirm, so the shared session feels fair and intentional.

The update also makes a generous product choice: friend races are free. SharePlay matches never consume daily plays and remain available even when a player has reached the solo free-play limit. Each player still submits their own score to Game Center, keeping the existing leaderboards honest.
```

Helpful Details candidate (402/500):

```text
Editor quick test: 1) On iPhone/iPad, tap Play with Friends and invite a second device through SharePlay. 2) Watch the synchronized countdown and live friend score/lives HUD. 3) Crash on one device first; it waits while the friend keeps racing. 4) Finish both runs, compare mirrored results, tap Play Again on both devices, then try again with zero daily plays remaining: friend races still start free.
```

Optional closer if there is room after final edits:

```text
A share of proceeds supports AMMEC, advancing autonomy and social inclusion for people with physical disabilities.
```

## App Store Metadata Candidates

Do not edit [`../../AppStore/docs/05-metadata-copy.md`](../../AppStore/docs/05-metadata-copy.md) directly; update `retrorapid-v1.6.json` and regenerate when these are approved.

Recommended iOS promotional text (125/170):

```text
Race friends free with SharePlay on iPhone and iPad. Dodge traffic together, rematch fast, and keep solo runs quick anywhere.
```

Recommended macOS promotional text:

```text
Dodge traffic and chase high scores in quick retro races, with Game Center, Apple Watch support, and accessibility-first controls.
```

Recommended iOS description additions:

```text
- Live two-player SharePlay races on iPhone and iPad
- Friend races are free and never use daily plays
```

Recommended What's New:

```text
Race friends live with SharePlay.

Tap Play with Friends on iPhone or iPad, start a synchronized countdown, dodge traffic together, and compare the same win, loss, or tie result at the end. Rematches wait until both players are ready.

Friend races are free and never use daily plays, even when your solo free plays are used up.
```

Metadata policy:

- Leave app name and subtitle unchanged for this release unless keyword baseline data strongly supports a change.
- Prefer In-App Event, screenshot, Custom Product Page, promotional text, and What's New for SharePlay messaging.
- Add `SharePlay`/`multiplayer` to hidden keywords only after checking current rank baselines and avoiding duplicate loss in cross-localization sets.
- Keep macOS metadata accurate; SharePlay v1 is iPhone/iPad only.

## Product Page And Screenshots

Default product page:

- iPhone/iPad: **10 slides** — funnel (0–3), SharePlay (4), Game Center leaderboards (5), customize settings (6), pocket aesthetic (7), achievements (8), free-tier menu (9). See [`../../AppStore/docs/06-screenshots.md`](../../AppStore/docs/06-screenshots.md).
- Mac: **9 slides** — same story minus SharePlay; achievements + menu at indices 7–8.
- Apple Watch: **5 slides** — sequence-only, no SharePlay overlays.
- Keep Apple Watch, Mac, accessibility, privacy, and no-data-collection proof visible elsewhere in the page.

SharePlay Custom Product Page candidate:

| # | Title | Body |
|---:|---|---|
| 1 | `Race Friends Live` | `Start a free SharePlay race on iPhone or iPad.` |
| 2 | `Countdown Together` | `Both players start from the same three-second countdown.` |
| 3 | `Watch The Friend Score` | `See score and lives update while you race.` |
| 4 | `Crash First? Keep Watching` | `Wait while your friend finishes the run.` |
| 5 | `Rematch When Ready` | `Both players confirm before the next race starts.` |

Custom Product Page setup:

- Reference name: `SharePlay - Friend Races`
- Promotional text: use the iOS SharePlay promotional text above.
- Keyword assignment: narrow social terms only (`friend`, `score`, `leaderboard`, `high`, `overtake` where available); keep broad racing/accessibility terms on the default page.
- Deep link: optional, only if the app can route safely to the menu or Play with Friends entry point.

App Preview storyboard:

| Time | Beat |
|---|---|
| 0-4s | Menu shows **Play with Friends** and free footer. |
| 4-8s | SharePlay invite/session start. |
| 8-12s | Synchronized countdown. |
| 12-18s | Live racing with friend score/lives visible. |
| 18-23s | One player crashes; waiting state shows friend still racing. |
| 23-28s | Result sheet and **Play Again** handshake. |

## Microsite And BlogDadederk

**Status:** Done (2026-07-25) in `BlogDadederk/AccessibilityUpTo11/AppsData/retrorapid.json`.

Target file:

- `/Users/dadederk/Developer/BlogDadederk/AccessibilityUpTo11/AppsData/retrorapid.json`

Shipped updates:

- Hero/subtitle: SharePlay-aware line (`Race friends live. Retro lanes, real speed.`).
- Description: SharePlay on iPhone/iPad; tvOS/visionOS promises removed.
- **Race Friends Live** feature card added.
- Game Center and controller features no longer say "coming soon".
- Platforms: watchOS, iOS, iPadOS, macOS only.

Release post outline:

1. Why live racing belongs in a tiny retro lane racer.
2. How SharePlay works: invite, countdown, race, result, rematch.
3. Why friend races are free.
4. How accessibility carries into multiplayer: clear overlays, friend wording, score/lives information, reduced disruption.
5. Download link and request for App Store reviews.

## ASC Submission Package

Copy below is ready to paste when launch week is set. Submit the featuring nomination ≥3 weeks before launch; create the In-App Event at T-2 weeks (publish date ≤14 days before event start).

### Featuring nomination

| Field | Paste |
|---|---|
| Nomination name | `RetroRapid! - Free SharePlay Friend Races` |
| Type | App Enhancements |
| Platforms | iPhone, iPad |
| In-App Event intent | Yes — attach `Friend Race Week` when media is ready |
| Description | See § Featuring Nomination (884/1,000) |
| Helpful Details | See § Featuring Nomination (402/500) |

### In-App Event — Friend Race Week

| Field | Paste |
|---|---|
| Reference name | `SharePlay Friend Race Week 2026` |
| Event name | `Friend Race Week` |
| Badge | Competition (backup: Major Update) |
| Short description | `Race friends free with SharePlay` |
| Long description | `Start a SharePlay race, dodge traffic together, and rematch without using daily plays.` |
| Purchase required | No |
| Platforms | iPhone, iPad |
| Media still needed | 16:9 card + 9:16 detail (see Apple media specs in § Apple Sources) |

### Manual ASC follow-ups

- Set **macOS promotional text** to the non-SharePlay candidate in § App Store Metadata Candidates (Helm apply uses shared iOS-led promo).
- Export localized screenshot overlays after verifying SharePlay slide text fit in Studio.
- CPP and App Preview: **deferred** this pass.

## Timeline

Use absolute dates once the release week is chosen.

| Timing | Work |
|---|---|
| T-5 weeks | Fix non-blocking SharePlay glitch, freeze feature behavior, capture final manual QA notes. |
| T-4 weeks | Finalize nomination, In-App Event copy, screenshot storyboard, demo-video storyboard, microsite copy. |
| T-3 weeks | Submit featuring nomination; Apple recommends at least 3 weeks lead time. |
| T-2 weeks | Submit build and In-App Event; prepare App Store media uploads and release post. |
| T-14 days or later | Set event publish date once it is within Apple's 14-day pre-start window. |
| Launch week | Release app, publish event, update microsite, share demo, monitor reviews/support. |
| T+7/T+14/T+28 | Check conversion, event metrics, keyword ranks, reviews, and crash/support signals. |

## Go/No-Go Checklist

- [x] Manual 2-device SharePlay lifecycle QA passed.
- [ ] Non-blocking glitch triaged and either fixed or documented as known low-risk polish.
- [x] `swift test --package-path Scripts` passes.
- [x] `swift run --package-path Scripts run-tests` passes.
- [ ] Release build uploaded to TestFlight and smoke-tested on iPhone and iPad.
- [x] iOS metadata updated (description + SharePlay promo; **apply macOS promo manually in ASC** — shared JSON promo is iOS-led; use macOS candidate in § App Store Metadata Candidates).
- [x] Default screenshot storyboard expanded to 10 slides (iPhone/iPad) with SharePlay, achievements, and menu fixtures.
- [x] BlogDadederk microsite copy updated (`AccessibilityUpTo11/AppsData/retrorapid.json`).
- [x] New screenshot base captures exported (`./retrorapid screenshots capture --slides 4,8,9` iPhone; Mac `7,8`).
- [ ] In-App Event media prepared: 16:9 card and 9:16 detail media (copy ready in § In-App Event Candidate).
- [ ] Featuring nomination submitted at least 3 weeks before target launch (copy ready in § Featuring Nomination).
- [ ] SharePlay screenshot assets checked for text fit in all target locales.
- [ ] Support/review monitoring window assigned for launch week.
- [ ] Custom Product Page — **deferred** this pass.
- [ ] App Preview — **deferred** this pass.

## Measurement

Baseline before release:

- Product page impressions and conversion by storefront.
- App Store Search downloads and top keywords.
- Current Game Center/social Custom Product Page metrics if live.
- Ratings/review count and sentiment.
- Daily active users and play-limit/paywall events if available locally.

Measure after release:

- In-App Event impressions, event page views, opens, downloads, proceeds, and sales after the event reaches Apple's privacy threshold.
- iOS product page conversion versus pre-launch baseline.
- Custom Product Page conversion once it reaches at least five first-time downloads.
- App Store review mentions of SharePlay, multiplayer, free friend races, glitches, or confusion.
- SharePlay support issues: invite failures, disconnects, rematch confusion, daily-play misunderstanding.

## Apple Sources

- [Offer In-App Events](https://developer.apple.com/help/app-store-connect/offer-in-app-events/offer-in-app-events)
- [In-App Event badges](https://developer.apple.com/help/app-store-connect/reference/in-app-events/in-app-event-badges/)
- [In-App Event media specifications](https://developer.apple.com/help/app-store-connect/reference/in-app-events/in-app-event-media-and-audio-specifications/)
- [Nominate your app for featuring](https://developer.apple.com/help/app-store-connect/manage-featuring-nominations/nominate-your-app-for-featuring/)
- [Custom Product Pages](https://developer.apple.com/app-store/custom-product-pages/)
