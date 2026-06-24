# Staged Metadata Copy

Part of [App Store docs hub](../README.md). Index: [RETRORAPID_APP_STORE_REFERENCE.md](../RETRORAPID_APP_STORE_REFERENCE.md).

Last updated: 2026-06-24 (English subtitle cross-localization split)
**See also:** [Strategy](04-metadata-strategy.md) · [Validation](12-validation-results.md) · [Apply script](../scripts/apply_retrorapid_metadata.py)


---

### Localized Metadata

| Locale | App name | Name count | Subtitle | Subtitle count | Keywords | Keyword bytes |
|---|---|---:|---|---:|---|---:|
| en-US | `RetroRapid: Arcade Racer` | 24/30 | `Dodge Traffic Across 3 Lanes` | 28/30 | `car,high,score,overtake,reflex,offline,voiceover,haptics,controller,leaderboard,handheld,lcd,endless` | 100/100 |
| en-GB | `RetroRapid: Arcade Racer` | 24/30 | `Dodge Traffic Across 3 Lanes` | 28/30 | `endless,accessible,swift,highway,skill,vintage,drive,watch,game,nostalgia,pixel,boost,classic,reflex` | 100/100 |
| en-AU | `RetroRapid: Arcade Racer` | 24/30 | `Overtake Rivals. Beat Records` | 29/30 | `chase,mobile,quick,offline,voiceover,haptic,controller,handheld,lcd,leaderboard,high,score,ipad,mac` | 99/100 |
| en-CA | `RetroRapid: Arcade Racer` | 24/30 | `Chase Records in Quick Races` | 28/30 | `scoreboard,watch,game,classic,pixel,vintage,boost,nostalgia,ipad,mobile,haptic,lane,mac,drive,swift` | 99/100 |
| es-ES | `RetroRapid: Carreras Arcade` | 27/30 | `Esquiva tráfico en 3 carriles` | 29/30 | `coche,record,adelantar,reflejos,clasico,mando,ranking,infinito,puntuacion,conexion,voiceover,logros` | 99/100 |
| ca | `RetroRapid: Carreres Arcade` | 27/30 | `Esquiva trànsit en 3 carrils` | 28/30 | `cotxe,avancaments,reflexos,comandament,lcd,accessibilitat,joc,reloj,puntuacio,connexio,velocitat,mac` | 100/100 |
| es-MX | `RetroRapid: Carreras Arcade` | 27/30 | `Esquiva carros en 3 carriles` | 28/30 | `rebasar,reflejos,record,control,ranking,clasico,infinito,puntuacion,reloj,internet,trafico,logros` | 97/100 |

Notes:

- **App Store names use `RetroRapid:` not `RetroRapid!`**, matching Xarra (`Xarra: Read, Listen, Focus`) and Mestre (`Mestre: Screen Video Recorder`). The installed app name and in-app UI keep `RetroRapid!` via `BrandMark`.
- Colon avoids tying discovery to punctuation. Users typically search `RetroRapid` without `!`; Apple's search is generally punctuation-tolerant, but `:` is the portfolio convention and reads as a category separator on the store.
- Subtitles explain the actual mechanic in one readable phrase: dodge traffic across three lanes.
- Apple Watch moves out of the subtitle and into promotional text, platform-specific screenshots, and description. This keeps the main listing broadly appealing while preserving Watch as a differentiator.
- Hidden keywords deliberately omit terms already spent in visible metadata: `arcade`, `racer/racing`, `retro` (already in `RetroRapid`), `dodge/esquiva`, `traffic/tráfico/trànsit`, `carro/carros`, and `lane/carril`.
- **English cross-localization:** subtitles and keywords are split across locales that index together — **en-GB** + **en-AU** (UK/Australia) and **en-CA** + **en-US** (Canada). Do not repeat subtitle tokens or keyword tokens across paired locales.
- `en-GB` keeps the traffic-dodge mechanic subtitle; `en-AU` uses high-score/overtake wording. `en-US` keeps the mechanic subtitle; `en-CA` uses records/quick-races wording.
- `high,score` uses separate English tokens so App Store search can combine them into `high score` within the same locale.
- Dropped glued offline tokens (`sinconexion`, `sininternet`, `sensexarxa`). Use **`conexion`** (es-ES) and **`internet`** (es-MX) as separate keyword tokens instead; write full phrases such as *sin conexión* / *sin internet* in description and promo copy.
- Spanish (Mexico) uses **`carros`** in the subtitle and promo, and **`rebasar` / `control` / `internet` / `trafico` / `logros`** in hidden keywords — not **`carro`** (subtitle already uses `carros`).
- The Catalan field has spare capacity again after removing weak glued offline tokens. Revalidate UTF-8 bytes after any edit.
### Promotional Text

| Locale | Promotional text | Count |
|---|---|---:|
| en-US / en-GB / en-AU / en-CA | `Dodge traffic and chase high scores in quick retro races, with Game Center, Apple Watch support, and accessibility-first controls.` | 130/170 |
| es-ES | `Esquiva tráfico y supera tu récord en carreras retro rápidas, con Game Center, Apple Watch y controles accesibles.` | 114/170 |
| ca | `Esquiva trànsit i supera el teu rècord en carreres retro ràpides, amb Game Center, Apple Watch i controls accessibles.` | 118/170 |
| es-MX | `Esquiva carros y supera tu récord en carreras retro rápidas, con Game Center, Apple Watch y controles accesibles.` | 113/170 |

