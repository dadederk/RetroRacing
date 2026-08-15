# Alternate App Icon Concept Assets

These files are the selected art-direction concepts for [the alternate app icon plan](../../alternate_app_icon_plan.md). Theme concepts remain non-runtime references. The app-icon generator uses the two selected Special Edition v4 PNGs as canonical Default sources and their v5 Dark companions as canonical charcoal-material sources, copying those bytes into the matching `.icon` packages.

Only the current selection is retained. Earlier generated revisions were removed from the repository on 2026-08-13 so that this directory cannot be mistaken for a version archive.

## Selected Set

The shipped Classic icon remains outside this directory at [`Icon/appstore1024.png`](../../../Icon/appstore1024.png). The selected alternates are:

| Icon | File | Defining direction |
|---|---|---|
| Pocket | [`pocket-v4.png`](pocket-v4.png) | Four-tone LCD treatment with the preferred interrupted center marker. |
| LCD | [`lcd.png`](lcd.png) | Pastel-beige LCD playfield and the canonical monochrome LCD character. |
| Cartridge | [`cartridge-v5.png`](cartridge-v5.png) | Hard 8-bit artwork on the corrected grey-and-yellow four-path road. |
| CRT | [`crt-v2.png`](crt-v2.png) | 16-bit arcade treatment with the approved grass, asphalt, and yellow-road palette. |
| Disc | [`disc-v4.png`](disc-v4.png) | Late-1990s rendered artwork with aqua road markers and deep-teal exterior. |
| Polygon | [`polygon-v3.png`](polygon-v3.png) | Low-poly character with four white road paths and restrained aqua accents. |
| Retro Cartridge | [`retro-cartridge-v4.png`](retro-cartridge-v4.png) | Full-frame cream cartridge, printed RetroRapid! label, original accessibility seal, and gold connector pins. |
| Retro Video Game | [`retro-video-game-v4.png`](retro-video-game-v4.png) | Full-bleed cream handheld, system-pink controls, and an LCD game screen made from shipped sprites on a coherent projected curve. |
| Retro Cartridge Dark | [`retro-cartridge-dark-v5.png`](retro-cartridge-dark-v5.png) | Material-aware charcoal cartridge companion with dimensional molding and unchanged pink/gold hierarchy. |
| Retro Video Game Dark | [`retro-video-game-dark-v5.png`](retro-video-game-dark-v5.png) | Material-aware charcoal handheld companion with dimensional molding and unchanged LCD/pink/navy hierarchy. |

[`nine-icon-ios27-mask-preview.png`](nine-icon-ios27-mask-preview.png) shows Classic and all eight selected alternates under the continuous-corner silhouette extracted from the supplied iOS 27 Photoshop template.

## Supporting References

- [`road-geometry-reference.png`](road-geometry-reference.png) records the shared renderer-derived perspective used to correct the road paths.
- [`ios-27-icon-mask.png`](ios-27-icon-mask.png) is the tracked `1024×1024` validation mask extracted from the supplied `App Icon Template.psd`.
- [`sketch-tabletop-source.png`](sketch-tabletop-source.png) is the user's source sketch for Retro Cartridge.
- [`sketch-handheld-source.png`](sketch-handheld-source.png) is the user's source sketch for Retro Video Game.
- [`special-editions-ios27-mask-preview.png`](special-editions-ios27-mask-preview.png) checks both hardware icons against the same template-derived mask on a contrasting background.
- [`special-editions-ios27-mask-dark-preview.png`](special-editions-ios27-mask-dark-preview.png) verifies the approved v5 Dark companions under the template mask, including charcoal material depth, app-pink accents, label/LCD content, navy details, and connector contacts.

These are references or validation artifacts, not alternate icon variants.

## Shared Art Direction

All selected PNGs are opaque, unmasked `1024×1024` sources. The operating system applies the final icon mask. Validation uses the exact continuous-corner silhouette extracted from the supplied iOS 27 Photoshop template. Its flatter top and side runs and earlier, slope-continuous shoulder transition supersede the earlier `n = 5` approximation; ordinary circular-radius rounded rectangles remain invalid references.

