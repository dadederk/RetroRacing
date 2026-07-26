# Staged Metadata Copy

Part of [App Store docs hub](../README.md).

Last updated: 2026-07-26

**Status:** `DRAFT_APPLIED` — see field-level status in `12-validation-results.md`.

**Canonical source:** [metadata/retrorapid-v1.5.json](../metadata/retrorapid-v1.5.json). Do not edit generated copy directly.

**See also:** [Strategy](04-metadata-strategy.md) · [Validation](12-validation-results.md) · [Apply script](../../Scripts/README.md)

---

## Localized Metadata

| Locale | App name | Name count | Subtitle | Subtitle count | Keywords | Keyword bytes |
|---|---|---:|---|---:|---|---:|
| en-US | `RetroRapid: Retro Arcade Racer` | 30/30 | `Dodge Traffic Across 3 Lanes` | 28/30 | `car,high,score,overtake,reflex,offline,voiceover,haptics,controller,leaderboard,handheld,lcd,friends` | 100/100 |
| en-GB | `RetroRapid: Retro Arcade Racer` | 30/30 | `Dodge Traffic Across 3 Lanes` | 28/30 | `endless,accessible,swift,highway,skill,vintage,drive,watch,game,nostalgia,pixel,boost,classic,reflex` | 100/100 |
| en-AU | `RetroRapid: Retro Arcade Racer` | 30/30 | `Overtake Rivals. Beat Records` | 29/30 | `chase,mobile,quick,offline,voiceover,haptic,controller,handheld,lcd,leaderboard,high,score,ipad,mac` | 99/100 |
| en-CA | `RetroRapid: Retro Arcade Racer` | 30/30 | `Chase Records in Quick Races` | 28/30 | `scoreboard,watch,game,classic,pixel,vintage,boost,nostalgia,ipad,mobile,haptic,lane,mac,drive,swift` | 99/100 |
| de-DE | `RetroRapid: Arcade Rennspiel` | 28/30 | `Weiche Verkehr auf 3 Spuren` | 27/30 | `rekord,controller,uhr,reaktion,klassisch,endlos,punkte,barrierefrei,erfolge,mac,ipad,wagen,rennen` | 97/100 |
| nl-NL | `RetroRapid: Arcade Race Spel` | 28/30 | `Ontwijk verkeer in 3 banen` | 26/30 | `reflex,controller,horloge,reactie,klassiek,oneindig,toegankelijk,prestaties,mac,ipad,snelheid,baan` | 98/100 |
| it | `RetroRapid: Retro Corse Arcade` | 30/30 | `Schiva il traffico in 3 corsie` | 30/30 | `record,controller,orologio,reazione,classico,infinito,punteggio,successi,riflessi,ipad,veloce,mac` | 97/100 |
| fr-FR | `RetroRapid: Retro Course Autos` | 30/30 | `Esquive le trafic, 3 voies` | 26/30 | `reflexes,manette,montre,reaction,classique,infini,accessibilite,mac,ipad,succes,classement,horsligne` | 100/100 |
| fr-CA | `RetroRapid: Course Autos Retro` | 30/30 | `Évitez le trafic, 3 voies` | 25/30 | `evitement,haptique,partage,amis,parties,illimite,score,reflexe,competitif,vivant,duo,watch,arcade` | 97/100 |
| es-ES | `RetroRapid: Carreras Arcade` | 27/30 | `Esquiva tráfico en 3 carriles` | 29/30 | `coche,record,adelantar,reflejos,clasico,mando,ranking,infinito,puntuacion,conexion,voiceover,logros` | 99/100 |
| ca | `RetroRapid: Carreres Arcade` | 27/30 | `Esquiva trànsit en 3 carrils` | 28/30 | `cotxe,avancaments,reflexos,comandament,lcd,accessibilitat,joc,reloj,puntuacio,connexio,velocitat,mac` | 100/100 |
| es-MX | `RetroRapid: Carreras Arcade` | 27/30 | `Esquiva carros en 3 carriles` | 28/30 | `rebasar,reflejos,record,control,ranking,clasico,infinito,puntuacion,reloj,internet,trafico,logros` | 97/100 |
| ja | `RetroRapid: レトロアーケード` | 20/30 | `3レーン交通回避レース` | 11/30 | `追い抜き,反射神経,無制限,オフライン,実績解除,ハイスコア,ランキング` | 96/100 |
| ko | `RetroRapid: 레트로 아케이드` | 20/30 | `3차선 교통 회피 레이싱` | 13/30 | `추월하기,반사신경,무제한,오프라인,햅틱피드백,컨트롤러,업적달성,SharePlay` | 100/100 |
| pt-BR | `RetroRapid: Corrida Arcade` | 26/30 | `Desvie tráfego em 3 faixas` | 26/30 | `ultrapassar,reflexo,pontuacao,haptico,controle,watch,conquista,conexao,recorde,pixel,classico,turbo` | 99/100 |
| pt-PT | `RetroRapid: Corrida Arcade` | 26/30 | `Desvie o trânsito em 3 faixas` | 29/30 | `ultrapassagem,reflexos,classificacao,comando,relogio,infinito,offline,ipad,ecra,partida,ranking,fast` | 100/100 |
| zh-Hant | `RetroRapid: 復古街機賽車` | 18/30 | `三線道閃避無盡交通` | 9/30 | `超車競賽,反射神經,離線遊玩,觸覺回饋,控制器,AppleWatch,成就解鎖,排行榜,race` | 100/100 |
| zh-Hans | `RetroRapid: 复古街机赛车` | 18/30 | `三车道闪避无尽车流` | 9/30 | `超车赛,反应力,离线玩,触感反馈,手柄支持,无障碍,分数榜,成就榜,智能手表` | 98/100 |

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
| en-US / en-GB / en-AU / en-CA | `Race friends free with SharePlay on iPhone and iPad. Dodge traffic together, rematch fast, and keep solo runs quick anywhere.` | 125/170 |
| de-DE | `Weiche Verkehr aus und jage Highscores in schnellen Retro-Rennen – mit Game Center, Apple Watch und barrierefreien Steuerungen.` | 127/170 |
| nl-NL | `Ontwijk verkeer en jaag op highscores in snelle retro-races, met Game Center, Apple Watch en toegankelijke besturing.` | 117/170 |
| it | `Schiva il traffico e punta al record in corse retrò veloci, con Game Center, Apple Watch e controlli accessibili.` | 113/170 |
| fr-FR | `Esquive le trafic et bats ton record dans des courses rétro rapides, avec Game Center, Apple Watch et des commandes accessibles.` | 128/170 |
| fr-CA | `Courses entre amis gratuites avec SharePlay sur iPhone et iPad. Évitez le trafic dans un arcade rétro à 3 voies, avec VoiceOver et Parties illimitées.` | 150/170 |
| es-ES | `Esquiva tráfico y supera tu récord en carreras retro rápidas, con Game Center, Apple Watch y controles accesibles.` | 114/170 |
| ca | `Esquiva trànsit i supera el teu rècord en carreres retro ràpides, amb Game Center, Apple Watch i controls accessibles.` | 118/170 |
| es-MX | `Esquiva carros y supera tu récord en carreras retro rápidas, con Game Center, Apple Watch y controles accesibles.` | 113/170 |
| ja | `iPhoneとiPadでSharePlayのフレンドレースが無料。3レーンのレトロアーケードで交通を避け、ハイスコアを狙おう。` | 63/170 |
| ko | `iPhone과 iPad에서 SharePlay 친구 레이스가 무료예요. 3차선 레트로 아케이드에서 교통을 피하고 하이스코어에 도전하세요.` | 75/170 |
| pt-BR | `Corridas com amigos grátis no SharePlay no iPhone e iPad. Desvie tráfego em um arcade retrô de 3 faixas e busque seu recorde.` | 125/170 |
| pt-PT | `Corridas com amigos grátis no SharePlay no iPhone e iPad. Desvie o trânsito num arcade retrô de 3 faixas, com VoiceOver e Partidas Ilimitadas.` | 142/170 |
| zh-Hant | `在 iPhone 與 iPad 上透過 SharePlay 免費與好友競賽。在三線道復古街機中閃避車流，挑戰最高分。` | 58/170 |
| zh-Hans | `在 iPhone 与 iPad 上通过 SharePlay 免费与好友竞赛。三车道复古街机闪避车流，支持 VoiceOver，可解锁无限畅玩。` | 71/170 |

