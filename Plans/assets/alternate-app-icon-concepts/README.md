# Alternate App Icon Concept Assets

These files are the selected art-direction concepts for [the alternate app icon plan](../../alternate_app_icon_plan.md). Theme concepts remain non-runtime references. The app-icon generator copies all three selected Special Editions into their matching `.icon` packages: Retro Cartridge uses neutral-grey v5 Default plus charcoal v5 Dark sources, Retro Video Game uses v4 Default plus v5 Dark, and Retro Game Box uses distinct light-grey/blue/pink and black/red v7 sources.

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
| Retro Cartridge | [`retro-cartridge-v5.png`](retro-cartridge-v5.png) | Full-frame neutral warm-grey cartridge, printed RetroRapid! label, original accessibility seal, and gold connector pins. |
| Retro Video Game | [`retro-video-game-v4.png`](retro-video-game-v4.png) | Full-bleed cream handheld, system-pink controls, and an LCD game screen made from shipped sprites on a coherent projected curve. |
| Retro Cartridge Dark | [`retro-cartridge-dark-v5.png`](retro-cartridge-dark-v5.png) | Material-aware charcoal cartridge companion with dimensional molding and unchanged pink/gold hierarchy. |
| Retro Video Game Dark | [`retro-video-game-dark-v5.png`](retro-video-game-dark-v5.png) | Material-aware charcoal handheld companion with dimensional molding and unchanged LCD/pink/navy hierarchy. |
| Retro Game Box | [`retro-game-box-v7.png`](retro-game-box-v7.png) | Light-mode handheld-era printing with subtle full-surface paper grain, a clean square perimeter, clearly visible irregular interior scratches, an upright condensed cobalt wordmark, a white/red lozenge, and the shared Dark-edition accessibility seal. |
| Retro Game Box Dark | [`retro-game-box-dark-v7.png`](retro-game-box-dark-v7.png) | Matte-black boxed-software composition with a left-flush racing-art panel, overlapping title and teal callout, red top tab, smaller inset white/red publisher capsule, left-shifted `BUILT WITH LOVE BY` footer lockup, shorter subtle striped no-neck accessibility figure, authentic interior scratches, and the shared gold seal. |

[`nine-icon-ios27-mask-preview.png`](nine-icon-ios27-mask-preview.png) shows the earlier nine-icon set under the continuous-corner silhouette extracted from the supplied iOS 27 Photoshop template. [`retro-game-box-ios27-mask-preview.png`](retro-game-box-ios27-mask-preview.png) validates both Retro Game Box appearances against that same silhouette.

## Supporting References

- [`road-geometry-reference.png`](road-geometry-reference.png) records the shared renderer-derived perspective used to correct the road paths.
- [`ios-27-icon-mask.png`](ios-27-icon-mask.png) is the tracked `1024×1024` validation mask extracted from the supplied `App Icon Template.psd`.
- [`sketch-tabletop-source.png`](sketch-tabletop-source.png) is the user's source sketch for Retro Cartridge.
- [`sketch-handheld-source.png`](sketch-handheld-source.png) is the user's source sketch for Retro Video Game.
- [`sketch-game-box-source.png`](sketch-game-box-source.png) is the user's source sketch for Retro Game Box.
- [`special-editions-ios27-mask-preview.png`](special-editions-ios27-mask-preview.png) checks both hardware icons against the same template-derived mask on a contrasting background.
- [`special-editions-ios27-mask-dark-preview.png`](special-editions-ios27-mask-dark-preview.png) verifies the approved v5 Dark companions under the template mask, including charcoal material depth, app-pink accents, label/LCD content, navy details, and connector contacts.

These are references or validation artifacts, not alternate icon variants.

## Shared Art Direction

All selected PNGs are opaque, unmasked `1024×1024` sources. The operating system applies the final icon mask. A Lamé curve / superellipse with `n ≈ 5` is a useful art-direction construction for the continuous shoulders and concentric inset rhythm. Final validation still uses the exact silhouette extracted from the supplied iOS 27 Photoshop template so the artwork follows the platform mask rather than relying on a guessed exponent or an ordinary circular-radius rounded rectangle.

