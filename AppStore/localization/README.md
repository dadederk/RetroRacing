# Localisation review sheets

Generated from the canonical in-app, App Store, IAP, Game Center, screenshot, and TestFlight sources. Do not edit the CSV copy as a source; record reviewer notes there, then apply approved edits to the canonical layer.

An approval is valid only when `approvedContentDigest` in `review-status.json` matches the digest below. Any copy change changes the digest and reopens review.

| Locale | Catalog | Status | Items | Current digest | Reviewer | Date |
|---|---|---|---:|---|---|---|
| [en-US](reviews/en-US.csv) | `en` | NEEDS_REVIEW | 611 | `b97b3ff4c8c39a0fd9dc2bfd9304cbf5aa4e674cf26ba4d309f4359005b0d9d5` | — | — |
| [en-GB](reviews/en-GB.csv) | `en` | NEEDS_REVIEW | 611 | `d9a37f9847b5b5f7031c3072ee214b8b56f751ff737ffe60cf49d8a07ec34b52` | — | — |
| [en-AU](reviews/en-AU.csv) | `en` | NEEDS_REVIEW | 611 | `adad3c2de35bbcf3848038b8c8d63d03a190d70a6ce53ee4fb172a59983992ac` | — | — |
| [en-CA](reviews/en-CA.csv) | `en` | NEEDS_REVIEW | 611 | `f0dc507affdb40782e7a178cbfda4ac62a776324c1a9c3c26fe54f12c8a52ec4` | — | — |
| [de-DE](reviews/de-DE.csv) | `de` | NEEDS_REVIEW | 611 | `63aa8ed95c25c702224f982f7787feedd48b4e70744196dfcf1ab0398ad35c78` | — | — |
| [nl-NL](reviews/nl-NL.csv) | `nl` | NEEDS_REVIEW | 611 | `1c606029c44fe51b975781c6ccbbc5eeb5c9510da20d18510d18bd7d356a3d63` | — | — |
| [it](reviews/it.csv) | `it` | NEEDS_REVIEW | 611 | `3789ddf4fcf3e4b56950029fe676228ef87c3e934f555b28437eee8738132bb2` | — | — |
| [fr-FR](reviews/fr-FR.csv) | `fr` | NEEDS_REVIEW | 611 | `ee9e5acf9209a864a66ffa4a0ac9d642d85edda908b431251c422789ec5c5f80` | — | — |
| [fr-CA](reviews/fr-CA.csv) | `fr-CA` | NEEDS_REVIEW | 611 | `4edecee23439fa72b890cd086b85e534e211a7965e698b6201a6a3f5c8feb342` | — | — |
| [es-ES](reviews/es-ES.csv) | `es` | NEEDS_REVIEW | 611 | `db277e9a9bc9f0fe02bd247c12124d13826bf8ff5c6d010f4d94d0a0d50211ff` | — | — |
| [es-MX](reviews/es-MX.csv) | `es-MX` | NEEDS_REVIEW | 611 | `b3020573c847aafbe96372e4951b597e1d6f9bb7ec34917ae087d5e8bc3ae872` | — | — |
| [ca](reviews/ca.csv) | `ca` | NEEDS_REVIEW | 611 | `21b50ac35e4920d583ab93ce4e02e8f1d922cc9f03164aa51d50e62da92299be` | — | — |
| [ja](reviews/ja.csv) | `ja` | NEEDS_REVIEW | 611 | `5aa8eaff4b54d8658c57307116b245ba637faa353df51c0765cf47f39dc5da73` | — | — |
| [ko](reviews/ko.csv) | `ko` | NEEDS_REVIEW | 611 | `408277b2eb2af03e9d71bdf32e6c87ade2ac0939d112b5cafbb0a8e9107dcd27` | — | — |
| [pt-BR](reviews/pt-BR.csv) | `pt-BR` | NEEDS_REVIEW | 611 | `0db6d690eca196ad4bdcd07c80f1995c452f65cf406bccceb47ac72d49c814aa` | — | — |
| [pt-PT](reviews/pt-PT.csv) | `pt-PT` | NEEDS_REVIEW | 611 | `efa227c66b14be0a6357ea736047c75806f2e5b9157502660d9c485b692dc4b1` | — | — |
| [zh-Hant](reviews/zh-Hant.csv) | `zh-Hant` | NEEDS_REVIEW | 611 | `10701061292f019d82eb12a49af1b49f50cd971546855e6caea826b7a311cce3` | — | — |
| [zh-Hans](reviews/zh-Hans.csv) | `zh-Hans` | NEEDS_REVIEW | 611 | `a8b5084e54bb3566393da4608533e5c29861ea09e8f435171fca5c70d3cdfdd9` | — | — |
| [tr](reviews/tr.csv) | `tr` | NEEDS_REVIEW | 611 | `f9a6b6ceb80f2f104a0150d56e6f875128dba9d50ab79b2d41af5cef0b41dcd9` | — | — |
| [pl](reviews/pl.csv) | `pl` | NEEDS_REVIEW | 611 | `3e50fe3a996932fca64347715296a30828ea7175ffea38ba5f6905495bef32e2` | — | — |

## Locale guidance

- **en-US:** Canonical English source. Direct, compact arcade copy with sentence casing and consistent product terminology.
- **en-GB:** Natural British English where regional copy differs; preserve the compact arcade voice.
- **en-AU:** Natural Australian English where regional copy differs; avoid forced slang.
- **en-CA:** Natural Canadian English where regional copy differs; preserve the compact arcade voice.
- **de-DE:** Friendly informal du, idiomatic German, correct cases, and German sentence casing rather than English title casing.
- **nl-NL:** Friendly informal Dutch with natural compounds and sentence casing; avoid literal English arcade phrasing.
- **it:** Energetic informal Italian with idiomatic racing vocabulary and sentence casing.
- **fr-FR:** Friendly informal tu for France, idiomatic arcade vocabulary, French punctuation, and sentence casing.
- **fr-CA:** Genuinely Canadian French, consistently formal vous, Canadian vocabulary where natural, French punctuation, and sentence casing.
- **es-ES:** Friendly informal European Spanish with coche, adelantamiento, partida, and natural sentence casing.
- **es-MX:** Friendly Mexican Spanish with carro, rebase, partida, and natural local idiom; do not inherit European Spanish UI pixels.
- **ca:** Valencian Meridional throughout: teua/seua, hui, este/esta, ací, appropriate -ix forms, rellotge, and avançament.
- **ja:** Compact, inviting Japanese game copy with consistent politeness and natural arcade terminology.
- **ko:** Natural Korean game copy with consistent 해요-style politeness and compact UI phrasing.
- **pt-BR:** Friendly Brazilian Portuguese with consistent você forms and Brazilian racing vocabulary.
- **pt-PT:** European Portuguese using neutral third-person forms without explicit você/vocês; use European vocabulary and orthography.
- **zh-Hant:** Traditional Chinese throughout, compact Taiwan-friendly game phrasing, and no Simplified Chinese character leakage.
- **zh-Hans:** Simplified Chinese throughout with compact, natural arcade phrasing and no Traditional character leakage.
- **tr:** Natural informal Turkish, dotted/dotless-I correctness, stable terminology, and locale-appropriate casing.
- **pl:** Natural Polish with correct inflection and plurals, stable terminology, and sentence casing rather than English title casing.