## Description Candidate

### en-US / en-GB / en-AU / en-CA

```text
RetroRapid! is a fast 3-lane arcade racer built for quick sessions and high-score chasing.

Dodge traffic and survive as speed keeps rising. Controls are easy to learn and hard to master, so every run becomes a reflex challenge.

Why players keep coming back:
- Quick, one-more-run arcade gameplay
- Live two-player SharePlay races on iPhone and iPad
- Friend races are free and never use daily plays
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
- Datafile, App Store review

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
"But beyond the nostalgia and tight gameplay, what truly stands out is its accessibility."
```

Count: 1195/4000 characters.

### de-DE

```text
RetroRapid! ist ein schnelles 3-Spuren-Arcade-Rennspiel für kurze Sessions und die Jagd nach Highscores.

Weiche dem Verkehr aus und halte durch, wenn das Tempo steigt. Die Steuerung ist leicht zu lernen und schwer zu meistern – jede Runde wird zur Reflexprüfung.

Warum Spieler wiederkommen:
- Schnelles Arcade-Gameplay für "noch eine Runde"
- Live-Zweispieler-SharePlay-Rennen auf iPhone und iPad
- Freundesrennen sind gratis und verbrauchen keine Tages-Spiele
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

Count: 1114/4000 characters.

### nl-NL

```text
RetroRapid! is een snelle 3-baans arcade-racer voor korte sessies en highscore-jagen.

