# About Screen

## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** About screen navigation, link sections, rate/review entry, font licenses and acknowledgements, localization, and accessibility.
- **Must not break:** Entry is a Settings push inside the Settings `NavigationStack`; review URL uses App Store ID `6758641625`; shared URLs stay centralized.
- **Key files:** `AboutView`, `SettingsView`, `ExternalLinks`, `AppStoreReviewURL`.

## Navigation

- Settings shows an About row near the bottom of the list.
- Tapping About pushes `AboutView`; Back returns to Settings and Done dismisses Settings.
- About lives in shared UI for iOS/iPadOS, tvOS, and macOS reuse.

## Content Contract

- App information links to the RetroRapid microsite.
- Rate opens the App Store write-review URL directly through `openURL`.
- Social section links to the blog and Dani’s social profiles.
- Giving Back reuses AMMEC copy from the paywall and uses `ExternalLinks.ammec`.
- Also Supporting highlights Swift for Swifts.
- A dedicated Fonts section covers Press Start 2P, OpenDyslexic, Atkinson Hyperlegible Next, and
  Lexend. Each detail shows representative accented Latin/CJK sample text in the candidate family,
  its intended reading benefit, official and license-source links, exact copyright notice, the
  SIL Open Font License label, and the locally bundled full OFL 1.1 text.
- General credits include Helm and ARCtic Conference.
- Footer keeps the ARCtic/Oulu origin and thanks copy.

## URL Handling

- Shared/cross-screen URLs belong in `ExternalLinks`.
- Official font and license-source URLs also belong in `ExternalLinks`.
- Review URL belongs in `AppStoreReviewURL`.
- iOS opens normal web links in in-app Safari where supported.
- Rate intentionally bypasses in-app Safari so the system can route to App Store review.

## Localization and Accessibility

- All visible text is localized in `Localizable.xcstrings`.
- Link rows combine title/subtitle into one accessible element.
- Decorative icons are hidden from accessibility.
- Link rows use link traits where appropriate.
- Dynamic Type layouts switch from horizontal to vertical where needed to avoid truncation.
- Font-family trademark names are not translated; attribution descriptions, section labels,
  availability state, and license navigation labels use the shared string catalog.

## Testing

- Tests or previews should cover Settings exposing About, constructing `AboutView` without service
  dependencies, Rate opening `AppStoreReviewURL.writeReview`, ordered font attribution descriptors,
  candidate previews, and loading the bundled full license resource.
