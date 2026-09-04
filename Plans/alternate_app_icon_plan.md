# Alternate App Icons Plan

**Status:** In progress — Pocket/LCD/Cartridge/CRT/Disc layered pilot and approved Special Edition appearances implemented; Polygon and full appearance/device QA remain open
**Created:** 2026-08-12

**See also:** [Monetization](../Requirements/monetization.md) · [Theming](../Requirements/theming_system.md) · [Accessibility](../Requirements/accessibility.md) · [Localization](../Requirements/localization.md) · [Testing](../Requirements/testing.md)

## Goal

Let people with **Unlimited Plays** choose a RetroRapid! app icon without creating a second purchase or a new user-facing premium tier.

The feature should feel like a collectible cosmetic benefit while keeping the existing pink icon as **Classic**, the default icon. Icon selection is independent from gameplay Style selection: changing a Style must not silently change the Home Screen icon, and changing the icon must not change gameplay.

## Recommendation

- Ship the chooser first on iPhone and iPad, where Apple provides a persistent alternate-icon API and RetroRapid! is publicly available.
- Keep the current shipped artwork as the Classic primary icon and offer nine alternates: one for each gameplay theme (Pocket, LCD, Cartridge, CRT, Disc, and Polygon) plus three special icons (Retro Cartridge, Retro Video Game, and Retro Game Box).
- Unlock alternate selection with the existing Unlimited Plays entitlement. The primary icon remains selectable by everyone.
- Let free users inspect the gallery. Selecting a locked alternate presents the existing Unlimited Plays paywall only after entitlement resolution; it never creates a separate purchase.
- Never auto-sync the icon with the selected gameplay Style. A system-level icon change should always follow a deliberate user tap.
- Do not automatically replace an already-selected alternate after an entitlement refund, debug revocation, or rollout-flag change. Lock further alternate changes but always allow returning to Classic; this avoids an unsolicited system icon-change alert on launch.
- Bundle every package in Debug and Release. Expose the gallery only behind `debugGameplay.alternateAppIconsEnabled`, which defaults on for fresh Debug installs, respects a stored Debug override, and is forcibly false outside Debug features.
- Treat the theme PNGs in this plan as art-direction concepts; production Pocket/LCD/Cartridge/CRT/Disc use exact curated theme car artwork. Disc additionally derives a transparent circuit-environment layer from its approved concept. Retro Cartridge uses its approved neutral-grey v5 Default and charcoal v5 Dark sources; Retro Video Game uses its approved v4 Default and separately rendered charcoal-material v5 Dark companion.

## Concept Set

All concept PNGs are unmasked, opaque `1024×1024` sources. The system, not the artwork, should apply the final icon mask. Shape validation uses the tracked mask extracted from the supplied iOS 27 Photoshop template, including its flatter top/side runs and early continuous-corner shoulder transition. Only the selected final concept for each catalog entry remains in the asset folder; superseded revisions are intentionally excluded.

The ten-icon catalog starts with Classic, then one icon for each of RetroRapid's six gameplay themes, followed by three Special Editions. Theme icons share the actual game renderer's projected road grammar. Pocket retains its approved three-path interrupted-center composition while LCD uses four broad boundary paths. Each icon derives every path and both road edges from one shared vanishing point; boundaries run from the top through the lower edge, and marker width, length, and spacing increase toward the viewer. Each icon retains its theme's canonical road, marker, and exterior colors.