The theme icons use the game renderer's projected road grammar. Production Pocket preserves the approved three-path interrupted-center layout; LCD, Cartridge, and CRT use four broad boundary paths. For each icon, all paths and both road edges share one vanishing point, continue from the top through the lower edge, and widen and spread toward the viewer. This keeps boundaries visible around and below the car instead of collapsing them into its silhouette. Production Cartridge keeps the exact shipped 8-bit iPad car above cool-grey Default or charcoal-blue Dark surfaces, retaining its characteristic yellow marks in both appearances. Production CRT keeps the exact shipped 16-bit iPad car above green-and-navy Default or green-grey-and-charcoal Dark surfaces; its two outer yellow path centers sit just inside the projected road edges instead of straddling the off-road boundary. A separate full-canvas frontmost layer applies scanlines, a faint phosphor highlight, and a radial vignette over car and road; Dark keeps the effect but reduces scanline strength while concentrating the vignette at the perimeter.

Each theme retains its own canonical road, marker, and exterior colors. Critical characters, labels, controls, and screen content remain inside the central mask-safe region; full-bleed backgrounds and hardware shells may be cropped by the system mask.

## Special-Edition Direction

### Retro Cartridge

The object is a fictional vintage game cartridge, not a console or display. Its matte molded neutral warm-grey shell fills every source corner so the operating-system mask becomes the outer cartridge contour. The plastic recalls classic handheld and 16-bit cartridge housings without copying a specific product: grey midtones retain a faint warm undertone, physical microtexture, molded highlights, and recessed shadows, with no cream, blue, or metallic cast. The raw boundary omits near-white highlights, while the grey bevel and app-pink echo follow centered, evenly inset descendants of the tracked iOS 27 mask. Their shoulders begin turning where the system contour turns instead of following an unrelated corner radius; this prevents Composer and system antialiasing from amplifying the shell into a pale rim.

The interior treats that curve as a playful construction system: the vent, label surround, and connector are horizontally compressed descendants of the same continuous-corner geometry, while the side ribs step with the outer shoulders. These repetitions stay subordinate to the printed artwork. App-pink accents remain secondary, and the bottom edge exposes one neat row of classic gold connector pins. The large front element is visibly a printed paper label with ink/paper texture rather than glass.

The label contains the single title `RetroRapid!`, a rear-view open-wheel racer, the same four renderer-aligned road paths used by the game, and an original gold certification-style medallion reading `Accessibility up to 11!`. The seal evokes period game packaging without reproducing Nintendo's name, wordmark, wording, typography, or exact seal geometry. Label text, car, seal, and the central connector contacts remain safe under normal iOS/iPadOS masks; only expendable edge detail may trim under the deliberately aggressive validation crop.

### Retro Video Game

The fictional handheld uses matte cream molded plastic as the full-bleed icon surface, with no pale boundary highlight, dark exterior wedges, or closed perimeter outline. Its restrained outer bevel follows the tracked iOS 27 mask, while the navy screen bezel and lower control tray are centered, horizontally compressed descendants of the same continuous-corner construction. Smaller molded wells repeat that logic around the D-pad and paired buttons; a thin app-pink echo connects the lower geometry to the controls without competing with the screen. The system mask therefore becomes the console's outer silhouette instead of clipping a second rounded object. Its screen, system-pink D-pad and buttons, speaker/status slots, and controls remain visible under the template mask. The screen resembles RetroRapid! gameplay through its assets and geometry rather than through a title or HUD.

The final screen is a deterministic composite, not a generated approximation. It uses these exact shipped iPad assets without altering their internal pixels:

- `RetroRacingShared/Assets.xcassets/Sprites/LCD/playersCar-LCD.imageset/playersCar-LCD-ipad.png`
- `RetroRacingShared/Assets.xcassets/Sprites/LCD/rivalsCar-LCD.imageset/rivalsCar-LCD-ipad.png`, used twice at a smaller scale

