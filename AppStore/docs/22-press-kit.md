# RetroRapid! press kit

## Status

The RetroRapid press page is implemented in the sibling `BlogDadederk` site and is ready for local review at `/apps/retrorapid/press/`. It is not published by this repository.

Publish the press page alongside RetroRapid 2.1. Its selected iPad and Mac imagery intentionally includes the Cartridge and CRT styles introduced in that release; do not publish it ahead of 2.1.

The site now uses one reusable press-kit layout for Xarra and RetroRapid. Per-app configuration controls facts, copy, downloads, screenshots, videos, portraits, localized summaries, and secondary media.

## Material available now

- Paste-ready product summary, brief, origin story, facts, features, privacy notes, coverage, developer bio, and press contact.
- Nine full-resolution screenshots covering iPhone, iPad, Mac, and Apple Watch, including an active SharePlay race and the default CRT style on Mac.
- Classic app icon at 1024, 512, and 256 pixels.
- Two approved pixel-art illustrations from the RetroRapid! 2.0 App Store in-app event.
- Downloadable ZIP with the screenshots, artwork, icons, and editorial-use README.

## Material intentionally hidden

Do not render placeholders for unavailable or unapproved material. The current RetroRapid configuration omits:

- Demo video.
- Developer portrait.
- Product or lifestyle photography.
- Localized press summary.

Add a section only when its final asset and usage text are ready.

## Public claims

- Name the publicly shipping iPhone, iPad, Mac, and Apple Watch experiences.
- SharePlay friend races are available on iPhone, iPad, and Mac and are always free.
- Keep tvOS and visionOS out of public press-kit platform claims until their public release status changes.
- State the free allowance as nine solo plays on the first day and three per day afterward.
- Describe Unlimited Plays as a US $2.99 one-time purchase with regional pricing, never a subscription.
- Keep privacy copy aligned with the App Store listing: no data collection, ads, or tracking.
- State that 10% of proceeds are donated to AMMEC.

## Source and refresh workflow

The public page and downloadable pack live in `BlogDadederk/AccessibilityUpTo11`:

- Shared layout: `Sources/Pages/AppPressContent.swift`
- RetroRapid configuration: `Sources/Models/AppPressKit+RetroRapid.swift`
- Full-resolution media: `Assets/Images/Site/Apps/RetroRapid/Press/`
- Downloadable pack: `Assets/Downloads/retrorapid-press-kit.zip`

When refreshing the kit:

1. Select screenshots only from released, publicly supported experiences.
2. Update the page catalog, ZIP contents, and ZIP README together.
3. Keep unavailable optional sections empty so they do not render.
4. Run the site tests and build, then visually review desktop and narrow layouts before publishing.
