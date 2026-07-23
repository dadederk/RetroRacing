# Staged Metadata Copy

Part of [App Store docs hub](../README.md).

Last updated: 2026-07-23

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
| de-DE | `RetroRapid: Arcade Rennspiel` | 28/30 | `Weiche Verkehr auf 3 Spuren` | 27/30 | `rekord,controller,uhr,reaktion,klassisch,endlos,punkte,barrierefrei,erfolge,mac,ipad,wagen,rennen` | 97/100 |
| nl-NL | `RetroRapid: Arcade Race Spel` | 28/30 | `Ontwijk verkeer in 3 banen` | 26/30 | `reflex,controller,horloge,reactie,klassiek,oneindig,toegankelijk,prestaties,mac,ipad,snelheid,baan` | 98/100 |
| it | `RetroRapid: Retro Corse Arcade` | 30/30 | `Schiva il traffico in 3 corsie` | 30/30 | `record,controller,orologio,reazione,classico,infinito,punteggio,successi,riflessi,ipad,veloce,mac` | 97/100 |
| fr-FR | `RetroRapid: Retro Course Autos` | 30/30 | `Esquive le trafic, 3 voies` | 26/30 | `reflexes,manette,montre,reaction,classique,infini,accessibilite,mac,ipad,succes,classement,horsligne` | 100/100 |
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
| de-DE | `Weiche Verkehr aus und jage Highscores in schnellen Retro-Rennen – mit Game Center, Apple Watch und barrierefreien Steuerungen.` | 127/170 |
| nl-NL | `Ontwijk verkeer en jaag op highscores in snelle retro-races, met Game Center, Apple Watch en toegankelijke besturing.` | 117/170 |
| it | `Schiva il traffico e punta al record in corse retrò veloci, con Game Center, Apple Watch e controlli accessibili.` | 113/170 |
| fr-FR | `Esquive le trafic et bats ton record dans des courses rétro rapides, avec Game Center, Apple Watch et des commandes accessibles.` | 128/170 |
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

### de-DE

```text
RetroRapid! ist ein schnelles 3-Spuren-Arcade-Rennspiel für kurze Sessions und die Jagd nach Highscores.

Weiche dem Verkehr aus und halte durch, wenn das Tempo steigt. Die Steuerung ist leicht zu lernen und schwer zu meistern – jede Runde wird zur Reflexprüfung.

Warum Spieler wiederkommen:
- Schnelles Arcade-Gameplay für "noch eine Runde"
- Game-Center-Bestenlisten, Erfolge und Freundesmarker
- Spiele auf iPhone, iPad, Mac und Apple Watch
- Touch, Wischen, Tastatur, Digital Crown und unterstützte Controller
- VoiceOver, Audiohinweise, Haptik, größerer Text, hoher Kontrast und Bewegung reduzieren
- Funktioniert offline für schnelle Runden jederzeit
- Spiele jeden Tag gratis oder schalte Unbegrenzte Spiele einmal frei – kein Abo
- Keine Datenerfassung

Crash, neu starten und schlage deinen Rekord.

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
"Doch abgesehen von der Nostalgie und dem straffen Gameplay sticht vor allem die Barrierefreiheit hervor."
```

Count: 994/4000 characters.

### nl-NL

```text
RetroRapid! is een snelle 3-baans arcade-racer voor korte sessies en highscore-jagen.

Ontwijk verkeer en houd vol terwijl het tempo stijgt. Besturing is makkelijk te leren en moeilijk te beheersen, dus elke run wordt een reflextest.

Waarom spelers blijven terugkomen:
- Snel arcade-gameplay voor "nog eentje dan"
- Game Center-ranglijsten, prestaties en vriendenmarkeringen
- Speel op iPhone, iPad, Mac en Apple Watch
- Touch, vegen, toetsenbord, Digital Crown en ondersteunde controllers
- VoiceOver, audiosignalen, haptiek, grotere tekst, hoog contrast en Verminder beweging
- Werkt offline voor snelle races wanneer je wilt
- Speel elke dag gratis of ontgrendel Onbeperkt spelen eenmalig – geen abonnement
- Geen gegevensverzameling

Crash, herstart en verbeter je record.

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
"Maar naast de nostalgie en strakke gameplay valt vooral de toegankelijkheid op."
```

