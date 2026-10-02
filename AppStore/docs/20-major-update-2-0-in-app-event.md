# RetroRapid! 2.0 Major Update In-App Event

This is the operational brief for the 2.0 launch event. It highlights the arrival of permanent SharePlay friend races and iPhone Duo tabletop play during a bounded launch window.

## App Store Connect state

| Field | Value |
|---|---|
| App and account | RetroRapid `6758641625`, AccessibilityUpTo11 |
| Event ID | `6818452317` |
| Event state | `WAITING_FOR_REVIEW` on 2026-10-02 |
| Primary locale | `en-US`; localization ID `521c30df-b3fa-46aa-a307-a95fba1a439c` |
| Badge | **Major Update**, confirmed in App Store Connect |
| Purpose / priority | Appropriate for all users / Normal, confirmed in App Store Connect |
| In-App Purchase required | No; friend races are free and do not use daily solo plays |
| Deep link | `https://accessibilityupto11.com/apps/retrorapid/open/` is saved; cold/warm device test remains |
| Scheduled window | Discoverable from 2026-10-16 11:52 UTC; event starts 2026-10-23 11:52 UTC and ends 2026-11-13 12:52 UTC. Shift if 2.0 availability slips. |

The en-US event localization is stored in App Store Connect:

| Field | Copy | Limit |
|---|---|---:|
| Name | RetroRapid! 2.0: Race Friends | 30 |
| Short description | Free SharePlay races and iPhone Duo play | 50 |
| Long description | Race a friend live with SharePlay for free, then try iPhone Duo’s tabletop arcade layout in RetroRapid! 2.0. | 120 |

The event tells users about significant new features, which fits [Apple's Major Update badge](https://developer.apple.com/help/app-store-connect/reference/in-app-events/in-app-event-badges/). The limited window is the 2.0 launch moment; the features remain available afterward. This follows Xarra's accepted Major Update precedent. Keep the nomination focused on the SharePlay feature and link this event once its reviewable package is complete.

## Media and localization

- The matching 1920 × 1080 [event card](../in-app-events/major-update-2-0/media/event-card.png) and 1080 × 1920 [details image](../in-app-events/major-update-2-0/media/details-page.png) are uploaded to the en-US event localization. They use the pixel-art treatment of RetroRapid's earlier Miami event and social visuals, with the real 16-bit car sprite as a design reference. Two equal racers share one road to represent free SharePlay friend races. These are illustrations, not in-game screenshots; there are no device frames or fabricated controls.
- The Duo tabletop layout remains in event copy until physical device capture and hinge behavior are verified. The waiting-for-friend overlay is not used as the hero.
- Check App Store Connect crops and overlays. Avoid baked-in event text and misleading device UI.
- The 19 non-primary event localizations and native review remain open. The en-US copy is the fallback until they are ready.

## Blockers and next actions

1. Restore a working Duo visual capture or test hardware. On October 2, both the running app and the simulator Home screen captured as black in the iOS 27.1 beta runtime. Unit tests passed, but the layout and hinge interaction are not visually approved.
2. Decide whether the October 16 advance discoverability is intended. Apple permits an event card to appear before its October 23 start, but the 2.0 update must be ready by the event start; move the schedule if the build slips.
3. Test the saved deep link on a device. The app currently handles `/apps/retrorapid/open/` and lands at the game menu, where Play with Friends is visible.
4. Monitor event review. Once approved, attach event `6818452317` to the submitted featuring nomination if it was not attached at submission. Apple does not allow attaching an event until it is approved or published.

Apple's [event setup instructions](https://developer.apple.com/help/app-store-connect/offer-in-app-events/offer-in-app-events) specify the 30/50/120-character copy limits, media, deep link, and schedule. See the [2.0 release plan](../../Plans/aso/11-release-2-0-duo-shareplay.md) for the build and App Review path.