| Icon | Role | Concept | Production note |
|---|---|---|---|
| Classic | Primary; free | ![Current Classic icon](../Icon/appstore1024.png) | Keep the shipped pink appearance and stable `nil` API mapping. |
| Pocket | Theme alternate | ![Pocket icon concept](assets/alternate-app-icon-concepts/pocket-v4.png) | Preserve the preferred four-tone LCD treatment and interrupted center marker, with olive road, darker olive marks, and pale yellow-green exterior. |
| LCD | Theme alternate | ![LCD icon concept](assets/alternate-app-icon-concepts/lcd.png) | Keep this distinct from Classic: canonical monochrome LCD car, pastel-beige playfield, warm-grey markers, and four renderer-aligned paths. |
| Cartridge | Theme alternate | ![Cartridge icon concept](assets/alternate-app-icon-concepts/cartridge-v5.png) | Preserve hard 8-bit edges, medium-grey road, bright-yellow markers, lighter-grey exterior, and the same four-path front/behind continuity as CRT. |
| CRT | Theme alternate | ![CRT icon concept](assets/alternate-app-icon-concepts/crt-v2.png) | Preserve the approved green off-road, deep-navy road, yellow lane marks, and four-path perspective; reduce fine scanline detail only if it muddies at Settings size. |
| Disc | Theme alternate | ![Disc icon concept](assets/alternate-app-icon-concepts/disc-v4.png) | Preserve the curated dark-teal v4 artwork as Dark. Default inverts the track hierarchy to a pale aqua road with deep-teal marker paths, retains the circuit-textured exterior, and redraws the canonical 32-bit car above the track. |
| Polygon | Theme alternate | ![Polygon icon concept](assets/alternate-app-icon-concepts/polygon-v3.png) | Preserve the canonical low-poly silhouette, four exhausts, midnight road, four white marker paths, and restrained neon-aqua exterior accents. |
| Retro Cartridge | Special alternate | ![Retro Cartridge icon concept](assets/alternate-app-icon-concepts/retro-cartridge-v5.png) | Copy the neutral-grey v5 source byte-for-byte into Default and the approved [`retro-cartridge-dark-v5.png`](assets/alternate-app-icon-concepts/retro-cartridge-dark-v5.png) into Dark. Both retain the label, vent, trim, seal, connector accents, and mask-concentric hardware composition; Dark uses genuinely rendered charcoal molding. |
| Retro Video Game | Special alternate | ![Retro Video Game icon concept](assets/alternate-app-icon-concepts/retro-video-game-v4.png) | Copy v4 byte-for-byte into Default and the approved [`retro-video-game-dark-v5.png`](assets/alternate-app-icon-concepts/retro-video-game-dark-v5.png) into Dark. Both retain the LCD game, bezel, controls, slots, trim, and mask-concentric hardware composition; Dark uses genuinely rendered charcoal molding. |
| Retro Game Box | Special alternate | ![Retro Game Box icon concept](assets/alternate-app-icon-concepts/retro-game-box-v7.png) | Copy the light-grey/blue/pink v7 cover byte-for-byte into Default and [`retro-game-box-dark-v7.png`](assets/alternate-app-icon-concepts/retro-game-box-dark-v7.png) into Dark. These are deliberately different printings rather than a tint. Both use subtle full-surface cardboard grain, clean uninterrupted square edges, and visible irregular interior scratches. Light retains the upright cobalt wordmark, white/red lozenge, and shared Dark-edition seal. Dark uses a left-flush art panel, slightly overlapping title and teal tagline box, top red tab, smaller inset publisher capsule, right information rail, shared seal, left-shifted `BUILT WITH LOVE BY` footer lockup, and a shorter, subtler striped negative-space accessibility figure with friendly rounded limbs and no neck. |

Source sketches: [Retro Cartridge](assets/alternate-app-icon-concepts/sketch-tabletop-source.png) · [Retro Video Game](assets/alternate-app-icon-concepts/sketch-handheld-source.png) · [Retro Game Box](assets/alternate-app-icon-concepts/sketch-game-box-source.png)

Retro Video Game intentionally omits titles, button letters, scores, and other tiny text. Its monochrome beige LCD screen uses the exact shipped iPad LCD player and rival sprites rather than generated interpretations. Its four road boundaries share one gentle projected bend: dash centers follow their respective curves, dash faces stay tangent to them, and length, width, and spacing increase toward the viewer. Retro Cartridge and Retro Game Box are deliberate printed-packaging exceptions to the no-text rule. Retro Cartridge keeps `RetroRapid!` and the original `Accessibility up to 11!` certification-style seal inside the central mask-safe region, with one neat row of classic gold contacts below. Retro Game Box keeps `RetroRapid!`, `Race like it is 1985`, an original `A11y up to 11!` publisher mark, and the exact gold medallion within the same safe region. Light adds the vertical cobalt wordmark and white/red lozenge; Dark adds the red `ACCESSIBILITY UP TO 11` / `BUILT WITH LOVE BY` footer lockup and horizontally striped negative-space accessibility mark. All period-inspired marks must remain original and must not reproduce Nintendo, Game Boy, Super Nintendo, ESRB, or other third-party names, logos, typography, seal geometry, exact layouts, or trade dress.

Generation provenance and the final prompt set are recorded in [the concept README](assets/alternate-app-icon-concepts/README.md).

## Platform Scope