Count: 938/4000 characters.

### it

```text
RetroRapid! è un arcade di corse a 3 corsie pensato per sessioni rapide e per inseguire il tuo miglior punteggio.

Schiva il traffico e resisti mentre la velocità aumenta. I controlli sono facili da imparare e difficili da padroneggiare, quindi ogni partita mette alla prova i tuoi riflessi.

Perché i giocatori tornano:
- Gameplay arcade veloce da "ancora una"
- Classifiche, obiettivi e marcatori amici di Game Center
- Gioca su iPhone, iPad, Mac e Apple Watch
- Tocco, swipe, tastiera, Digital Crown e controller supportati
- VoiceOver, segnali audio, haptica, testo più grande, alto contrasto e Riduci movimento
- Funziona offline per corse veloci in qualsiasi momento
- Gioca gratis ogni giorno o sblocca Partite illimitate con un solo acquisto – nessun abbonamento
- Nessuna raccolta dati

Schianto, riparti e batti il tuo record.

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
"Ma oltre alla nostalgia e al gameplay serrato, ciò che davvero spicca è l'accessibilità."
```

Count: 1006/4000 characters.

### fr-FR

```text
RetroRapid! est un arcade de course à 3 voies pensé pour des parties rapides et pour chasser ton meilleur score.

Esquive le trafic et tiens bon quand la vitesse monte. Les commandes sont faciles à apprendre et difficiles à maîtriser, donc chaque partie teste tes réflexes.

Pourquoi les joueurs reviennent :
- Gameplay arcade rapide "encore une"
- Classements, succès et marqueurs d'amis Game Center
- Joue sur iPhone, iPad, Mac et Apple Watch
- Toucher, glisser, clavier, Digital Crown et manettes compatibles
- VoiceOver, indices audio, haptique, texte plus grand, contraste élevé et Réduire les animations
- Fonctionne hors ligne pour des courses rapides à tout moment
- Joue gratuitement chaque jour ou débloque Parties illimitées en un seul achat – pas d'abonnement
- Aucune collecte de données

Crash, redémarre et bats ton record.

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week) :
"Au-delà de la nostalgie et du gameplay serré, ce qui ressort vraiment, c'est l'accessibilité."
```

Count: 1014/4000 characters.

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
Race friends live with SharePlay on iPhone and iPad — synchronized countdowns, shared win/loss/tie results, and free rematches that wait until both players are ready.

RetroRapid! now speaks German, Dutch, Italian, and French across the app, alongside Spanish and Catalan.

We've also polished settings, audio, and stability across iPhone, iPad, Mac, and Apple Watch.

If you're catching up: recent releases added Game Center achievements, friend markers during races, and shareable result snapshots, along with accessibility improvements and Spanish and Catalan localization.

Thanks for racing with us.
```

Count: 604/4000 characters.

### de-DE

```text
Rase live mit Freunden per SharePlay auf iPhone und iPad — synchronisierte Countdowns, gemeinsame Sieg-/Niederlage-/Unentschieden-Ergebnisse und kostenlose Rematches, die warten, bis beide Spieler bereit sind.

RetroRapid! spricht jetzt Deutsch, Niederländisch, Italienisch und Französisch in der gesamten App, zusätzlich zu Spanisch und Katalanisch.

Außerdem haben wir Einstellungen, Audio und Stabilität auf iPhone, iPad, Mac und Apple Watch verbessert.

Falls du aufholst: In den letzten Versionen kamen Game-Center-Erfolge, Freundesmarker auf der Strecke und teilbare Ergebnis-Screenshots hinzu, dazu Barrierefreiheitsverbesserungen sowie spanische und katalanische Lokalisierung.

