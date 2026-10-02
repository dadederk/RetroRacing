# Product Page Header Concepts

These are future App Store product page header concepts for RetroRapid!. None is an active App Store Connect asset.

## Headers

| File | Status | Direction |
|---|---|---|
| `lcd-console.png` | Lead concept | Beige LCD game console with the original full-height racing screen, pink controls, and the wordmark on the upper faceplate. |
| `coastal-sunset.png` | Earlier alternate | Three-car coastal race, based on the past Miami In-App Event artwork. |
| `bay-sunset.png` | Retained alternate | San Francisco Bay highway scene, based on the 3k downloads celebration artwork. |

All headers contain only the approved `RetroRapid!` wordmark over the illustration. There is no tagline, milestone count, or locale-specific copy. The same file can therefore be considered for every supported storefront locale.

## Production Assets

- `backgrounds/` contains the three text-free, full-size scenes.
- `sources/lcd-console-original.png` is the original 1915 x 821 LCD console render supplied for the selected proportion. The lead header preserves its screen and hardware geometry.
- `sources/retrorapid-title-cartridge-lcd.png` is the 1000 x 244 transparent title layer used on the LCD console. `sources/retrorapid-title-cartridge.png` is the 1400 x 341 layer used on the earlier sunset concepts. Both are scaled copies of `../assets/brand-marks/retrorapid-title-cartridge.png`; the lettering was not regenerated.
- The LCD hardware and screen refer to `../../Plans/assets/alternate-app-icon-concepts/retro-video-game-v4.png` and `../../Plans/assets/alternate-app-icon-concepts/lcd.png`.
- `sources/miami-in-app-landscape.png` and `sources/3k-downloads-california.png` preserve the original campaign art used as visual references. The milestone wording in the latter appears only in this source file, never in a header.

## Layout

- Header canvas: **3840 x 1646 px**, opaque sRGB PNG.
- Center crop used for layout checks: **1646 x 661 px**, at **x=1097, y=493**.
- LCD wordmark layer: **x=1420..2420, y=245..489**, fully on the upper beige faceplate. This visual placement is above the earlier center crop, so verify title visibility in App Store Connect's actual preview before submission. The sunset wordmark layers sit at **x=1220..2620, y=550..891**.
- The backgrounds were generated at approximately half size, then upscaled to the production canvas with nearest-neighbor sampling. The approved wordmark was trimmed and scaled separately before compositing.

## ImageGen Prompts

The built-in ImageGen tool produced the backgrounds. The LCD lead uses the initial panoramic render from this prompt:

> Use case: ads-marketing. Asset type: text-free panoramic background for the RetroRapid! App Store product page header; target aspect ratio 3840:1646 (2.33:1). Input image 1 is the PRIMARY art-direction reference: the approved Retro Video Game icon's warm cream/beige rounded plastic hardware, grey monochrome LCD racing game, bright saturated pink D-pad and two round buttons, subtle precision-molded casing. Input image 2 defines the exact style of the LCD road, lane dashes and chunky monochrome racing car. Create a brand-new wide, straight-on, symmetrical hero view of a fictional retro tabletop video-game console that spans the entire panorama. Make the central LCD large and readable, showing the grey/black low-resolution road perspective, one large player car at lower center and two smaller opponent cars above. The road and cars must stay truly monochrome grey/black, like the references. Let cream/beige hardware form a substantial frame. Put an oversized hot-pink D-pad at the far left and two dimensional hot-pink round action buttons at the far right, with slim metallic pink/chrome highlights around the display and hardware edges. Use pink as a vivid controlled accent; overall visual identity remains beige, warm grey and charcoal. Reserve a clean, wide, unobstructed horizontal band across the upper center of the console, roughly 30%-50% image height and within the middle 45% width, for an approved title mark that will be added later. Keep both the player car and controls visible in the full banner. Sophisticated premium product-art finish, restrained realistic plastic texture, sharp pixel-art game graphics, no card border or floating device shadow. No text, letters, words, numbers, logos, labels, fake brand marks, UI overlays, watermark, or extra copy.

The coastal background used these two prompts in sequence:

> Use case: ads-marketing. Asset type: text-free panoramic background for a future RetroRapid! App Store product page header, final target aspect ratio 3840:1646 (2.33:1). Input image 1 is the primary visual reference: the existing Miami in-app event landscape with a pixel-art sunset highway, three green top-down racing cars, palms, and magenta/orange/cobalt palette. Input image 2 is a secondary style reference for the polished game-campaign pixel art and road perspective only; do not copy its milestone sign, city identity, or any lettering. Create a fresh, seamless, super-wide landscape adaptation. Keep the dramatic pixelated tropical arcade highway and three recognizable green racing cars, with the main car in the lower middle and two smaller rivals further up the road. Extend the scene broadly left and right with natural scenery; maintain crisp coherent pixel-art texture. Reserve the upper-middle central 42% of the canvas, roughly from 30% to 61% of image height, as relatively simple dark plum sky / distant horizon with enough consistent contrast for an exact approved wordmark to be placed later. Position the bright sun lower or slightly off center so it will not sit behind the future title. This generated background MUST contain absolutely no text, letters, words, numbers, logos, milestone signs, arrows, buttons, UI, badges, watermarks, or extra copy. No visible Miami-specific landmarks. Full-bleed finished illustration, no framing.

> Use case: precise-object-edit. Edit target: the supplied text-free panoramic RetroRapid pixel-art racing background. Preserve its 2.33:1 aspect ratio, crisp pixel style, palette, three green cars, road, palms, and left/right scenery. Make one compositional change: move the bright sun from the exact center to around 27% of canvas width while keeping it low on the horizon, and keep the upper-middle central 42% of canvas width from about 30% to 60% of height as simple dark plum sky for a large official RetroRapid! title to be added later. Keep road and main car visually centered. Do not add text, letters, words, numbers, logos, milestone signs, arrows, buttons, UI, badges, or watermark.

The bay alternate used this prompt:

> Use case: ads-marketing. Asset type: text-free alternate panoramic background for a future RetroRapid! App Store product page header. Input image is the RetroRapid 3k downloads California celebration artwork, used as the main art direction and visual style reference. Reimagine it as an EVERGREEN 2.33:1 wide pixel-art racing scene in that same polished, colorful sunset arcade style. Preserve the striking San Francisco Bay-like city and bridge skyline, palm silhouettes, road perspective, and one recognizable green pixel racing car. Extend the scene naturally left and right to make a wide banner; place the green car lower-center, leaving the upper-middle central 42% of image width from about 30% to 60% of image height relatively uncluttered and dark enough for the official wordmark to be overlaid later. Remove the existing 3K downloads sign, arrow sign, and THANK YOU wording entirely; replace with continuous natural road/city scenery. No other text, letters, words, numbers, logos, badges, road signs, UI, watermarks, or added copy. Full-bleed coherent pixel illustration.

## Before Submission

Inspect the chosen image in App Store Connect's actual product page preview and confirm the final creative-asset requirements at the time of upload.