| Platform | System capability | Plan |
|---|---|---|
| iPhone and iPad | `UIApplication` supports persistent alternate icons. | **v1.** Configure the gallery as eligible. Treat runtime support as an operation guard, not a visibility gate. |
| macOS | AppKit can temporarily change only the Dock tile image; it is not an equivalent persistent app-icon chooser. | Do not expose the feature. Keep visual and behavioral expectations consistent. |
| Apple Watch | The alternate-icon API is unavailable. | Do not expose the feature. |
| Apple TV | UIKit supports alternate icons, but tvOS requires separate rectangular parallax stacks and RetroRapid! is not publicly listed there. | Defer until a public tvOS plan justifies the asset and QA cost. |
| Apple Vision Pro | A compatible iPhone/iPad app can retain alternate-icon behavior, but Apple documents native visionOS SDK apps as unsupported. RetroRapid! has a native target. | Do not expose the feature in the native visionOS app. |

The shared UI is driven by injected platform eligibility so unsupported targets do not need platform checks in shared services or views. UIKit runtime capability remains separately observable for icon-change requests and diagnostics.

## User Experience

### Settings entry

- Add an **App Icon** disclosure row inside Theme, directly after the Style controls, on supported platforms.
- The row value is the current option name, such as **Classic**, **Pocket**, or **Retro Video Game**.
- Hide the entire row unless the injected service reports both iPhone/iPad platform eligibility and an enabled rollout flag. Do not hide it because UIKit temporarily reports no runtime support.
- Do not disable icon changes while a race is active; the setting is cosmetic and does not affect game state.

### Gallery

- Present a native grouped `List` that follows the Style Gallery's interaction and Unlimited Plays prompt patterns.
- Keep catalog and section order stable: Classic; Pocket, LCD, Cartridge, CRT, Disc, Polygon; Retro Cartridge, Retro Video Game, Retro Game Box.
- Mark the current icon with both a checkmark and a localized **Selected** value; never rely on color alone.
- For free users, show a lock on alternates and a concise Unlimited Plays benefit row. Tapping a locked alternate opens the existing voluntary paywall.
- While entitlement state is unresolved, show the gallery without an upsell and disable locked selections with a progress state. This avoids a paywall flash for returning purchasers.
- Selecting the already-active icon is a no-op.
- Selecting Classic passes `nil` to the system API and is always allowed.
- During a change, keep unrelated rows at full contrast and focusable, show a large activity indicator on the requested row, and reject repeated requests in the service.
- On success, update the checkmark from the system-reported current icon. Do not show a second custom success alert because the system already reports the change.
- Keep the full system-request lifecycle in the UIKit adapter. Trust matching reported state even when UIKit withholds or fails its callback, accept a successful system completion when state publication is delayed, and pause the bounded recovery budget while Apple's confirmation keeps the app inactive. The shared service owns observable progress and repeated-request suppression, then refreshes selection from reported system state.
- On failure, keep the previous selection and present a localized error alert.

### Entitlement behavior

| State | Classic | Alternates | Paywall behavior |
|---|---|---|---|
| Unlimited Plays | Selectable | Selectable | None |
| Resolved free user | Selectable | Previewable but locked | Locked tap opens voluntary paywall |
| Entitlement unresolved | Selectable | Previewable; temporarily disabled | No paywall until resolution |
| Entitlement revoked with alternate active | Selectable | Current alternate remains installed; other alternate changes locked | Locked tap opens paywall after resolution |

Use `hasPremiumAccessForGating` for returning-purchaser access and `shouldShowFreeTierAffordances` to decide when an upsell is appropriate.

## Technical Design

### Shared model and policy

Add platform-agnostic shared types:

- `AppIconID` — stable typed identifier for the nine catalog entries.
- `AppIconGroup` — stable Classic, Themes, and Special Editions grouping.
- `AppIconOption` — ID, localized name/description keys, group, preview asset name, and optional system icon name; `nil` identifies the Classic primary icon.
- `AppIconCatalog` — ordered, unique options with stable system names.
- `AppIconSelectionPolicy` — returns no-op, select, wait for entitlement, or present paywall.
- `AppIconChanging` — injected protocol exposing support, the system-reported current name, and an async change operation.

Suggested stable system names:

| Option | System icon name |
|---|---|
| Classic | `nil` |
| Pocket | `RetroRapidPocket` |
| LCD | `RetroRapidLCD` |
| Cartridge | `RetroRapidCartridge` |
| CRT | `RetroRapidCRT` |
| Disc | `RetroRapidDisc` |
| Polygon | `RetroRapidPolygon` |
| Retro Cartridge | `RetroRapidGameCartridge` |
| Retro Video Game | `RetroRapidVideoGame` |
| Retro Game Box | `RetroRapidGameBox` |