### Description Candidate

#### en-US / en-GB / en-AU / en-CA

```text
RetroRapid! is a fast 3-lane arcade racer built for quick sessions and high-score chasing.

Dodge traffic and survive as speed keeps rising. Controls are easy to learn and hard to master, so every run becomes a reflex challenge.

Why players keep coming back:
- Quick, one-more-run arcade gameplay
- Game Center leaderboards, achievements, and friend markers
- Play on iPhone, iPad, Mac, and Apple Watch
- Touch, swipe, keyboard, Digital Crown, and supported game controllers
- VoiceOver, audio cues, haptics, larger text, high contrast, and Reduce Motion support
- Works offline for quick races anytime
- Play free every day, or unlock Unlimited Plays once; no subscription
- No data collection

Crash, restart, and beat your best.
```

Count: 748/4000 characters.

#### es-ES

```text
RetroRapid! es un arcade de carreras de 3 carriles pensado para partidas rápidas y para perseguir tu mejor puntuación.

Esquiva tráfico y aguanta cuando la velocidad sube. Los controles son fáciles de aprender y difíciles de dominar, así que cada partida pone a prueba tus reflejos.

Por qué engancha:
- Jugabilidad arcade rápida de "una más"
- Clasificaciones, logros y marcadores de amigos de Game Center
- Juega en iPhone, iPad, Mac y Apple Watch
- Toque, deslizamiento, teclado, Digital Crown y mandos compatibles
- VoiceOver, pistas de audio, hápticos, texto más grande, alto contraste y reducción de movimiento
- Juega sin conexión para partidas rápidas en cualquier momento
- Juega gratis cada día o desbloquea Partidas ilimitadas con una sola compra; sin suscripción
- No se recopilan datos

Choca, reinicia y supera tu marca.
```

Count: 836/4000 characters.

#### ca

```text
RetroRapid! és un arcade de carreres de 3 carrils pensat per a partides ràpides i per a perseguir la teua millor puntuació.

Esquiva trànsit i resistix quan la velocitat puja. Els controls són fàcils d'aprendre i difícils de dominar, aixina que cada partida posa a prova els teus reflexos.

Per què enganxa:
- Jugabilitat arcade ràpida de "una més"
- Classificacions, assoliments i marcadors d'amistats de Game Center
- Juga en iPhone, iPad, Mac i Apple Watch
- Toc, lliscament, teclat, Digital Crown i comandaments compatibles
- VoiceOver, pistes d'àudio, hàptics, text més gran, alt contrast i reducció de moviment
- Juga sense connexió per a partides ràpides en qualsevol moment
- Juga gratis cada dia o desbloqueja Partides il·limitades amb una sola compra; sense subscripció
- No es recopilen dades

Xoca, reinicia i supera la teua marca.
```

Count: 778/4000 characters.

#### es-MX

```text
RetroRapid! es un arcade de carreras de 3 carriles pensado para partidas rápidas y para perseguir tu mejor récord.

Esquiva carros y rebasa cuando la velocidad sube. Los controles son fáciles de aprender y difíciles de dominar, así que cada partida pone a prueba tus reflejos.

Por qué engancha:
- Jugabilidad arcade rápida de "una más"
- Clasificaciones, logros y marcadores de amigos de Game Center
- Juega en iPhone, iPad, Mac y Apple Watch
- Toque, deslizamiento, teclado, Digital Crown y controles compatibles
- VoiceOver, pistas de audio, hápticos, texto más grande, alto contraste y reducción de movimiento
- Juega sin internet para partidas rápidas en cualquier momento
- Juega gratis cada día o desbloquea Partidas ilimitadas con una sola compra; sin suscripción
- No se recopilan datos

Choca, reinicia y supera tu récord.
```

Count: 834/4000 characters. Applied to iOS and macOS 1.5 **es-MX** drafts.

### What's New Candidate

Use this shape for the next bug-fix/polish release if there is no larger feature to lead with. It fixes the live brand mismatch and keeps Game Center value visible without over-explaining.

#### en-US / en-GB / en-AU / en-CA

```text
This update sharpens RetroRapid! with bug fixes and racing polish. The Game Center update is still the star: earn achievements, chase friends on the track, and share clean snapshots of your best runs. Thanks for racing with us.
```

Count: 227/4000 characters.

#### es-ES

```text
Esta actualización hace que RetroRapid! sea más estable y fiable. Game Center sigue siendo la estrella: logros, amigos en la pista y capturas limpias para compartir tus mejores partidas. Gracias por correr con nosotros.
```

Count: 219/4000 characters.

#### es-MX

```text
Esta actualización hace que RetroRapid! sea más estable y fiable. Game Center sigue siendo la estrella: logros, amigos en la pista y capturas limpias para compartir tus mejores partidas. Gracias por correr con nosotros.
```

Count: 219/4000 characters.

#### ca

```text
Esta actualització fa que RetroRapid! siga més estable i fiable. Game Center continua sent l'estrela: assoliments, amistats en la pista i captures netes per a compartir les teues millors partides. Gràcies per córrer amb nosaltres.
```

Count: 230/4000 characters.
