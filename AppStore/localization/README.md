# Localisation review sheets

Generated from the canonical in-app, App Store, IAP, Game Center, screenshot, and TestFlight sources. Do not edit the CSV copy as a source; record reviewer notes there, then apply approved edits to the canonical layer.

An approval is valid only when `approvedContentDigest` in `review-status.json` matches the digest below. Any copy change changes the digest and reopens review.

| Locale | Catalog | Status | Items | Current digest | Reviewer | Date |
|---|---|---|---:|---|---|---|
| [en-US](reviews/en-US.csv) | `en` | NEEDS_REVIEW | 614 | `566872bcf3c6848133db2d9b079f62a5d67db1b85dea883e3835f831326e8eef` | — | — |
| [en-GB](reviews/en-GB.csv) | `en` | NEEDS_REVIEW | 614 | `3cf84460ae4649f709f905b9fb6c67f59a621d31a27aa1224c5fe62410976126` | — | — |
| [en-AU](reviews/en-AU.csv) | `en` | NEEDS_REVIEW | 614 | `7870ee1d9782e3df3a2f375b315c623bd49dce2bc8b68dab5a14cb3fa14e8dbd` | — | — |
| [en-CA](reviews/en-CA.csv) | `en` | NEEDS_REVIEW | 614 | `bd734983a1d58e5baf0be1d35e0b8902efda6296043d4c9da477f12fcb6a957e` | — | — |
| [de-DE](reviews/de-DE.csv) | `de` | NEEDS_REVIEW | 614 | `6d507221d3d6a13e85041a67841324914bad7036c14b6274c896a4906c083b88` | — | — |
| [nl-NL](reviews/nl-NL.csv) | `nl` | NEEDS_REVIEW | 614 | `183bdaa191db0caa1e6bcebd433ae5d5965d9a28cc9496a90b9f83678ebcc660` | — | — |
| [it](reviews/it.csv) | `it` | NEEDS_REVIEW | 614 | `c1d512179591b2156b33055776312fd5c37f22241e7f328fa4b86cfe3d0d0a97` | — | — |
| [fr-FR](reviews/fr-FR.csv) | `fr` | NEEDS_REVIEW | 614 | `7d8358f23802e04df194deca64d58d5bb29c143e9ca481fe9ad1878276f0823d` | — | — |
| [fr-CA](reviews/fr-CA.csv) | `fr-CA` | NEEDS_REVIEW | 614 | `b1a77111493d984d866409b91c2a3b3e8599e75dc1feba59e8cd1d81b1858f78` | — | — |
| [es-ES](reviews/es-ES.csv) | `es` | NEEDS_REVIEW | 614 | `41056ca0fd15fc30a5735d7e80137c09f448a2b703334aa7cd64e2c2d5ce7a25` | — | — |
| [es-MX](reviews/es-MX.csv) | `es-MX` | NEEDS_REVIEW | 614 | `b7e0befabac78feca5776b3e99b73db0ec0b3ffd1366c5501f14c4c55d7022d2` | — | — |
| [ca](reviews/ca.csv) | `ca` | NEEDS_REVIEW | 614 | `61bff74f5418a92e827bfb4364b9d945cb449314a37a158a5ddab08a12a691ed` | — | — |
| [ja](reviews/ja.csv) | `ja` | NEEDS_REVIEW | 614 | `505d91e8b1c43b511490fd16d440dcb3f484e31862e419f0a4a7b145838c4008` | — | — |
| [ko](reviews/ko.csv) | `ko` | NEEDS_REVIEW | 614 | `a5461207bd2b07ff5b43d4e49aa1aac45fde5c17b6883f00ad8e892cde2092f1` | — | — |
| [pt-BR](reviews/pt-BR.csv) | `pt-BR` | NEEDS_REVIEW | 614 | `b83fb27ac412bafdbb9e8760f5977134a96de07b7518be322f68f95b513d0aeb` | — | — |
| [pt-PT](reviews/pt-PT.csv) | `pt-PT` | NEEDS_REVIEW | 614 | `b13dc7d957af75765765de7afd7faf9d00af304dfe6c5484c12943c38791bd1d` | — | — |
| [zh-Hant](reviews/zh-Hant.csv) | `zh-Hant` | NEEDS_REVIEW | 614 | `50c8529d36770a081b5dbba48de07d5c944831db7ca4db14513c3acaa66df015` | — | — |
| [zh-Hans](reviews/zh-Hans.csv) | `zh-Hans` | NEEDS_REVIEW | 614 | `cc7bce7845e0a309676cbc41fed04721745f8c34a1f55efed954d7cfb03ead6c` | — | — |
| [tr](reviews/tr.csv) | `tr` | NEEDS_REVIEW | 614 | `da2b0abf36456bf6994bd82a0b1538482abc0bc1576574a46e609b1dff31bee5` | — | — |
| [pl](reviews/pl.csv) | `pl` | NEEDS_REVIEW | 614 | `a8823480f3379475f759f36a504595a8162e3067528b99eadc0a67f2cf370838` | — | — |

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
