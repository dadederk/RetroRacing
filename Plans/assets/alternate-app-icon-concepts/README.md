# Alternate App Icon Concept Assets

These files are the selected art-direction concepts for [the alternate app icon plan](../../alternate_app_icon_plan.md). They are not wired into an app target.

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
| Retro Video Game | [`retro-video-game-v4.png`](retro-video-game-v4.png) | Full-bleed cream handheld, system-pink controls, and an LCD game screen made from shipped assets. |

[`nine-icon-rounded-preview.png`](nine-icon-rounded-preview.png) shows Classic and all eight selected alternates under an iOS-style rounded mask.

## Supporting References

- [`road-geometry-reference.png`](road-geometry-reference.png) records the shared renderer-derived perspective used to correct the road paths.
- [`sketch-tabletop-source.png`](sketch-tabletop-source.png) is the user's source sketch for Retro Cartridge.
- [`sketch-handheld-source.png`](sketch-handheld-source.png) is the user's source sketch for Retro Video Game.
- [`retro-video-game-v4-rounded-preview.png`](retro-video-game-v4-rounded-preview.png) checks the handheld at several plausible iOS/iPadOS mask radii.

These are references or validation artifacts, not alternate icon variants.

## Shared Art Direction

All selected PNGs are opaque, unmasked `1024×1024` sources. The operating system applies the final rounded icon mask.

The theme icons use the game renderer's road grammar: four separate dashed boundary paths define three lanes—outer-left, inner-left, inner-right, and outer-right. Each path follows one uninterrupted perspective trajectory behind and in front of the car. Marker length, width, and spacing increase toward the viewer. The road is approximately 38% of the canvas width at the top and 94% at the bottom. Pocket deliberately adds its interrupted center marker as a theme-specific exception.

Each theme retains its own canonical road, marker, and exterior colors. Critical characters, labels, controls, and screen content remain inside the central mask-safe region; full-bleed backgrounds and hardware shells may be cropped by the system mask.

## Special-Edition Direction

### Retro Cartridge

The object is a fictional vintage game cartridge, not a console or display. Its molded cream shell fills every source corner so the operating-system mask becomes the outer cartridge contour; concentric inset bevels make moderate and aggressive rounded masks feel intentional. App-pink accents remain secondary, and the bottom edge exposes one neat row of classic gold connector pins. The large front element is visibly a printed paper label with ink/paper texture rather than glass.

The label contains the single title `RetroRapid!`, a rear-view open-wheel racer, the same four renderer-aligned road paths used by the game, and an original gold certification-style medallion reading `Accessibility up to 11!`. The seal evokes period game packaging without reproducing Nintendo's name, wordmark, wording, typography, or exact seal geometry. Label text, car, seal, and the central connector contacts remain safe under normal iOS/iPadOS masks; only expendable edge detail may trim under the deliberately aggressive validation crop.

### Retro Video Game

The fictional handheld uses cream molded plastic as the full-bleed icon surface, with no dark exterior wedges or closed perimeter outline. The operating-system mask therefore becomes the console's outer silhouette instead of clipping a second nested rounded object. Its screen, system-pink D-pad and buttons, speaker/status slots, and controls remain visible under rounded masks. The screen resembles RetroRapid! gameplay through its assets and geometry rather than through a title or HUD.

The final screen is a deterministic composite, not a generated approximation. It uses these exact shipped iPad assets without altering their internal pixels:

- `RetroRacingShared/Assets.xcassets/Sprites/LCD/playersCar-LCD.imageset/playersCar-LCD-ipad.png`
- `RetroRacingShared/Assets.xcassets/Sprites/LCD/rivalsCar-LCD.imageset/rivalsCar-LCD-ipad.png`, used twice at a smaller scale

The warm-beige playfield and four warm-grey boundary paths follow the renderer contract. There is no center path, scenery, score, title, button lettering, real-console branding, or other tiny text.

## Provenance

- Concepts were generated and revised on 2026-08-12 and 2026-08-13 with the built-in ImageGen workflow, then mechanically normalized to opaque `1024×1024` PNGs.
- Retro Video Game's final in-screen composition was assembled deterministically from repository assets after the hardware concept was generated.
- Both special-edition edge treatments were validated at approximate 18%, 23%, and 29% rounded-corner radii; the 29% case is intentionally more aggressive than the normal presentation.
- Generated theme characters remain close art-direction interpretations unless a note above identifies exact shipped assets. Production Icon Composer packages should replace interpretations with their canonical curated artwork where needed.
- No transparency or chroma-key processing was requested.
