# Screenshot Localization Copy (All Slides)

Part of [ASO & growth plans](README.md). Index: [retrorapid_aso_growth_plan.md](../retrorapid_aso_growth_plan.md).

Last updated: 2026-06-24
**See also:** [Current storyboard](../../AppStore/docs/06-screenshots.md) · Sync script: `Scripts/SyncScreenshotStudioLocalizations.swift`


---

## 4) Screenshot Messaging Plan (Revised)

## 4.1 Positioning Rule

- Slide 1 should sell the game loop.
- Accessibility should appear early (slide 2/3), but not replace the gameplay hook.
- Game Center should appear as replayability support, not as headline proposition.

## 4.2 iPhone Caption Sequence — Live (as of 2026-06-24)

Current iPhone/iPad/Mac source copy uses this **seven-slide** order. Locales: `en-US`, `en-GB`, `en-AU`, `en-CA`, `es-ES`, `es-MX`, `ca`. English variants share the same base captures; `es-MX` shares `es-ES` captures with Mexico-specific overlay copy on slide 1.

| # | Title (EN) | Body (EN) |
|---|------------|-----------|
| 1 | `Race Through Endless Traffic` | `Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer.` |
| 2 | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. Master the basics in seconds, then chase your high score for hours.` |
| 3 | `Built For Accessibility` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` |
| 4 | `One Wrong Move. Game Over` | `The speed climbs. One mistake ends your run. Restart fast and beat your best.` |
| 5 | `Climb the Leaderboards` | `Earn achievements, chase friends, and share your best runs with Game Center.` |
| 6 | `Choose Your Retro Aesthetic` | `Switch from pocket-console green to LCD handheld style, and make every run feel properly retro.` |
| 7 | `Customize Your Experience` | `Tune controls, haptics, volume, visual style, and feedback so RetroRapid! fits your play style.` (`Customise` on en-GB/en-AU) |

## 4.3 Screenshot Localization — All Slides, All Languages

Translations use vocabulary consistent with `Localizable.xcstrings` and App Store metadata.  
CA follows **Valencian Meridional** dialect: `trànsit` for traffic, `teua`/`seua` for feminine possessives, `este`/`esta` for proximal demonstratives, Valencian verb forms (`gaudix`, `resistix`, `valga`).

### Slide 1 — Hook

| Lang | Title | Body |
|------|-------|------|
| EN | `Race Through Endless Traffic` | `Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer.` |
| ES | `Esquiva Tráfico Sin Fin` | `Conduce tu coche, esquiva rivales y acumula adelantamientos en este arcade de carreras de inspiración retro.` |
| ES-MX | `Esquiva Carros Sin Fin` | `Conduce tu carro, esquiva rivales y rebasa adelantamientos en este arcade de carreras de inspiración retro.` |
| CA | `Esquiva Trànsit Sense Fi` | `Condueix el teu cotxe, esquiva rivals i acumula avançaments en este arcade de carreres d'inspiració retro.` |

### Slide 2 — Controls

| Lang | Title | Body |
|------|-------|------|
| EN | `Simple Controls. Pure Arcade Action` | `Move left. Move right. Don't crash. Master the basics in seconds, then chase your high score for hours.` |
| ES / ES-MX | `Controles Simples. Acción Arcade Pura` | `Izquierda. Derecha. No choques. Domina lo básico en segundos y pasa horas persiguiendo tu récord.` |
| CA | `Controls Simples. Acció Arcade Pura` | `Esquerra. Dreta. No xoques. Domina l'essencial en segons i passa hores perseguint el teu rècord.` |

### Slide 3 — Accessibility

| Lang | Title | Body |
|------|-------|------|
| EN | `Built For Accessibility` | `VoiceOver, audio cues, haptics, larger text, and adaptable gameplay settings.` |
| ES / ES-MX | `Diseñado para la Accesibilidad` | `VoiceOver, pistas de audio, hápticos y ajustes de juego adaptables.` |
| CA | `Dissenyat per a l'Accessibilitat` | `VoiceOver, pistes d'àudio, hàptics i opcions de joc adaptables.` |

### Slide 4 — Tension

| Lang | Title | Body |
|------|-------|------|
| EN | `One Wrong Move. Game Over` | `The speed climbs. One mistake ends your run. Restart fast and beat your best.` |
| ES / ES-MX | `Un Error. Game Over` | `La velocidad sube. Un fallo termina tu partida. ¡Supera tu récord!` |
| CA | `Un Error. Game Over` | `La velocitat puja. Un error acaba la teua partida. Supera el teu rècord!` |

### Slide 5 — Game Center

| Lang | Title | Body |
|------|-------|------|
| EN | `Climb the Leaderboards` | `Earn achievements, chase friends, and share your best runs with Game Center.` |
| ES / ES-MX | `Sube en la Clasificación` | `Gana logros, persigue amigos y comparte tus mejores partidas con Game Center.` |
| CA | `Puja en la Classificació` | `Guanya assoliments, persegueix amistats i comparteix les teues millors partides amb Game Center.` |

### Slide 6 — Themes

| Lang | Title | Body |
|------|-------|------|
| EN | `Choose Your Retro Aesthetic` | `Switch from pocket-console green to LCD handheld style, and make every run feel properly retro.` |
| ES / ES-MX | `Elige Tu Estética Retro` | `Del verde de las consolas de bolsillo clásicas a los juegos de mano LCD, personaliza tu experiencia visual con temas retro icónicos.` |
| CA | `Tria la Teua Estètica Retro` | `Del verd de les consoles de butxaca clàssiques als jocs de mà LCD, personalitza la teua experiència visual amb temes retro icònics.` |

### Slide 7 — Customisation

| Lang | Title | Body |
|------|-------|------|
| EN | `Customize Your Experience` | `Tune controls, haptics, volume, visual style, and feedback so RetroRapid! fits your play style.` |
| ES / ES-MX | `Personaliza Tu Experiencia` | `Ajusta el volumen, elige la respuesta háptica, selecciona tu tema y afina los controles. RetroRapid! se adapta a tu estilo de juego.` |
| CA | `Personalitza la Teua Experiència` | `Ajusta el volum, tria la retroalimentació hàptica, selecciona el teu tema i afina els controls. RetroRapid! s'adapta al teu estil de joc.` |

> **Export status (2026-06-24):** Source `data.plist` copy is synced for iPhone, iPad, Mac, and Apple Watch. iPhone has English-variant JPEG exports; `es-ES`, `es-MX`, and `ca` must be re-exported. iPad and Mac need full locale exports (Mac slides 6–7 are new in source).

## 4.4 Apple Watch Screenshot Approach

- Assume **no marketing text overlays** for watch output.
- Use sequence-only storytelling:
  1. Core gameplay lane view
  2. Input interaction moment (Digital Crown/swipe)
  3. Collision/high-tension moment
  4. Pause/help/accessibility state
  5. Score/result state
- Add support explanation in ASC screenshot order notes/internal checklist, not in-image copy.

## 4.5 Platform Scope Cleanup In ScreenshotStudio

- Remove Apple TV and Apple Vision from active planning/output for now to avoid accidental scope drift.
- Keep active sets: iPhone, iPad, Mac, Apple Watch.