Do not rename a shipped system icon name. The operating system owns the selected name, so stable names are compatibility data.

### Platform adapter

- Implement `UIApplicationAppIconChanger` in `RetroRacingUniversal`, not in the shared service layer.
- Map `supportsAlternateIcons`, `alternateIconName`, and the async `setAlternateIconName` API behind `AppIconChanging`.
- Keep the adapter main-actor isolated and surface typed errors to the shared gallery.
- Inject an explicit unsupported implementation from other composition roots. Do not create a business dependency by default inside a view initializer.
- Read the current icon from the system whenever the gallery appears. Do not persist a duplicate UserDefaults selection.

```mermaid
flowchart LR
  gallery["AppIconGalleryView"] --> policy["AppIconSelectionPolicy"]
  entitlement["Unlimited Plays state"] --> policy
  catalog["AppIconCatalog"] --> gallery
  policy --> changer["AppIconChanging protocol"]
  changer --> uikit["UIApplication adapter (iOS/iPadOS)"]
  uikit --> system["Home Screen / Spotlight / Settings"]
```

### Xcode and asset configuration

Apple's current Icon Composer workflow requires one `.icon` package for each alternate. The current eight-package adaptive pilot is intentionally mixed:

1. Pocket, LCD, Cartridge, CRT, and Disc use layered Canvas, foreground Subject, and background World artwork. The Subject keeps the canonical car above the lane marks; the World keeps the road behind both. Pocket's three paths and LCD/Cartridge/CRT/Disc's four paths run through the full canvas and share their icon's true vanishing-point projection. Dark uses separate near-black off-road and road greys tinted subtly toward each Default palette, while lane marks retain each theme's characteristic light color. Each Road and Lane Marks layer uses Icon Composer's flat image-name specialization array to select Default, Dark, and Default-for-Tinted sources. Mono keeps the car fully opaque, lane marks stronger than the road, and the road restrained, producing the hierarchy used by Clear and Tinted. CRT uses a frontmost transparent Accents PNG combining scanlines and a strong radial vignette, ensuring the tube effect visibly covers the finished composition in Icon Composer. Disc adds a transparent circuit-environment layer behind its appearance-specialized road. Nested `slot` specializations are forbidden because Icon Composer silently ignores them.
2. Retro Cartridge keeps the approved neutral-grey v5 PNG byte-for-byte as Default and its approved v5 charcoal-material companion as Dark. Retro Video Game keeps its approved v4 PNG as Default and v5 charcoal-material companion as Dark. Both use the same flat image-name specialization contract on one stable layer. Retro Game Box copies its approved light-grey/blue/pink v7 PNG into Default and its black/red v7 companion into Dark; Tinted maps back to Default. Every Special Edition document canvas explicitly specializes Default, Dark, and Tinted fills. Tinted and Clear are system generated.
3. Polygon remains flattened with one neutral appearance until the layered theme material and appearance recipe passes device QA. Classic remains unchanged.
4. Preserve the existing primary package name `RetroRapid.icon` and the Default appearance's shipped visual parity.
5. Add every alternate name to `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` for Debug and Release. Let Xcode generate `CFBundleIcons` entries; do not hand-maintain those generated keys in `Info.plist`.
6. Generate eight opaque RGB `512×512` Default/Dark gallery preview pairs from the same package sources. Retro Game Box intentionally changes from the light-grey/blue cover to the black/red cover between appearances. Each primary universal single-scale image set exposes both appearances in Xcode. The gallery changes the SwiftUI image view's identity with the color scheme so the adaptive asset is resolved again when a reused list row changes appearance, without duplicating the Dark rendition under another asset name. The high-resolution preview is not treated as an intrinsic `1x` image.
7. Run `./retrorapid assets app-icons` to regenerate sources and previews, `--dry-run` to inspect the plan, and `--check` to enforce deterministic drift without overwriting tracked Composer styling.

Author Default artwork plus Dark and Mono annotations, then let Icon Composer derive the six system presentations: Default, Dark, Clear Light/Dark, and Tinted Light/Dark. Every result must preserve the same core silhouette and remain recognizable. Keep the source artwork square and unmasked, but validate every concept through [`ios-27-icon-mask.png`](assets/alternate-app-icon-concepts/ios-27-icon-mask.png) so critical artwork stays in the central safe region and inset hardware contours remain concentric with the actual continuous-corner crop. Avoid pre-rounded layers, tiny text, excessive baked glow, and baked inter-layer shadows that conflict with system effects.

