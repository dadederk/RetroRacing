# About Screen

## Overview

The About screen provides information about RetroRacing, ways to rate the app, social links, acknowledgements, and credits. It is **accessible from Settings** on iOS, tvOS, and macOS via an “About” row that pushes a dedicated About view.

## Navigation

- Entry point: `SettingsView` (shared) shows an **About** row at the bottom of the list:
  - Label: localized “About” with `info.circle` SF Symbol.
  - Action: Pushes `AboutView` inside the `NavigationStack` used by Settings.
- Flow:
  - Menu → Settings (sheet) → About (push) → Back returns to Settings → Done dismisses Settings.

## Sections

The About screen is implemented in `RetroRacingShared/Views/AboutView.swift` and uses `List` + `Section` for a Settings‑style layout:

1. **App Information**
   - Title and subtitle introducing RetroRacing.
   - Link to the RetroRacing micro‑site: `https://accessibilityupto11.com/apps/retroracing/`.

2. **Rate**
   - Button that calls `RatingService.requestRating()`.
   - Used both as a user‑triggered entry point and a way to align with StoreKit rating prompts.

3. **Let’s connect!**
   - Links to:
     - Accessibility up to 11! (blog)
     - X (Twitter) – `@dadederk`
     - Mastodon – `@dadederk@iosdev.space`
     - BlueSky – `@dadederk.bsky.social`
     - LinkedIn – Daniel Devesa

4. **Giving Back**
   - Highlights AMMEC and explains that a portion of proceeds is donated.

5. **Also Supporting**
   - Highlights **Swift for Swifts**.

6. **Credits**
   - Font credit:
     - **Press Start 2P** by CodeMan38
     - Licensed under SIL Open Font License 1.1
     - Link to the font page on Google Fonts.

7. **Footer**
   - Sentiment and origin:
     - “Released with love ❤️ from ARCtic”
     - “Oulu, Finland”
     - Thanks to everyone who played and encouraged “pushing the button”.

## Architecture & Dependencies

- The screen lives in the **shared UI layer** (`RetroRacingShared/Views`) to maximize reuse across iOS, tvOS, and macOS.
- It depends on:
  - `RatingService` (protocol) injected via `SettingsView` and ultimately `MenuView`.
  - `GameLocalizedStrings` for all user‑facing text.
- URL handling:
  - URLs are centralised in a small internal `AboutViewURLs` helper.
  - On iOS, links open in‑app using `SafariView` (SFSafariViewController wrapper).
  - On other platforms, links use `openURL` from the SwiftUI environment.

## Localization

- All visible text is localized via `RetroRacingShared/Localizable.xcstrings`.
- Keys follow the `about_*` naming convention (e.g. `about_title`, `about_app_subtitle`, `about_footer_thanks`).
- Supported languages:
  - English (source)
  - Spanish
  - Catalan (Valencià meridional)

## Accessibility

Best‑effort accessibility has been applied in line with `/Requirements/accessibility.md`:

- **VoiceOver / Screen Readers**
  - Reusable `InfoLinkRow` combines title and subtitle into a single accessibility element.
  - Decorative icons are hidden from VoiceOver.
  - Link rows use link traits rather than button traits where appropriate.
  - The rate button includes an accessibility hint describing that it opens the rating dialog.

- **Dynamic Type**
  - Text uses system fonts that scale with Dynamic Type.
  - Layout uses `AdaptiveStack` to switch from horizontal to vertical arrangements at accessibility sizes to reduce truncation.

- **Color & Contrast**
  - Uses semantic colors (`.primary`, `.secondary`, `.tint`) to respect Light/Dark Mode and system contrast settings.

## Testing Notes

- Building the **RetroRacingUniversal** target ensures the About screen compiles and links correctly for iOS.
- Unit tests should cover:
  - That `SettingsView` exposes an About row.
  - That `AboutView` can be constructed with a mock `RatingService`.
  - That tapping the Rate button calls `RatingService.requestRating()` (via a mock).