The warm-beige playfield and four warm-grey boundary paths follow the renderer contract. The road takes one gentle right-hand bend into the distance: all four path centers derive from the same projected curve, every dash is tangent to its path, and dash length, width, and spacing increase toward the viewer. There is no center path, scenery, score, title, button lettering, real-console branding, or other tiny text.

### Retro Game Box

The icon is an original fictional period-inspired 16-bit retail cover, not a reproduction of a Nintendo, Game Boy, or SNES box. Both appearances use a fake front perspective rather than a photographed three-dimensional carton: one printed face receives a slight coherent planar warp, and the operating-system mask establishes the only outer silhouette. Their structure echoes an `n ≈ 5` superellipse rhythm, then is checked against the exact iOS 27 continuous-corner shoulders. The title, racing panel, seal, and fictional publisher mark stay inside the central mask-safe region.

Default is a deliberately different handheld-era printing: a warm light-grey band reaches the raw left, top, and bottom square edges and carries an original upright condensed cobalt `A11y up to 11!` wordmark, while system-pink artwork derived from the approved Retro Cartridge palette and graphic treatment reaches the remaining raw edges. There is no footer or publisher sentence. A white fictional publisher lozenge with red outline and red `A11y up to 11!` lettering sits over the lower artwork. The gold `Accessibility up to 11!` seal artwork from Dark is reused at lower right. Its cream-and-black 8-bit rear-view racer, two rivals, and four cream dashed paths share one horizon.

Dark is a more explicit homage to the hierarchy of late 16-bit boxed software while remaining original. Its matte-black cover divides into a rectangular racing-art panel that reaches the raw left edge and a narrower black information rail on the right. `RetroRapid!` slightly overlaps the artwork, a red tab interrupts the top edge, and a reduced original white/red `A11y up to 11!` capsule sits inward from the top-right corner. A black box carrying exact teal `Race like it is 1985` lettering overlaps the art/rail boundary. The exact gold `Accessibility up to 11!` medallion sits lower left. Large original red `ACCESSIBILITY UP TO 11` lettering and a red strip with cream `BUILT WITH LOVE BY` form one left-shifted bottom publisher lockup with a clear black gap before the corner motif. A shorter, quieter muted-gold horizontal-line field exits through the raw bottom and right edges. Black gaps interrupt those lines to carve a soft complete circle and friendly generic human figure whose round head meets broad curved shoulders directly, with no neck and rounded open limbs; the outer pattern is intentionally expendable under the system mask.

Both fronts carry `RetroRapid!`, `Race like it is 1985`, `A11y up to 11!`, and the same gold `Accessibility up to 11!` medallion. Both use the same restrained material rule: fine, low-contrast, evenly distributed paper tooth; no edge-concentrated abrasion or false outer border; and a small asymmetrical set of clearly visible, broken, fibrous scratches in expendable interior space. Their varied lengths, angles, and opacity create handled-box authenticity without tracing the system silhouette. This keeps the flat fields and pixel artwork crisp at icon size while letting every raw square edge continue naturally through a system mask. The typography, layout details, capsule, lozenge, striped mark, and seal are deliberately original. The approved v7 artworks supply Default, Dark, and Default-for-Tinted source mappings. Clear and Tinted presentations remain system rendered.

## Provenance

