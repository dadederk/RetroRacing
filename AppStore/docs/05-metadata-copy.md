# Staged Metadata Copy

Part of [App Store docs hub](../README.md).

Last updated: 2026-07-17

**Status:** `DRAFT_APPLIED` — see field-level status in `12-validation-results.md`.

**Canonical source:** [metadata/retrorapid-v1.5.json](../metadata/retrorapid-v1.5.json). Do not edit generated copy directly.

**See also:** [Strategy](04-metadata-strategy.md) · [Validation](12-validation-results.md) · [Apply script](../../Scripts/README.md)

---

## Localized Metadata

| Locale | App name | Name count | Subtitle | Subtitle count | Keywords | Keyword bytes |
|---|---|---:|---|---:|---|---:|
| en-US | `RetroRapid: Retro Arcade Racer` | 30/30 | `Dodge Traffic Across 3 Lanes` | 28/30 | `car,high,score,overtake,reflex,offline,voiceover,haptics,controller,leaderboard,handheld,lcd,endless` | 100/100 |
| en-GB | `RetroRapid: Retro Arcade Racer` | 30/30 | `Dodge Traffic Across 3 Lanes` | 28/30 | `endless,accessible,swift,highway,skill,vintage,drive,watch,game,nostalgia,pixel,boost,classic,reflex` | 100/100 |
| en-AU | `RetroRapid: Retro Arcade Racer` | 30/30 | `Overtake Rivals. Beat Records` | 29/30 | `chase,mobile,quick,offline,voiceover,haptic,controller,handheld,lcd,leaderboard,high,score,ipad,mac` | 99/100 |
| en-CA | `RetroRapid: Retro Arcade Racer` | 30/30 | `Chase Records in Quick Races` | 28/30 | `scoreboard,watch,game,classic,pixel,vintage,boost,nostalgia,ipad,mobile,haptic,lane,mac,drive,swift` | 99/100 |
| es-ES | `RetroRapid: Carreras Arcade` | 27/30 | `Esquiva tráfico en 3 carriles` | 29/30 | `coche,record,adelantar,reflejos,clasico,mando,ranking,infinito,puntuacion,conexion,voiceover,logros` | 99/100 |
| ca | `RetroRapid: Carreres Arcade` | 27/30 | `Esquiva trànsit en 3 carrils` | 28/30 | `cotxe,avancaments,reflexos,comandament,lcd,accessibilitat,joc,reloj,puntuacio,connexio,velocitat,mac` | 100/100 |
| es-MX | `RetroRapid: Carreras Arcade` | 27/30 | `Esquiva carros en 3 carriles` | 28/30 | `rebasar,reflejos,record,control,ranking,clasico,infinito,puntuacion,reloj,internet,trafico,logros` | 97/100 |

Notes:

- App Store names use `RetroRapid:` while the installed app and in-app UI retain `RetroRapid!` through `BrandMark`.
- Subtitles explain the actual mechanic in readable language; hidden keywords cover supporting search intents.
- Apple Watch remains in promotional text, screenshots, and descriptions instead of the subtitle.
- English cross-localization splits subtitles and keywords across `en-GB`/`en-AU` and `en-CA`/`en-US`.
- Spanish offline intent uses `conexion` in `es-ES` and `internet` in `es-MX`; full phrases remain in visible descriptions.
- Re-run the generator after any catalog edit; UTF-8 keyword bytes are validated automatically.

## Promotional Text

| Locale | Promotional text | Count |
|---|---|---:|
| en-US / en-GB / en-AU / en-CA | `Dodge traffic and chase high scores in quick retro races, with Game Center, Apple Watch support, and accessibility-first controls.` | 130/170 |
| es-ES | `Esquiva tráfico y supera tu récord en carreras retro rápidas, con Game Center, Apple Watch y controles accesibles.` | 114/170 |
| ca | `Esquiva trànsit i supera el teu rècord en carreres retro ràpides, amb Game Center, Apple Watch i controls accessibles.` | 118/170 |
| es-MX | `Esquiva carros y supera tu récord en carreras retro rápidas, con Game Center, Apple Watch y controles accesibles.` | 113/170 |

## Description Candidate

### en-US / en-GB / en-AU / en-CA

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

Players are saying:
"I am really a fan of this nice accessible game that I can just pick up and play! Finally, something that also works with the apple watch!"
— Datafile, App Store review

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
"But beyond the nostalgia and tight gameplay, what truly stands out is its accessibility."
```

Count: 1092/4000 characters.

### es-ES

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

Lo que dicen los jugadores:
"Un juego simplemente accesible y simplemente entretenido. Muy recomendable."
— Jonathan Chacón, reseña en el App Store

Destacado en Create with Swift, Boletín semanal n.º 96 (App Indie de la Semana):
"Más allá de la nostalgia y la jugabilidad ajustada, lo que realmente destaca es su accesibilidad."
```

Count: 1165/4000 characters.

### ca

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

Destacat a Create with Swift, Butlletí setmanal núm. 96 (App Indie de la Setmana):
"Més enllà de la nostàlgia i la jugabilitat ajustada, allò que realment destaca és la seua accessibilitat."
```

Count: 1035/4000 characters.

### es-MX

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

Lo que dicen los jugadores:
"Un juego simplemente accesible y simplemente entretenido. Muy recomendable."
— Jonathan Chacón, reseña en el App Store

Destacado en Create with Swift, Boletín semanal n.º 96 (App Indie de la Semana):
"Más allá de la nostalgia y la jugabilidad ajustada, lo que realmente destaca es su accesibilidad."
```

Count: 1163/4000 characters.

## What's New Candidate

Use this shape for the next bug-fix or polish release if there is no larger feature to lead with.

### en-US / en-GB / en-AU / en-CA

```text
This update sharpens RetroRapid! with bug fixes and racing polish. The Game Center update is still the star: earn achievements, chase friends on the track, and share clean snapshots of your best runs. Thanks for racing with us.
```

Count: 227/4000 characters.

### es-ES / es-MX

```text
Esta actualización pule RetroRapid! con correcciones de errores y mejoras de conducción. La actualización de Game Center sigue siendo la protagonista: consigue logros, persigue a tus amigos en la pista y comparte capturas limpias de tus mejores partidas. Gracias por correr con nosotros.
```

Count: 287/4000 characters.

### ca

```text
Esta actualització poleix RetroRapid! amb correccions d'errors i millores de conducció. L'actualització de Game Center continua sent la protagonista: consegueix assoliments, persegueix als teus amics en la pista i comparteix captures netes de les teues millors partides. Gràcies per córrer amb nosaltres.
```

Count: 304/4000 characters.

_Generated by `swift run --package-path Scripts generate-metadata-docs`._