Danke, dass du mit uns fährst.
```

Count: 717/4000 characters.

### nl-NL

```text
Race live met vrienden via SharePlay op iPhone en iPad — gesynchroniseerde countdowns, gedeelde winst/verlies/gelijkspel-resultaten en gratis rematches die wachten tot beide spelers klaar zijn.

RetroRapid! spreekt nu Duits, Nederlands, Italiaans en Frans in de hele app, naast Spaans en Catalaans.

We hebben ook instellingen, audio en stabiliteit verbeterd op iPhone, iPad, Mac en Apple Watch.

Als je bij bent: recente releases voegden Game Center-prestaties, vriendenmarkeringen tijdens races en deelbare resultaat-screenshots toe, plus toegankelijkheidsverbeteringen en Spaanse en Catalaanse localisatie.

Bedankt dat je met ons rijdt.
```

Count: 640/4000 characters.

### it

```text
Corri in diretta con gli amici tramite SharePlay su iPhone e iPad — countdown sincronizzati, risultati condivisi di vittoria/sconfitta/parità e rematch gratuiti che aspettano che entrambi i giocatori siano pronti.

RetroRapid! ora parla tedesco, olandese, italiano e francese in tutta l'app, oltre a spagnolo e catalano.

Abbiamo anche rifinito impostazioni, audio e stabilità su iPhone, iPad, Mac e Apple Watch.

Se ti stai aggiornando: le versioni recenti hanno aggiunto obiettivi Game Center, marcatori amici in gara e screenshot condivisibili dei risultati, oltre a miglioramenti di accessibilità e localizzazione in spagnolo e catalano.

Grazie per correre con noi.
```

Count: 670/4000 characters.

### fr-FR

```text
Course en direct avec tes amis via SharePlay sur iPhone et iPad — comptes à rebours synchronisés, résultats victoire/défaite/égalité partagés et revanches gratuites qui attendent que les deux joueurs soient prêts.

RetroRapid! parle désormais allemand, néerlandais, italien et français dans toute l'app, en plus de l'espagnol et du catalan.

Nous avons aussi peaufiné les réglages, l'audio et la stabilité sur iPhone, iPad, Mac et Apple Watch.

Si tu rattrapes le train : les versions récentes ont ajouté des succès Game Center, des marqueurs d'amis en course et des captures de résultats partageables, ainsi que des améliorations d'accessibilité et une localisation en espagnol et catalan.

Merci de courir avec nous.
```

Count: 718/4000 characters.

### es-ES / es-MX

```text
Corre en vivo con amigos gracias a SharePlay en iPhone e iPad: cuenta atrás sincronizada, mismos resultados de victoria, derrota o empate y revanchas gratis que esperan a que ambos jugadores estén listos.

RetroRapid! ya habla alemán, neerlandés, italiano y francés en toda la app, además de español y catalán.

También hemos pulido ajustes, audio y estabilidad en iPhone, iPad, Mac y Apple Watch.

Si te pones al día: versiones recientes añadieron logros de Game Center, marcadores de amigos en pista y capturas de resultados para compartir, junto con mejoras de accesibilidad y localización en español y catalán.

Gracias por correr con nosotros.
```

Count: 648/4000 characters.

### ca

```text
Corre en viu amb amics amb SharePlay a iPhone i iPad: compte enrere sincronitzat, mateixos resultats de victòria, derrota o empat i revanxes gratuïtes que esperen que els dos jugadors estiguen llestos.

RetroRapid! ara parla alemany, neerlandès, italià i francès a tota l'app, a més de castellà i català.

També hem polix ajustos, àudio i estabilitat a iPhone, iPad, Mac i Apple Watch.

Si et poses al dia: versions recents van afegir assoliments de Game Center, marcadors d'amistats en pista i captures de resultats per a compartir, juntament amb millores d'accessibilitat i localització en castellà i català.

Gràcies per córrer amb nosaltres.
```

Count: 645/4000 characters.

_Generated by `swift run --package-path Scripts generate-metadata-docs`._