Ontwijk verkeer en houd vol terwijl het tempo stijgt. Besturing is makkelijk te leren en moeilijk te beheersen, dus elke run wordt een reflextest.

Waarom spelers blijven terugkomen:
- Snel arcade-gameplay voor "nog eentje dan"
- Live SharePlay-races voor twee spelers op iPhone en iPad
- Vriendenraces zijn gratis en gebruiken geen dagelijkse spelen
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

Count: 1061/4000 characters.

### it

```text
RetroRapid! è un arcade di corse a 3 corsie pensato per sessioni rapide e per inseguire il tuo miglior punteggio.

Schiva il traffico e resisti mentre la velocità aumenta. I controlli sono facili da imparare e difficili da padroneggiare, quindi ogni partita mette alla prova i tuoi riflessi.

Perché i giocatori tornano:
- Gameplay arcade veloce da "ancora una"
- Corse SharePlay live per due giocatori su iPhone e iPad
- Le gare con amici sono gratis e non consumano partite giornaliere
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

Count: 1132/4000 characters.

### fr-FR

```text
RetroRapid! est un arcade de course à 3 voies pensé pour des parties rapides et pour chasser ton meilleur score.

Esquive le trafic et tiens bon quand la vitesse monte. Les commandes sont faciles à apprendre et difficiles à maîtriser, donc chaque partie teste tes réflexes.

Pourquoi les joueurs reviennent :
- Gameplay arcade rapide "encore une"
- Courses SharePlay en direct à deux joueurs sur iPhone et iPad
- Les courses entre amis sont gratuites et n'utilisent pas les parties quotidiennes
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

Count: 1162/4000 characters.

### fr-CA

```text
RetroRapid! est un arcade de course à 3 voies pensé pour des parties rapides et pour chasser votre meilleur score.

Évitez le trafic et tenez bon quand la vitesse monte. Les commandes sont faciles à apprendre et difficiles à maîtriser, donc chaque partie teste vos réflexes.

Pourquoi les joueurs reviennent :
- Gameplay arcade rapide « encore une »
- Courses SharePlay en direct à deux joueurs sur iPhone et iPad
- Les courses entre amis sont gratuites et n'utilisent pas les parties quotidiennes
- Classements, succès et marqueurs d'amis Game Center
- Jouez sur iPhone, iPad, Mac et Apple Watch
- Toucher, glisser, clavier, Digital Crown et manettes compatibles
- VoiceOver, indices audio, haptique, texte plus grand, contraste élevé et Réduire le mouvement
- Fonctionne hors ligne pour des courses rapides en tout temps
- Jouez gratuitement chaque jour ou débloquez Parties illimitées en un seul achat – pas d'abonnement
- Aucune collecte de données

Crash, redémarrez et battez votre record.

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week) :
« Au-delà de la nostalgie et du gameplay serré, ce qui ressort vraiment, c'est l'accessibilité. »
```