### Suggested file placement

- `RetroRacing/RetroRacingShared/AppIcon/` — IDs, catalog, selection policy.
- `RetroRacing/RetroRacingShared/Services/Protocols/AppIconChanging.swift` — protocol.
- `RetroRacing/RetroRacingShared/Views/AppIconGalleryView.swift` — shared gallery.
- `RetroRacing/RetroRacingUniversal/AppIcon/UIApplicationAppIconChanger.swift` — UIKit adapter.
- `RetroRacing/RetroRacingUniversal/Assets/RetroRapid*.icon` — compiled Icon Composer packages.
- `Icon/Alternates/` — editable/source exports if retained outside the target.

## Accessibility and Localization

- Give each option a localized name and a concise accessibility description of its visual style.
- Make each list row one accessibility element with its visual description, lock state, and selected state. Hide decorative preview pixels from VoiceOver.
- Preserve a logical reading order matching the visual catalog order.
- At accessibility Dynamic Type sizes, place the preview and state indicator above the wrapping name and cap the decorative preview at 180 points so the row remains navigable.
- Support VoiceOver, Voice Control, Switch Control, Full Keyboard Access, Increase Contrast, Differentiate Without Color, Reduce Transparency, and Reduce Motion.
- Do not encode selection or locked state through color alone.
- Add all new user-visible strings to `Localizable.xcstrings` and localize them across the supported locale catalog.
- Keep text out of theme and hardware-screen artwork so the same icon package works in every locale. Retro Cartridge and Retro Game Box deliberately use fixed English text as period printed-packaging art; localized names and accessibility descriptions provide the locale-aware UI equivalent.

## Monetization and App Store Work

- Reuse `com.accessibilityUpTo11.RetroRacing.unlimitedPlays`; no new product or tier.
- Add alternate icons to the Unlimited Plays benefit copy only while both rollout and iPhone/iPad platform eligibility are enabled, without weakening the primary unlimited-rounds promise.
- No public listing or IAP copy changes ship while Release forces the feature off. When rollout becomes a production decision, update App Store review notes and any screenshots only through [AppStore/README.md](../AppStore/README.md).
- Avoid public claims for macOS, watchOS, tvOS, or native visionOS icon switching.
- All primary, alternate, dark, clear, and tinted icons ship in the binary and remain subject to App Review.

## Validation

### Automated

- Catalog order, uniqueness, stable system-name mapping, and `nil` Classic mapping.
- Selection-policy coverage for entitled, free, unresolved, revoked, current, and Classic cases.
- Debug-default-on flag behavior, stored Debug overrides, immediate UI reaction, and Release isolation from stored state.
- Gallery behavior with success, failure, unsupported service, and repeated taps using injected test doubles.
- Settings row visibility by injected platform eligibility and rollout state, independently from transient UIKit capability.
- Localization-key and asset-presence checks for every catalog entry.
- Existing package, documentation, asset audit, and platform suites remain green.

Recommended gate after implementation:

```bash
./retrorapid assets app-icons --check
./retrorapid test package
./retrorapid assets audit --check
./retrorapid assets audit --full --check
./retrorapid check
./retrorapid test --platform all
./retrorapid docs
```

### Manual iPhone and iPad

- Change from Classic to every alternate and back; verify the system confirmation, selected checkmark, and error recovery.
- Verify Home Screen, App Library, Spotlight, Settings, notifications, share sheets, and post-relaunch state.
- Verify persistence across an app update and expected reset behavior after reinstall.
- Review every icon at small system sizes and in Default, Dark, Clear, and Tinted appearances on light and dark wallpapers.
- Test free, entitled, cold-launch cached entitlement, restored purchase, debug revocation, and refund-like states.
- Run the accessibility matrix listed above with the largest supported text sizes.
- Compare archive size before and after the icon set; optimize source layers if the compiled increase is disproportionate.

### Appearance and cache troubleshooting

