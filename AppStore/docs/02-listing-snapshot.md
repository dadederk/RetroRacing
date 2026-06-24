# Current Public Listing Snapshot

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-06-24
**See also:** [Metadata strategy](04-metadata-strategy.md) · [Submission gate](03-submission-quality-gate.md)


---

## Current Public Listing Snapshot

Checked on 2026-06-24 from the public App Store pages.

Sources:

- [RetroRapid! US App Store listing](https://apps.apple.com/us/app/retrorapid/id6758641625)
- [RetroRapid! UK App Store listing](https://apps.apple.com/gb/app/retrorapid/id6758641625)
- [RetroRapid! Spain App Store listing](https://apps.apple.com/es/app/retrorapid/id6758641625)

| Field | Current public value | Notes |
|---|---|---|
| Name | `RetroRapid!` | Strong brand, but uses only 11/30 characters and leaves the highest-weight visible field without generic discovery terms. |
| Subtitle | `Retro racing at full speed` | Clear vibe, but less specific than the actual mechanic. It repeats the retro/racing idea without using lane, traffic, dodging, high score, or arcade-reflex language. |
| Promotional text | `iPhone, iPad, Mac, Apple Watch` | Inferred from the public page placement. This is clear platform support, but weak conversion copy and does not mention the actual game loop. Verify in App Store Connect. |
| Category | Racing | Good fit. Keep unless data strongly argues for a different Games subcategory. |
| Current version | 1.4.2, May 12, 2026 | The current What's New text still says `RetroRacing` in the public listing. This should be fixed on the next version metadata pass. |
| Languages | English, English (UK), English (Australia), English (Canada), Catalan, Spanish | App UI and App Store metadata now include English regional variants. |
| IAP | Unlimited Plays | One-time purchase positioning remains a conversion strength. |
| Public accessibility labels | VoiceOver, Larger Text, Dark Interface, Sufficient Contrast | Strong base. Verify whether Reduced Motion and Differentiates Without Color Alone can also be declared based on the current implementation. |
| Public compatibility | iPhone, iPad, Mac, Apple Watch, Apple Vision | The visionOS target is publicly available but currently shows a "Coming Soon" placeholder. Do not advertise Vision gameplay until this is resolved. |

The public page shows 4.8 stars in both the US and UK snapshots checked. The UK page shows more ratings than the US page in the public web view, so UK performance should be reviewed separately rather than assumed to behave like US performance.

### App Store Connect Metadata Archive

Pulled with Helm CLI on 2026-06-24 from the live iOS and macOS 1.4.2 localizations. Name and subtitle are shared App Info fields; keywords are version- and platform-specific fields. The live keyword values matched across iOS and macOS.

| Locale | Live name | Live subtitle | Live keywords |
|---|---|---|---|
| en-US | `RetroRapid!` | `Retro racing at full speed` | `arcade,nostalgia,overtake,dodge,classic,pixel,fast,traffic,vintage,endless,car,lcd,race,rush,boost` |
| es-ES | `RetroRapid!` | `Carreras retro a tope` | `arcade,nostalgia,adelantamiento,esquivar,clásico,píxel,rápido,tráfico,vintage,coche,lcd,velocidad` |
| ca | `RetroRapid!` | `Retro racing at full speed` | `arcade,nostalgia,avançament,esquivar,clàssic,píxel,ràpid,tràfic,vintage,cotxe,lcd,cursa,velocitat` |