The theme icons use the game renderer's projected road grammar. Production Pocket preserves the approved three-path interrupted-center layout; LCD, Cartridge, and CRT use four broad boundary paths. For each icon, all paths and both road edges share one vanishing point, continue from the top through the lower edge, and widen and spread toward the viewer. This keeps boundaries visible around and below the car instead of collapsing them into its silhouette. Production Cartridge keeps the exact shipped 8-bit iPad car above cool-grey Default or charcoal-blue Dark surfaces, retaining its characteristic yellow marks in both appearances. Production CRT keeps the exact shipped 16-bit iPad car above green-and-navy Default or green-grey-and-charcoal Dark surfaces; its two outer yellow path centers sit just inside the projected road edges instead of straddling the off-road boundary. A separate full-canvas frontmost layer applies scanlines, a faint phosphor highlight, and a radial vignette over car and road; Dark keeps the effect but reduces scanline strength while concentrating the vignette at the perimeter.

Each theme retains its own canonical road, marker, and exterior colors. Critical characters, labels, controls, and screen content remain inside the central mask-safe region; full-bleed backgrounds and hardware shells may be cropped by the system mask.

## Special-Edition Direction

### Retro Cartridge

The object is a fictional vintage game cartridge, not a console or display. Its matte molded cream shell fills every source corner so the operating-system mask becomes the outer cartridge contour. The raw boundary omits near-white highlights, while the cream bevel and app-pink echo follow centered, evenly inset descendants of the tracked iOS 27 mask. Their shoulders begin turning where the system contour turns instead of following an unrelated corner radius; this prevents Composer and system antialiasing from amplifying the shell into a pale rim.

The interior treats that curve as a playful construction system: the vent, label surround, and connector are horizontally compressed descendants of the same continuous-corner geometry, while the side ribs step with the outer shoulders. These repetitions stay subordinate to the printed artwork. App-pink accents remain secondary, and the bottom edge exposes one neat row of classic gold connector pins. The large front element is visibly a printed paper label with ink/paper texture rather than glass.

The label contains the single title `RetroRapid!`, a rear-view open-wheel racer, the same four renderer-aligned road paths used by the game, and an original gold certification-style medallion reading `Accessibility up to 11!`. The seal evokes period game packaging without reproducing Nintendo's name, wordmark, wording, typography, or exact seal geometry. Label text, car, seal, and the central connector contacts remain safe under normal iOS/iPadOS masks; only expendable edge detail may trim under the deliberately aggressive validation crop.

### Retro Video Game

The fictional handheld uses matte cream molded plastic as the full-bleed icon surface, with no pale boundary highlight, dark exterior wedges, or closed perimeter outline. Its restrained outer bevel follows the tracked iOS 27 mask, while the navy screen bezel and lower control tray are centered, horizontally compressed descendants of the same continuous-corner construction. Smaller molded wells repeat that logic around the D-pad and paired buttons; a thin app-pink echo connects the lower geometry to the controls without competing with the screen. The system mask therefore becomes the console's outer silhouette instead of clipping a second rounded object. Its screen, system-pink D-pad and buttons, speaker/status slots, and controls remain visible under the template mask. The screen resembles RetroRapid! gameplay through its assets and geometry rather than through a title or HUD.

The final screen is a deterministic composite, not a generated approximation. It uses these exact shipped iPad assets without altering their internal pixels:

- `RetroRacingShared/Assets.xcassets/Sprites/LCD/playersCar-LCD.imageset/playersCar-LCD-ipad.png`
- `RetroRacingShared/Assets.xcassets/Sprites/LCD/rivalsCar-LCD.imageset/rivalsCar-LCD-ipad.png`, used twice at a smaller scale

The warm-beige playfield and four warm-grey boundary paths follow the renderer contract. The road takes one gentle right-hand bend into the distance: all four path centers derive from the same projected curve, every dash is tangent to its path, and dash length, width, and spacing increase toward the viewer. There is no center path, scenery, score, title, button lettering, real-console branding, or other tiny text.

## Provenance