- Diagnose the installed icon independently from the in-app gallery. Gallery previews follow the app's color scheme, while SpringBoard applies the Home Screen appearance chosen by the user.
- Before treating an appearance mismatch as package failure, return to Classic, terminate and relaunch the app, select the alternate again, and wait for the system confirmation. If SpringBoard still shows an obsolete rendition after the package changed, remove the app, restart the device when practical, reinstall the current build, and repeat from Classic; this clears system icon caches but also removes local app data.
- Do not create `2x` or `3x` Icon Composer layers. Packages use unmasked `1024×1024` single-scale sources, and gallery imagesets use tracked universal single-scale `512×512` previews that are always rendered below their source dimensions.
- Compare Icon Composer's Default, Dark, and Mono source presentations before checking Clear or Tinted on-device. Clear and Tinted are system-generated, so use several wallpapers and tint colors rather than treating one Home Screen result as authoritative.
- When a selection fails or remains unresolved, capture the narrow diagnostic stream with `log stream --predicate 'eventMessage CONTAINS "APP_ICON_"' --level debug` and record the requested icon name, reported system icon name, app lifecycle state, and whether a clean install changes the result. Never capture wallpaper or unrelated user data.

## Implementation Record

- `Requirements/app_icons.md` is the shipped behavior contract and is routed from `Requirements/INDEX.md`.
- Shared catalog, selection policy, observable service, UIKit adapter, deterministic fakes, Theme-integrated Settings gallery, paywall gating, Debug flag, package declarations, previews, localization, and automated packaging checks are implemented.
- Release bundles all packages but the resolver forcibly hides the gallery and icon-specific paywall copy.
- Pocket, LCD, Cartridge, CRT, and Disc now use deterministic semantic SVG road/lane layers plus transparent canonical SpriteKit cars. Their tracked manifests preserve foreground-to-background ordering, full-height projected boundaries, flat Default/Dark/Tinted image source mappings, Mono (`tinted`) treatments, and no flattened `Default.png`. CRT rasterizes its scanlines and strengthened radial vignette together into the frontmost transparent Accents layer, so the tube falloff remains visible over the finished Composer composition. Disc keeps its approved circuit exterior as a deterministic transparent World layer behind the road.
- Retro Cartridge uses its approved neutral-grey v5 PNG for Default and charcoal-plastic v5 companion for Dark. Retro Video Game uses its approved v4 PNG for Default and charcoal-plastic v5 companion for Dark. Retro Game Box uses its approved light-grey/blue/pink v7 PNG for Default and black/red v7 PNG for Dark. Each package uses one appearance-aware layer. This is a deliberate exception to semantic layering so the approved packaging and material depth remain intact.
- `./retrorapid assets app-icons` copies these canonical sources into the Special Edition packages, owns the generated Pocket/LCD/Cartridge/CRT/Disc layers, derives Disc's transparent circuit environment from the approved concept, and generates all eight adaptive Default/Dark gallery pairs in their canonical image sets. The runtime asset audit verifies package references, geometry, layer order, flat image/opacity appearance specializations, the car/lanes/road Mono hierarchy without freezing manually tuned opacity values, preview appearance metadata, and output drift, while `./retrorapid check` includes the generator's `--check` gate.
- Polygon remains the only flattened neutral alternate in the adaptive pilot. Physical-device icon changes and return-to-Classic behavior are verified; residual work is hands-on six-presentation QA, Polygon's layered conversion, and the full device/accessibility matrix. tvOS remains deferred.

## Effort Estimate

| Work | Estimate |
|---|---:|
| Rebuild and refine the selected ten-icon catalog | 0.5–1 day |
| Complete remaining two theme alternates as layered Icon Composer packages | 1–2 days |
| Shared catalog, policy, gallery, UIKit adapter, and composition-root wiring | 1.5–2 days |
| Unit/UI tests, localization, requirements, and paywall/App Store updates | 1–2 days |
| Appearance, device, entitlement, accessibility, and archive-size QA | 1–2 days |
| **Total** | **6–11 person-days** |

The code cost changes little with icon count; layered art production and appearance QA are the main variable costs. The selected catalog keeps all six theme identities plus three Special Editions, accepting that art and appearance QA cost in exchange for a coherent collectible gallery.

## Deferred Product Decision

- Should a future public tvOS release receive its own rectangular parallax interpretations, or keep this benefit specific to iPhone and iPad?

## Apple References

- [Configuring your app to use alternate app icons](https://developer.apple.com/documentation/xcode/configuring-your-app-to-use-alternate-app-icons)
- [`setAlternateIconName`](https://developer.apple.com/documentation/uikit/uiapplication/setalternateiconname%28_%3Acompletionhandler%3A%29)
- [Creating your app icon using Icon Composer](https://developer.apple.com/documentation/xcode/creating-your-app-icon-using-icon-composer)
- [Human Interface Guidelines: App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons/)