- Concepts were generated and revised on 2026-08-12 and 2026-08-13 with the built-in ImageGen workflow, then mechanically normalized to opaque `1024×1024` PNGs.
- Retro Video Game's final in-screen composition was assembled deterministically from repository assets after the hardware concept was generated.
- Both special-edition edge treatments are validated with the tracked mask extracted from the supplied iOS 27 Photoshop template. Inset contours are assessed against centered constant-distance or compressed descendants of that silhouette rather than an assumed superellipse exponent.
- On-device review on 2026-08-14 identified a pale perimeter amplified by the special packages' stronger Composer translucency. The final sources use matte boundary pixels and inset concentric highlights, while both packages match the theme icons' restrained `0.05` translucency.
- The 2026-08-14 playful-concentricity pass reworked only the hardware architecture. Retro Video Game's approved LCD composition was restored deterministically after the shell exploration so generated car interpretations did not enter the final screen.
- The 2026-08-14 road-perspective edit used the built-in ImageGen workflow to establish the intended bend, then rebuilt the four paths deterministically so the final screen has one shared projection and retains the exact shipped cars. The edit prompt was: “Keep the gentle bend; make all four dashed boundaries follow the same smooth projected curve; place each dash on and tangent to its path; grow dash length, width, and spacing toward the viewer; preserve the handheld hardware, LCD palette, and cars.”
- The 2026-08-14 template-concentricity pass used the built-in ImageGen edit workflow with each Special Edition as its edit target and the supplied Photoshop template as the geometry reference. The prompt kept each icon's label, gameplay, controls, palette, and text invariant while rebuilding the outer shell, molded bevels, pink echoes, screen/label surrounds, and control tray around the template's continuous-corner shoulders. Exact shipped LCD car sprites were composited back over the handheld result before promotion.
- The 2026-08-14 package pilot adopted both Special Edition v4 PNGs unchanged as runtime Default artwork. An initial procedural recolour preserved pixels but flattened the molded lighting, so it was retired after visual review. The final v5 Dark companions were regenerated with the built-in ImageGen edit workflow from the approved Default and initial Dark references, then normalized to opaque `1024×1024` PNGs. The edit locked the hardware composition and protected the label or LCD game, system-pink/navy accents, seal, and connector while re-rendering only the charcoal plastic's grain, bevel illumination, recesses, and depth.
- The 2026-09-03 Retro Game Box v2 concept was regenerated with the built-in ImageGen workflow from the user's sketch, two user-supplied vintage-box references, the prior fictional concept, and the exact iOS 27 mask. The real boxes informed only cardboard texture, print character, and broad cover hierarchy; no names, characters, logos, exact layouts, or trade dress were reused. The selected pass replaces the earlier physical three-quarter carton with a nearly frontal, gently warped printed face, corrects the tagline to `Race like it is 1985`, and applies a uniform mask-safe composition inset. The result was mechanically normalized to an opaque `1024×1024` PNG; the mask preview is a validation artifact only.
- The 2026-09-04 Retro Game Box v5 Default supersedes v4 with quieter texture and a square-first composition. ImageGen extended the grey identity band and pink racing field to their raw square edges, made the vertical cobalt wordmark upright, inverted the publisher lozenge to white with red outline and lettering, and removed the generated Light seal. The exact approved Dark v2 seal pixels were then extracted and composited into mask-safe lower-right artwork space. The resulting unmasked square reads as a complete cover while the same source survives the exact iOS 27 continuous-corner mask. No third-party names, logos, characters, fonts, seal geometry, exact layout, or trade dress were reused.
- The 2026-09-04 Retro Game Box v6 Default and v3 Dark material pass used built-in ImageGen precise-object edits to establish the intended fine cardboard character, followed by a deterministic preservation pass over the approved sources so typography, art, geometry, and the shared seal could not drift. A restrained edge-aware smoothing pass quieted coarse grain. Dark's earlier gold-worn perimeter was replaced only within a narrow feathered outer strip using clean matte-black material from the ImageGen pass. Two tiny low-contrast print scratches remain in quiet interior areas of each cover. The final opaque `1024×1024` sources were checked both as raw squares and against the exact iOS 27 mask.
- The 2026-09-04 Retro Game Box v7 Default and v4 Dark scratch pass retained the clean v6/v3 perimeters but increased the skeuomorphic wear. Built-in ImageGen precise-object edits established the authentic broken, fibrous scratch character. Those texture studies were converted into isolated scratch masks and composited over the approved pixel-locked layouts, avoiding the geometry and typography drift of a full generative redraw. Marks remain inside the canvas and away from critical text, seals, and focal cars; no wear follows or approaches the system-mask contour.
- The 2026-09-04 Retro Game Box v5 Dark recomposition used the built-in ImageGen edit workflow with v4 as the edit target, the exact iOS 27 mask as geometry reference, and two user-supplied vintage boxes as broad hierarchy references only. The generated design moves the artwork flush left, overlaps the title and teal tagline box with that panel, adds a red top tab and an original top-right publisher capsule, and restructures the lower edge as a red publisher-style lockup. A precise cleanup removed an accidental purple side tab and empty seal placeholder; a title-only optical pass moved the title inside the mask-safe shoulder. The result was mechanically normalized to opaque `1024×1024` sRGB, the artwork boundary was extended through the raw left edge, and the exact approved v4 gold seal was restored unchanged. No third-party names, logos, characters, fonts, seal geometry, exact layouts, or trade dress were reused.
- The 2026-09-04 Retro Game Box v6 Dark finishing pass used the built-in ImageGen edit workflow to establish the smaller inset capsule, exact `BUILT WITH LOVE BY` footer wording, and initial accessibility-corner study. The approved v5 base then received only those localized regions. The final corner mark is deterministic: dense muted-gold horizontal lines run beyond the raw right and bottom edges, and exact black vector knockouts form a circle plus generic open-armed human figure. This preserves every approved title, road, car, seal, scratch, and texture pixel outside the three requested edit regions while producing a deliberately cropped period-print motif under the exact iOS 27 mask.
- The 2026-09-04 Retro Game Box v7 Dark balance pass used a built-in ImageGen precise-object edit to move the two-line footer lockup left and redraw the striped corner mark with a shorter, subtler field and friendlier rounded no-neck figure. Only the successful footer and lower-right regions were composited over the approved v6 source, keeping the title, game art, road, cars, seal, tagline, capsule, and upper cardboard pixel-locked. The exact mask preview confirms a clear gap between marks and an intentionally cropped but recognizable accessibility figure.
- The 2026-09-04 Retro Cartridge v5 Default material pass used a built-in ImageGen precise-object edit to replace only the cream molded shell with neutral warm-grey ABS plastic. The selected study was mechanically normalized to opaque `1024×1024` sRGB. Its pink vent and piping, printed label, cream ink, car, road, seal, black recesses, gold contacts, concentric geometry, and full-bleed mask fit remain unchanged in intent.
- `./retrorapid assets app-icons` copies the approved neutral-grey v5 Default and charcoal v5 Dark files for Retro Cartridge, the approved v4 Default and v5 Dark files for Retro Video Game, and the approved v7 Default and Dark sources for Retro Game Box instead of procedurally tinting artwork. Each package uses one stable layer with flat Default, Dark, and Tinted image-name specializations; the generator also creates matching adaptive gallery previews. This preserves deterministic runtime output while allowing appearance-specific packaging and material rendering.