Count: 1173/4000 characters.

### es-ES

```text
RetroRapid! es un arcade de carreras de 3 carriles pensado para partidas rápidas y para perseguir tu mejor puntuación.

Esquiva tráfico y aguanta cuando la velocidad sube. Los controles son fáciles de aprender y difíciles de dominar, así que cada partida pone a prueba tus reflejos.

Por qué engancha:
- Jugabilidad arcade rápida de "una más"
- Carreras SharePlay en vivo para dos jugadores en iPhone e iPad
- Las carreras con amigos son gratis y no consumen partidas diarias
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
- Jonathan Chacón, reseña en el App Store

Destacado en Create with Swift, Boletín semanal n.º 96 (App Indie de la Semana):
"Más allá de la nostalgia y la jugabilidad ajustada, lo que realmente destaca es su accesibilidad."
```

Count: 1298/4000 characters.

### ca

```text
RetroRapid! és un arcade de carreres de 3 carrils pensat per a partides ràpides i per a perseguir la teua millor puntuació.

Esquiva trànsit i resistix quan la velocitat puja. Els controls són fàcils d'aprendre i difícils de dominar, aixina que cada partida posa a prova els teus reflexos.

Per què enganxa:
- Jugabilitat arcade ràpida de "una més"
- Carreres SharePlay en viu per a dos jugadors a iPhone i iPad
- Les carreres amb amics són gratuïtes i no consumeixen partides diàries
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

Count: 1171/4000 characters.

### es-MX

```text
RetroRapid! es un arcade de carreras de 3 carriles pensado para partidas rápidas y para perseguir tu mejor récord.

Esquiva carros y rebasa cuando la velocidad sube. Los controles son fáciles de aprender y difíciles de dominar, así que cada partida pone a prueba tus reflejos.

Por qué engancha:
- Jugabilidad arcade rápida de "una más"
- Carreras SharePlay en vivo para dos jugadores en iPhone e iPad
- Las carreras con amigos son gratis y no consumen partidas diarias
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
- Jonathan Chacón, reseña en el App Store

Destacado en Create with Swift, Boletín semanal n.º 96 (App Indie de la Semana):
"Más allá de la nostalgia y la jugabilidad ajustada, lo que realmente destaca es su accesibilidad."
```

Count: 1296/4000 characters.

### ja

```text
RetroRapid!は、短時間プレイとハイスコア更新に最適な3レーンのアーケードレースゲームです。

交通を避け、スピードが上がるほど生き残れ。操作は覚えやすく、極めるのは難しい。だから毎ラウンドが反射神経の勝負になります。

プレイヤーが戻ってくる理由:
- 「もう1回」が止まらない高速アーケード
- iPhone/iPadでのSharePlayライブ2人対戦
- フレンドレースは無料でデイリープレイを消費しない
- Game Centerランキング、実績、フレンドマーカー
- iPhone、iPad、Mac、Apple Watchでプレイ
- タッチ、スワイプ、キーボード、Digital Crown、対応コントローラ
- VoiceOver、音声キュー、触覚、大きい文字、高コントラスト、視差効果を減らす
- オフラインでもすぐレース可能
- 毎日無料プレイ、または買い切りで無制限プレイ（サブスクなし）
- データ収集なし

クラッシュして、すぐ再スタート。ベストを更新しよう。

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
「ノスタルジーと手触りの良いゲームプレイに加え、特に際立つのがアクセシビリティ。」
```

Count: 568/4000 characters.

### ko

```text
RetroRapid!는 짧은 세션과 하이스코어 도전에 맞춘 3차선 아케이드 레이싱 게임이에요.

교통을 피하고 속도가 올라갈수록 버텨 보세요. 조작은 배우기 쉽고 마스터하기 어려워서 매 판이 반사 신경 테스트가 됩니다.

