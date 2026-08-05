# Localisation quality review

Last updated: 2026-08-05

The 1.6 localisation package is staged locally. No App Store Connect metadata, IAP, Game Center, TestFlight, or screenshot data may be changed as part of this review wave.

## Canonical review flow

1. Freeze and review English source copy.
2. Generate deterministic sheets with `./retrorapid localization reviews --all`.
3. A fluent reviewer checks every row for their locale across in-app strings, listing metadata, IAP, Game Center, screenshots, and TestFlight.
4. Apply corrections to the canonical layer, regenerate the sheets, and repeat until the digest is stable.
5. Set the locale to `APPROVED` in [`../localization/review-status.json`](../localization/review-status.json), recording reviewer, date, notes, and the exact digest from [`../localization/README.md`](../localization/README.md).
6. Return every String Catalog unit for that locale to `translated` only after approval of the exact digest.
7. Run `./retrorapid localization audit --require-approval` before release capture or rollout.

Any later copy change produces a new digest and invalidates approval. Structural auditing runs inside `./retrorapid check`; pending approval is expected during editorial work and is enforced only by the release-readiness flag.

## Required language decisions

- `fr-CA`: genuinely Canadian, formal `vous` throughout.
- `pt-PT`: European vocabulary and neutral third-person forms without explicit `você`/`vocês`.
- `ca`: consistent Valencian Meridional, including `teua`/`seua`, `hui`, `este`/`esta`, `ací`, appropriate `-ix` forms, `rellotge`, and `avançament`.
- `es-MX`: Mexican idiom and terminology, full in-app coverage, and independent source capture.
- `zh-Hant`/`zh-Hans`: no character-set leakage.
- All locales: natural casing, stable product/glossary terms, accurate plurals and placeholders, and the same warm, punchy arcade tone as English.

## Capture gate

Existing Screenshot Studio images are the recoverable baseline. Capture and install replacements only after the source locale is approved, then inspect every device set for language, truncation, clipping, character leakage, and stale English UI. Upload remains a later manual operation.

## Accessibility review

The fluent review must include a physical-device VoiceOver pass, not only visual proofreading. Complete a run with Screen Curtain enabled; confirm labels make sense without the screen, announcements describe lane changes, scores, achievements, errors, and Game Over in the right order, and pronunciation is natural for the locale. Labels must not include redundant role words such as “button.” Also spot-check Voice Control names against visible labels, Full Keyboard Access focus order on iPad/Mac, and the largest Dynamic Type sizes for truncation. Automated coverage verifies presence and placeholders but cannot approve meaning, pronunciation, or the end-to-end experience.