### Retro Cartridge Light v5 material prompt

> Change only the light cream/yellow-beige molded cartridge plastic to a classic neutral light-grey plastic inspired by late-1980s handheld and 16-bit game cartridges. Give it a restrained, very slightly warm undertone so it remains physical and nostalgic rather than cold or metallic. Preserve the molded depth, embossed microtexture, gentle wear, highlights, shadows, bevels, recesses, and concentric squircle geometry. Target approximately `#A9AAA5` in the midtones, with believable lighter highlights and darker grey shadows. Keep the pink vent, pink outline accents, pink label, cream label typography and road markings, black outlines, car artwork, `Accessibility up to 11!` seal, gold connector pins, dimensions, proportions, typography, text spelling, spacing, lighting direction, rounded-corner-safe design, and every small detail unchanged. Avoid cream or yellow plastic, cold blue-grey, metallic material, altered text, road drift, seal changes, white edge artefacts, and pre-masking.

### Dark v5 ImageGen prompts

Retro Cartridge:

> Improve only the graphite shell material in the exact Dark icon composition. Re-render the existing dark-grey cartridge molding as premium charcoal injection-molded plastic with realistic material-specific studio highlights, fine subtle grain, lit bevels, soft recessed shadows, and clear dimensional separation. Remove the flat tinted or painted-over look. Lock the outer silhouette, concentric continuous-corner contours, label aperture, top and side vents, connector, proportions, full-bleed crop, and safe margins. Change only the molded shell plastic. Preserve the full pink printed label, `RetroRapid!` typography, car, road and every lane mark, `Accessibility up to 11!` seal, pink vent and piping, black borders and recesses, and gold connector contacts. Avoid composition drift, flat recolouring, muddy surfaces, heavy repeating texture, pale edge artefacts, halos, and corner clipping.