플레이어가 계속 돌아오는 이유:
- "한 판 더"가 멈추지 않는 빠른 아케이드
- iPhone/iPad SharePlay 라이브 2인 레이스
- 친구 레이스는 무료이며 일일 플레이를 사용하지 않음
- Game Center 리더보드, 업적, 친구 마커
- iPhone, iPad, Mac, Apple Watch에서 플레이
- 터치, 스와이프, 키보드, Digital Crown, 지원 컨트롤러
- VoiceOver, 오디오 큐, 햅틱, 큰 텍스트, 고대비, 동작 줄이기
- 오프라인에서도 빠른 레이스 가능
- 매일 무료 플레이 또는 1회 구매로 무제한 플레이, 구독 없음
- 데이터 수집 없음

충돌하고, 다시 시작하고, 최고 기록을 갱신하세요.

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
"향수와 탄탄한 게임플레이를 넘어, 진짜 돋보이는 건 접근성이에요."
```

Count: 602/4000 characters.

### pt-BR

```text
RetroRapid! é um arcade de corrida de 3 faixas feito para sessões rápidas e para perseguir seu recorde.

Desvie do tráfego e aguente enquanto a velocidade sobe. Os controles são fáceis de aprender e difíceis de dominar, então cada corrida vira um teste de reflexos.

Por que os jogadores voltam:
- Gameplay arcade rápido de "só mais uma"
- Corridas SharePlay ao vivo para dois jogadores no iPhone e iPad
- Corridas com amigos são grátis e não usam partidas diárias
- Rankings, conquistas e marcadores de amigos do Game Center
- Jogue no iPhone, iPad, Mac e Apple Watch
- Toque, deslize, teclado, Digital Crown e controles compatíveis
- VoiceOver, pistas sonoras, háptico, texto maior, alto contraste e Reduzir Movimento
- Funciona offline para corridas rápidas a qualquer hora
- Jogue grátis todo dia ou desbloqueie Partidas Ilimitadas com compra única, sem assinatura
- Sem coleta de dados

Bata, reinicie e supere seu recorde.

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
"Além da nostalgia e da jogabilidade precisa, o que realmente se destaca é a acessibilidade."
```

Count: 1101/4000 characters.

### pt-PT

```text
RetroRapid! é um arcade de corrida de 3 faixas feito para sessões rápidas e para perseguir o seu recorde.

Desvie do trânsito e aguente enquanto a velocidade sobe. Os controlos são fáceis de aprender e difíceis de dominar, por isso cada corrida vira um teste de reflexos.

Porque os jogadores voltam:
- Gameplay arcade rápido de "só mais uma"
- Corridas SharePlay ao vivo para dois jogadores no iPhone e iPad
- Corridas com amigos são grátis e não usam partidas diárias
- Rankings, conquistas e marcadores de amigos do Game Center
- Jogue no iPhone, iPad, Mac e Apple Watch
- Toque, deslize, teclado, Digital Crown e comandos compatíveis
- VoiceOver, pistas sonoras, háptico, texto maior, alto contraste e Reduzir Movimento
- Funciona offline para corridas rápidas a qualquer hora
- Jogue grátis todos os dias ou desbloqueie Partidas Ilimitadas com compra única, sem assinatura
- Sem recolha de dados

Bata, reinicie e ultrapasse o seu recorde.

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week):
"Além da nostalgia e da jogabilidade precisa, o que realmente se destaca é a acessibilidade."
```

Count: 1117/4000 characters.

### zh-Hant

```text
RetroRapid! 是一款快節奏的三線道街機賽車，適合短局遊玩與挑戰最高分。

閃避車流並在速度提升時撐下去。操作好學難精，因此每一局都是反射神經的考驗。

玩家會一再回來的原因：
- 快節奏「再來一局」街機玩法
- iPhone/iPad 上的 SharePlay 即時雙人競賽
- 好友對戰免費，且不消耗每日次數
- Game Center 排行榜、成就與好友標記
- 可在 iPhone、iPad、Mac 與 Apple Watch 上遊玩
- 支援觸控、滑動、鍵盤、Digital Crown 與相容控制器
- VoiceOver、音效提示、觸覺回饋、較大字體、高對比與減少動態效果
- 離線也能隨時快速開跑
- 每天免費遊玩，或以一次性購買解鎖無限暢玩，無訂閱
- 不收集資料

撞車、重來，刷新你的最佳成績。

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week)：
「除了懷舊感與緊湊玩法，真正突出的是無障礙設計。」
```

Count: 467/4000 characters.

### zh-Hans

```text
RetroRapid! 是一款快节奏的三车道街机赛车，适合短局游玩与挑战最高分。