- Concepts were generated and revised on 2026-08-12 and 2026-08-13 with the built-in ImageGen workflow, then mechanically normalized to opaque `1024×1024` PNGs.
- Retro Video Game's final in-screen composition was assembled deterministically from repository assets after the hardware concept was generated.
- Both special-edition edge treatments are validated with the tracked mask extracted from the supplied iOS 27 Photoshop template. Inset contours are assessed against centered constant-distance or compressed descendants of that silhouette rather than an assumed superellipse exponent.
- On-device review on 2026-08-14 identified a pale perimeter amplified by the special packages' stronger Composer translucency. The final sources use matte boundary pixels and inset concentric highlights, while both packages match the theme icons' restrained `0.05` translucency.
- The 2026-08-14 playful-concentricity pass reworked only the hardware architecture. Retro Video Game's approved LCD composition was restored deterministically after the shell exploration so generated car interpretations did not enter the final screen.
- The 2026-08-14 road-perspective edit used the built-in ImageGen workflow to establish the intended bend, then rebuilt the four paths deterministically so the final screen has one shared projection and retains the exact shipped cars. The edit prompt was: “Keep the gentle bend; make all four dashed boundaries follow the same smooth projected curve; place each dash on and tangent to its path; grow dash length, width, and spacing toward the viewer; preserve the handheld hardware, LCD palette, and cars.”
- The 2026-08-14 template-concentricity pass used the built-in ImageGen edit workflow with each Special Edition as its edit target and the supplied Photoshop template as the geometry reference. The prompt kept each icon's label, gameplay, controls, palette, and text invariant while rebuilding the outer shell, molded bevels, pink echoes, screen/label surrounds, and control tray around the template's continuous-corner shoulders. Exact shipped LCD car sprites were composited back over the handheld result before promotion.
- The 2026-08-14 package pilot adopted both Special Edition v4 PNGs unchanged as runtime Default artwork. An initial procedural recolour preserved pixels but flattened the molded lighting, so it was retired after visual review. The final v5 Dark companions were regenerated with the built-in ImageGen edit workflow from the approved Default and initial Dark references, then normalized to opaque `1024×1024` PNGs. The edit locked the hardware composition and protected the label or LCD game, system-pink/navy accents, seal, and connector while re-rendering only the charcoal plastic's grain, bevel illumination, recesses, and depth.
- `./retrorapid assets app-icons` copies the approved v4 Default and v5 Dark files into their packages instead of procedurally tinting either appearance. Each package uses one stable layer with flat Default, Dark, and Tinted image-name specializations; the generator also creates matching adaptive gallery previews. This preserves deterministic runtime output while allowing material-specific Dark rendering.

### Dark v5 ImageGen prompts

Retro Cartridge:

> Improve only the graphite shell material in the exact Dark icon composition. Re-render the existing dark-grey cartridge molding as premium charcoal injection-molded plastic with realistic material-specific studio highlights, fine subtle grain, lit bevels, soft recessed shadows, and clear dimensional separation. Remove the flat tinted or painted-over look. Lock the outer silhouette, concentric continuous-corner contours, label aperture, top and side vents, connector, proportions, full-bleed crop, and safe margins. Change only the molded shell plastic. Preserve the full pink printed label, `RetroRapid!` typography, car, road and every lane mark, `Accessibility up to 11!` seal, pink vent and piping, black borders and recesses, and gold connector contacts. Avoid composition drift, flat recolouring, muddy surfaces, heavy repeating texture, pale edge artefacts, halos, and corner clipping.

Retro Video Game:

> Improve only the graphite console-body material in the exact Dark icon composition. Re-render the existing dark-grey molding as premium charcoal injection-molded plastic with realistic material-specific studio highlights, fine subtle grain, lit bevels, soft recessed shadows, and clear rounded depth. Remove the flat tinted or painted-over look. Lock the outer continuous-corner silhouette, screen aperture, navy bezel, lower control tray, control positions, proportions, full-bleed crop, concentric geometry, and safe margins. Change only the molded console plastic. Preserve the warm monochrome LCD, three pixel-art cars, correctly converging road and continuous dashed lane marks, navy bezel and speaker details, pink D-pad and buttons, and thin pink piping. Avoid composition drift, altered gameplay, displaced controls, flat recolouring, muddy surfaces, cream remnants, glossy black glass, pale edge artefacts, halos, and corner clipping.

- Generated theme characters remain close art-direction interpretations unless a note above identifies exact shipped assets. Production Icon Composer packages should replace interpretations with their canonical curated artwork where needed.
- No transparency or chroma-key processing was requested.