Retro Video Game:

> Improve only the graphite console-body material in the exact Dark icon composition. Re-render the existing dark-grey molding as premium charcoal injection-molded plastic with realistic material-specific studio highlights, fine subtle grain, lit bevels, soft recessed shadows, and clear rounded depth. Remove the flat tinted or painted-over look. Lock the outer continuous-corner silhouette, screen aperture, navy bezel, lower control tray, control positions, proportions, full-bleed crop, concentric geometry, and safe margins. Change only the molded console plastic. Preserve the warm monochrome LCD, three pixel-art cars, correctly converging road and continuous dashed lane marks, navy bezel and speaker details, pink D-pad and buttons, and thin pink piping. Avoid composition drift, altered gameplay, displaced controls, flat recolouring, muddy surfaces, cream remnants, glossy black glass, pale edge artefacts, halos, and corner clipping.

- Generated theme characters remain close art-direction interpretations unless a note above identifies exact shipped assets. Production Icon Composer packages should replace interpretations with their canonical curated artwork where needed.
- No transparency or chroma-key processing was requested.

### Retro Game Box Dark v2 foundational ImageGen prompt set

Final generation direction:

> Create an original fictional 16-bit racing-game cover as a full-bleed square app-icon source. Follow the user's sketch with a fake front perspective: the canvas is one nearly frontal printed face, gently and coherently warped around an `n ≈ 5` Lamé/superellipse rhythm rather than rendered as a physical three-quarter box. Use tactile matte-black uncoated cardboard, deep-red structural accents, cream typography, subtle ink absorption and print grain, and nested contours that play concentrically with the supplied iOS 27 mask. Put `RetroRapid!` prominently at the top and `Race like it is 1985` in a narrow right column. The central artwork shows an original rear-view red open-wheel racer, two smaller rivals, green verges, and four dashed road paths converging consistently to one horizon. Add the exact publisher line `A game by Accessibility up to 11`, an original gold seal reading `Accessibility up to 11!`, and an original capsule reading `A11y up to 11!`. Keep all critical content mask-safe. The real vintage-box references inform only texture and broad hierarchy. Do not use a visible spine, side, top plane, product mockup, real brand, logo, character, rating mark, exact layout, or trade dress.

Final mask-safe framing edit:

> Uniformly enlarge the safe-but-slightly-inset composition to `108%`, centered on the same square canvas. Treat every printed element as one locked group and preserve all relative positions, proportions, textures, and the flat fake-front perspective. Continue the same matte-black cardboard full bleed behind it. Only expendable outer wear may approach the crop; after the exact iOS 27 mask is applied, the complete title, tagline, central art, gold seal, publisher line, and `A11y up to 11!` capsule must remain visible with black breathing room.

### Retro Game Box Light v5 foundational ImageGen prompt set

Final generation direction:

> Refine the existing fictional handheld-era cover without redesigning its racing artwork. Reduce the embossed cardboard texture by roughly `55%`, leaving subtle fine uncoated-paper tooth and restrained print grain. Extend the warm light-grey identity band to the raw left, top, and bottom square edges and the system-pink racing field to the remaining raw edges, with no rounded outer frame. Keep the vertical cobalt `A11y up to 11!` wording and reading direction, but use an original upright, non-italic, bold condensed face. Replace the lower mark with a white lozenge carrying a red outline and exact red `A11y up to 11!` lettering. Remove the generated Light seal and leave clean pink space at lower right. Preserve `RetroRapid!`, `Race like it is 1985`, the cream-and-black 8-bit racer, two rivals, four coherent cream dashed paths, cyan accents, palette, and fake-front perspective. The raw square and exact iOS 27 masked result must both read as intentional finished compositions. Do not imitate or reproduce Nintendo, Game Boy, their fonts, logos, characters, packaging, seal geometry, or trade dress.

Final seal reuse and mask validation:

> Extract the exact `Accessibility up to 11!` medallion pixels from the approved Dark v2 artwork, including its complete starburst silhouette and internal print, and composite that unchanged seal into the Light cover's lower-right open pink space. Keep clear square-edge breathing room and ensure every starburst point survives the exact iOS 27 mask. Do not globally shrink, round, or premask the full-bleed cover.

### Retro Game Box Light v6 / Dark v3 foundational material-refinement prompt set

Light precise-object edit:

> Make a material-only texture refinement to the approved Light cover. Replace the existing finish with extremely subtle, fine, low-contrast, evenly distributed printed-cardboard grain across the warm light-grey band and pink artwork field. Remove concentrated edge wear, corner abrasion, perimeter scratches, border scuffing, edge darkening, and halos. Add only two tiny, short, barely visible print scratches in expendable interior background space. Preserve the raw square, full-bleed fields, every character of every text string, geometry, layout, perspective, pixel-art cars, road, speed streaks, palette, lozenge, and accessibility seal exactly. Do not add a rounded outer frame, mask, vignette, bevel, transparency, or new text.

Dark precise-object edit:

> Make a material-only texture refinement to the approved Dark cover. Completely remove the gold/yellow worn perimeter, corner abrasion, edge scratches, distressed outline, and edge darkening; let matte-black printed cardboard continue uniformly through every raw square edge. Replace the coarse distressed finish with extremely subtle, fine, low-contrast, evenly distributed cardboard grain. Add only two tiny, short, barely visible print scratches in open interior black-cardboard space. Preserve every character of every text string, geometry, layout, perspective, red frame, racing artwork, palette, symbols, publisher capsule, and accessibility seal exactly. Do not add a rounded outer frame, mask, keyline, glow, transparency, new text, or redesigned artwork.

### Retro Game Box Light v7 / Dark v4 scratch-authenticity prompt set

Light precise-object edit:

> Change only the age marks on the approved Light cover. Add roughly six to eight irregular, fine scratches: mostly short broken hairline scuffs with two moderately longer interrupted marks, varied asymmetrical angles, and a slightly lighter fibrous paper tone. Keep every scratch in open interior cardboard or printed-art space, away from all text, cars, road marks, logos, and the seal. Keep the raw outer perimeter completely clean: no mark may touch, trace, echo, or imply a rounded rectangle, superellipse, keyline, corner outline, or halo. Preserve the exact square canvas, composition, geometry, crop, scale, perspective, colors, subtle grain, typography, and artwork. Add scratches only.

Dark precise-object edit:

> Change only the scratch marks on the approved Dark cover. Add roughly six to eight authentic vintage-box scratches: irregular, fine, broken hairline scuffs with varied short lengths and angles, including two moderately longer interrupted scratches. Place them asymmetrically in open interior matte-black or printed-art areas and reveal a muted warm-grey or faint tan fibrous layer beneath the ink. Keep the raw outer perimeter completely clean and keep every mark away from critical text, cars, frame lines, the seal, publisher capsule, arrows, dots, and glyphs. Preserve the exact square canvas, composition, geometry, crop, scale, perspective, colors, subtle grain, typography, and artwork. Add scratches only.

### Retro Game Box Dark v5 boxed-software composition prompt set

Main recomposition:

> Recompose only the approved Dark Retro Game Box as an original fictional late-16-bit boxed-racing-game front. Preserve its matte-black cardboard, deep-red/cream/teal/gold palette, authentic interior scratches, original rear-view racer, road perspective, and clean raw-square perimeter. Make a rectangular artwork panel reach all the way to the left edge and reserve a narrow black information rail on the right. Let `RetroRapid!` overlap the artwork slightly. Add one broad red tab at the top and an original white capsule with red `A11y up to 11!` lettering at top right. Put exact teal `Race like it is 1985` text in a black box that overlaps the artwork and right rail. Leave clean black space at lower left for the approved gold seal. At the bottom, set large uppercase red `ACCESSIBILITY UP TO 11` above a red strip containing cream `A GAME BY`. Keep critical marks inside the supplied iOS 27 mask-safe region while allowing expendable background materials to run full bleed. The vintage references inform broad cover hierarchy only. Do not reproduce any real publisher name, logo, character, font, exact layout, seal, rating mark, or trade dress.