闪避车流并在速度提升时撑下去。操作好学难精，因此每一局都是反应力的考验。

玩家会一再回来的原因：
- 快节奏「再来一局」街机玩法
- iPhone/iPad 上的 SharePlay 即时双人竞赛
- 好友对战免费，且不消耗每日次数
- Game Center 排行榜、成就与好友标记
- 可在 iPhone、iPad、Mac 与 Apple Watch 上玩
- 支持触控、滑动、键盘、Digital Crown 与兼容手柄
- VoiceOver、音效提示、触感反馈、较大字体、高对比与减少动态效果
- 离线也能随时快速开跑
- 每天免费游玩，或以一次性购买解锁无限畅玩，无订阅
- 不收集数据

撞车、重来，刷新你的最佳成绩。

Featured in Create with Swift, Weekly Newsletter #96 (Indie App of the Week)：
「除了怀旧感与紧凑玩法，真正突出的是无障碍设计。」
```

Count: 464/4000 characters.

## What's New Candidate

Use this shape for the next bug-fix or polish release if there is no larger feature to lead with.

### en-US / en-GB / en-AU / en-CA

```text
Race friends live with SharePlay on iPhone and iPad: synchronized countdowns, shared win/loss/tie results, and free rematches that wait until both players are ready.

This update adds full in-app localization for German, Dutch, Italian, French (France), French (Canada), Japanese, Korean, Brazilian Portuguese, European Portuguese, Traditional Chinese, and Simplified Chinese.

We've also polished settings, audio, and stability across iPhone, iPad, Mac, and Apple Watch.

If you're catching up: recent releases added Game Center achievements, friend markers during races, and shareable result snapshots, along with accessibility improvements.

Thanks for racing with us.
```

Count: 671/4000 characters.

### de-DE

```text
Rase live mit Freunden per SharePlay auf iPhone und iPad: synchronisierte Countdowns, gemeinsame Sieg-/Niederlage-/Unentschieden-Ergebnisse und kostenlose Rematches, die warten, bis beide Spieler bereit sind.

Dieses Update ergänzt die vollständige App-Lokalisierung um Deutsch, Niederländisch, Italienisch, Französisch, Französisch (Kanada), Japanisch, Koreanisch, brasilianisches Portugiesisch, europäisches Portugiesisch, traditionelles Chinesisch und vereinfachtes Chinesisch.

Außerdem haben wir Einstellungen, Audio und Stabilität auf iPhone, iPad, Mac und Apple Watch verbessert.

Falls du aufholst: In den letzten Versionen kamen Game-Center-Erfolge, Freundesmarker auf der Strecke und teilbare Ergebnis-Screenshots hinzu, dazu Barrierefreiheitsverbesserungen.

Danke, dass du mit uns fährst.
```

Count: 800/4000 characters.

### nl-NL

```text
Race live met vrienden via SharePlay op iPhone en iPad: gesynchroniseerde countdowns, gedeelde winst/verlies/gelijkspel-resultaten en gratis rematches die wachten tot beide spelers klaar zijn.

Deze update voegt volledige app-localisatie toe voor Duits, Nederlands, Italiaans, Frans (Frankrijk), Frans (Canada), Japans, Koreaans, Braziliaans Portugees, Europees Portugees, Traditioneel Chinees en Vereenvoudigd Chinees.

We hebben ook instellingen, audio en stabiliteit verbeterd op iPhone, iPad, Mac en Apple Watch.

Als je bij bent: recente releases voegden Game Center-prestaties, vriendenmarkeringen tijdens races en deelbare resultaat-screenshots toe, plus toegankelijkheidsverbeteringen.

Bedankt dat je met ons rijdt.
```

Count: 724/4000 characters.

### it

```text
Corri in diretta con gli amici tramite SharePlay su iPhone e iPad: countdown sincronizzati, risultati condivisi di vittoria/sconfitta/parità e rematch gratuiti che aspettano che entrambi i giocatori siano pronti.

Questo aggiornamento aggiunge la localizzazione completa dell'app per tedesco, olandese, italiano, francese (Francia), francese (Canada), giapponese, coreano, portoghese brasiliano, portoghese europeo, cinese tradizionale e cinese semplificato.

Abbiamo anche rifinito impostazioni, audio e stabilità su iPhone, iPad, Mac e Apple Watch.

Se ti stai aggiornando: le versioni recenti hanno aggiunto obiettivi Game Center, marcatori amici in gara e screenshot condivisibili dei risultati, oltre a miglioramenti di accessibilità.

Grazie per correre con noi.
```

Count: 768/4000 characters.

### fr-FR

```text
Course en direct avec tes amis via SharePlay sur iPhone et iPad : comptes à rebours synchronisés, résultats victoire/défaite/égalité partagés et revanches gratuites qui attendent que les deux joueurs soient prêts.

Cette mise à jour ajoute la localisation complète de l'app en allemand, néerlandais, italien, français (France), français canadien, japonais, coréen, portugais brésilien, portugais européen, chinois traditionnel et chinois simplifié.

Nous avons aussi peaufiné les réglages, l'audio et la stabilité sur iPhone, iPad, Mac et Apple Watch.

Si tu rattrapes le train : les versions récentes ont ajouté des succès Game Center, des marqueurs d'amis en course et des captures de résultats partageables, ainsi que des améliorations d'accessibilité.

Merci de courir avec nous.
```

Count: 783/4000 characters.

### fr-CA

```text
Coursez en direct avec vos amis via SharePlay sur iPhone et iPad : comptes à rebours synchronisés, résultats victoire/défaite/égalité partagés et revanches gratuites qui attendent que les deux joueurs soient prêts.

Cette mise à jour ajoute la localisation complète de l'app en allemand, néerlandais, italien, français (France), français canadien, japonais, coréen, portugais brésilien, portugais européen, chinois traditionnel et chinois simplifié.

Nous avons aussi peaufiné les réglages, l'audio et la stabilité sur iPhone, iPad, Mac et Apple Watch.

Si vous rattrapez le train : les versions récentes ont ajouté des succès Game Center, des marqueurs d'amis en course et des captures de résultats partageables, ainsi que des améliorations d'accessibilité.

Merci de courir avec nous.
```

Count: 786/4000 characters.

### es-ES / es-MX

```text
Corre en vivo con amigos gracias a SharePlay en iPhone e iPad: cuenta atrás sincronizada, mismos resultados de victoria, derrota o empate y revanchas gratis que esperan a que ambos jugadores estén listos.

Esta actualización añade la localización completa de la app para alemán, neerlandés, italiano, francés (Francia), francés de Canadá, japonés, coreano, portugués de Brasil, portugués europeo, chino tradicional y chino simplificado.

También hemos pulido ajustes, audio y estabilidad en iPhone, iPad, Mac y Apple Watch.

Si te pones al día: versiones recientes añadieron logros de Game Center, marcadores de amigos en pista y capturas de resultados para compartir, junto con mejoras de accesibilidad.

Gracias por correr con nosotros.
```

Count: 738/4000 characters.

### ca

```text
Corre en viu amb amics amb SharePlay a iPhone i iPad: compte enrere sincronitzat, mateixos resultats de victòria, derrota o empat i revanxes gratuïtes que esperen que els dos jugadors estiguen llestos.

Aquesta actualització afig la localització completa de l'app per a alemany, neerlandés, italià, francés (França), francés del Canadà, japonés, coreà, portugués del Brasil, portugués europeu, xinés tradicional i xinés simplificat.

També hem polit ajustos, àudio i estabilitat a iPhone, iPad, Mac i Apple Watch.

Si et poses al dia: versions recents van afegir assoliments de Game Center, marcadors d'amistats en pista i captures de resultats per a compartir, juntament amb millores d'accessibilitat.

Gràcies per córrer amb nosaltres.
```

Count: 737/4000 characters.

### ja

```text
iPhoneとiPadでSharePlayのライブフレンドレース。同期カウントダウン、勝敗/引き分けの共有結果、両者の準備を待つ無料リマッチ。

このアップデートで、ドイツ語、オランダ語、イタリア語、フランス語、カナダフランス語、日本語、韓国語、ブラジルポルトガル語、ヨーロッパポルトガル語、繁体字中国語、簡体字中国語のアプリ内ローカライズに完全対応しました。