Artifact cleanup:

> Preserve the recomposed Dark cover exactly, including artwork, title, red top tab, white/red publisher capsule, teal tagline box, footer lockup, cardboard texture, scratches, and full-bleed black perimeter. Remove only the accidental purple tab on the right edge and the empty red-outlined seal placeholder at lower left, replacing both with matching matte-black printed cardboard. Nudge the top-right capsule slightly inward so its complete outline survives the supplied continuous-corner mask. Add no new marks or text.

Title mask-safety correction:

> Change only the `RetroRapid!` title. Reduce it by approximately six percent and move it slightly down and right while preserving its angle, cream face, black outline, red depth, and playful overlap with the artwork panel. Keep the entire title and shadow inside the supplied iOS 27 continuous-corner mask. Preserve every other pixel and design decision.

Deterministic finishing:

> Normalize the selected result to opaque `1024×1024` sRGB without changing its artwork. Extend the artwork panel through the raw left edge using its existing boundary color and texture. Restore the exact approved gold `Accessibility up to 11!` seal pixels unchanged in the clean lower-left mask-safe region. Validate both the unmasked square and the exact iOS 27 masked preview.

### Retro Game Box Dark v6 accessibility-corner prompt set

Localized ImageGen edit:

> Make exactly three localized refinements to the approved Dark cover. Replace the bottom-right abstract glyph with a period-inspired muted-gold horizontal-line field whose interruptions reveal a generic circular open-armed human accessibility figure. Change only the cream footer text inside the existing red strip to exact uppercase `BUILT WITH LOVE BY`, preserving its condensed type, tracking, placement, and strip. Make the top-right white/red `A11y up to 11!` capsule approximately ten percent smaller and move it slightly left and down for more black breathing room. Preserve the complete title, racing artwork, road, cars, seal, red tab, teal tagline, dots, triangle, cardboard texture, scratches, clean perimeter, and fake-front perspective. Do not reproduce any commercial publisher or platform logo.

Negative-space correction:

> The corner motif must not place a gold accessibility figure over the stripes. Run dense horizontal gold lines continuously through an oversized rectangle that exits the raw bottom and right edges. Remove line segments wherever the emblem falls so a complete circular outline, round head, open arms, torso, and open legs are all black absence of ink. The system mask may crop the expendable outer stripe field, but the negative-space figure must remain recognizable.

Deterministic preservation pass:

> Retain the approved v5 source everywhere except the three requested regions. Reuse the ImageGen-rendered smaller capsule and exact `BUILT WITH LOVE BY` strip. Construct the final oversized corner motif from deterministic horizontal line geometry and black vector knockouts, then validate it against the exact iOS 27 mask. Normalize the final source to opaque `1024×1024` sRGB.

### Retro Game Box Dark v7 balance prompt set

Localized ImageGen edit:

> Refine only the two bottom graphic elements of the approved Dark cover. Move the complete publisher footer lockup—large exact red `ACCESSIBILITY UP TO 11` together with the red strip and exact cream `BUILT WITH LOVE BY`—approximately thirty pixels left as one locked group, retaining its vertical position and leaving a clear black gap before the corner mark. Make the bottom-right muted-gold horizontal-line field approximately twenty-five percent shorter, slightly narrower, and less visually intense. Preserve the black negative-space construction, but redraw the enclosed figure with a round head meeting broad curved shoulders directly, no neck or stalk, and friendly rounded open arms, torso, and legs. The quieter motif may exit the raw right and bottom edges and be cropped by the exact iOS 27 mask while remaining recognizable. Preserve every other pixel and all other text.

Deterministic preservation pass:

> Normalize the selected study to `1024×1024` sRGB and composite only its footer and lower-right information-rail regions over the approved v6 source. Keep the title, top tab, capsule, racing panel, road, cars, gold seal, teal tagline, dots, triangle, upper scratches, cardboard texture, and clean perimeter from v6 unchanged. Validate both the raw square and the exact iOS 27 masked pair.