iPhone、iPad、Mac、Apple Watch向けに設定、音声、安定性も改善しました。

最近の更新ではGame Center実績、レース中のフレンドマーカー、結果スナップショットの共有、アクセシビリティ改善が追加されています。

一緒にレースしてくれてありがとう。
```

Count: 319/4000 characters.

### ko

```text
iPhone과 iPad에서 SharePlay 라이브 친구 레이스, 동기화된 카운트다운, 승/패/무승부 공유 결과, 두 플레이어 준비를 기다리는 무료 리매치.

이번 업데이트로 독일어, 네덜란드어, 이탈리아어, 프랑스어, 캐나다 프랑스어, 일본어, 한국어, 브라질 포르투갈어, 유럽 포르투갈어, 중국어 번체, 중국어 간체 앱 현지화가 추가되었습니다.

iPhone, iPad, Mac, Apple Watch용 설정, 오디오, 안정성도 다듬었습니다.

최근 업데이트에는 Game Center 업적, 레이스 중 친구 마커, 결과 스냅샷 공유, 접근성 개선이 추가되었습니다.

함께 레이스해 주셔서 감사합니다.
```

Count: 337/4000 characters.

### pt-BR

```text
Corra ao vivo com amigos no SharePlay no iPhone e iPad: contagem regressiva sincronizada, mesmos resultados de vitória, derrota ou empate e revanches grátis que esperam os dois jogadores ficarem prontos.

Esta atualização adiciona localização completa do app para alemão, neerlandês, italiano, francês (França), francês do Canadá, japonês, coreano, português do Brasil, português europeu, chinês tradicional e chinês simplificado.

Também polimos ajustes, áudio e estabilidade no iPhone, iPad, Mac e Apple Watch.

Se você está se atualizando: versões recentes adicionaram conquistas do Game Center, marcadores de amigos na pista, capturas de resultados para compartilhar e melhorias de acessibilidade.

Obrigado por correr com a gente.
```

Count: 735/4000 characters.

### pt-PT

```text
Corra ao vivo com amigos no SharePlay no iPhone e iPad: contagem decrescente sincronizada, mesmos resultados de vitória, derrota ou empate e revanches grátis que esperam que os dois jogadores fiquem prontos.

Esta atualização adiciona localização completa da app para alemão, neerlandês, italiano, francês (França), francês do Canadá, japonês, coreano, português do Brasil, português europeu, chinês tradicional e chinês simplificado.

Também polimos definições, áudio e estabilidade no iPhone, iPad, Mac e Apple Watch.

Se está a atualizar: versões recentes adicionaram conquistas do Game Center, marcadores de amigos na pista, capturas de resultados para partilhar e melhorias de acessibilidade.

Obrigado por correr connosco.
```

Count: 728/4000 characters.

### zh-Hant

```text
在 iPhone 與 iPad 上透過 SharePlay 與好友即時競賽：同步倒數、共享勝/負/平結果，以及等待雙方都準備好的免費重賽。

此更新新增德文、荷蘭文、義大利文、法文、加拿大法文、日文、韓文、巴西葡萄牙文、歐洲葡萄牙文、繁體中文與簡體中文的完整 App 本地化。

我們也改進了 iPhone、iPad、Mac 與 Apple Watch 的設定、音效與穩定性。

若你剛回來：近期版本新增了 Game Center 成就、賽道上的好友標記、可分享的結果截圖，以及無障礙改進。

感謝你與我們一起競速。
```

Count: 258/4000 characters.

### zh-Hans

```text
在 iPhone 与 iPad 上通过 SharePlay 与好友即时竞赛：同步倒计时、共享胜/负/平结果，以及等待双方都准备好的免费重赛。

此更新新增德文、荷兰文、意大利文、法文、加拿大法文、日文、韩文、巴西葡萄牙文、欧洲葡萄牙文、繁体中文与简体中文的完整 App 本地化。

我们也改进了 iPhone、iPad、Mac 与 Apple Watch 的设置、音效与稳定性。

若你刚回来：近期版本新增了 Game Center 成就、赛道上的好友标记、可分享的结果截图，以及无障碍改进。

感谢你与我们一起竞速。
```

Count: 259/4000 characters.

_Generated by `swift run --package-path Scripts generate-metadata-docs`._
