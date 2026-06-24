# Screenshot Localization Copy (All Slides)

Part of [ASO & growth plans](README.md). Index: [retrorapid_aso_growth_plan.md](../retrorapid_aso_growth_plan.md).

Last updated: 2026-03-14 (campaign); brand status refreshed 2026-06-24
**See also:** [Current storyboard](../../AppStoreAssets/docs/06-screenshots.md)


---

## 4) Screenshot Messaging Plan (Revised)

## 4.1 Positioning Rule

- Slide 1 should sell the game loop.
- Accessibility should appear early (slide 2/3), but not replace the gameplay hook.
- Game Center should appear as replayability support, not as headline proposition.

## 4.2 iPhone Caption Sequence — Live (as of 2026-04-10)

Current iPhone set in ScreenshotStudio has 7 slides. Localizations for ES/CA are pending (see §4.5).

| # | Title (EN) | Body (EN) |
|---|------------|-----------|
| 1 | `Race Through Endless Traffic.` | `Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer.` |
| 2 | `Simple Controls. Pure Arcade Action.` | `Move left. Move right. Don't crash. Master the basics in seconds, spend hours chasing your high score.` |
| 3 | `Choose Your Retro Aesthetic` | `From classic pocket consoles green to lcd handheld games, customize your visual experience with iconic retro themes.` |
| 4 | `One Wrong Move. Game Over.` | `The speed climbs. One mistake ends your run. Chase your high score!` |
| 5 | `Customize Your Experience` | `Adjust volume, choose haptic feedback, select your theme, and fine-tune controls. RetroRapid! adapts to your play style.` |
| 6 | `Built For Accessibility.` | `VoiceOver, audio cues, haptics, and adaptable gameplay settings.` |
| 7 | `Your Best Run Is Next.` | `Game Center leaderboards keep every crash worth restarting.` |

## 4.3 Screenshot Localization — All Slides, All Languages

Translations use vocabulary consistent with `Localizable.xcstrings` and the metadata in §5 (verified 2026-04-10).  
CA follows **Valencian Meridional** dialect: `trànsit` for traffic, `teua`/`seua` for feminine possessives, `este`/`esta` for proximal demonstratives, Valencian verb forms (`gaudix`, `resistix`, `valga`).

### Slide 1 — Hook

| Lang | Title | Body |
|------|-------|------|
| EN | `Race Through Endless Traffic.` | `Navigate your car, dodge rivals, and rack up overtakes in this retro-inspired arcade racer.` |
| ES | `Esquiva Tráfico Sin Fin.` | `Conduce tu coche, esquiva rivales y acumula adelantamientos en este arcade de carreras de inspiración retro.` |
| CA | `Esquiva Trànsit Sense Fi.` | `Condueix el teu cotxe, esquiva rivals i acumula avançaments en este arcade de carreres d'inspiració retro.` |

### Slide 2 — Controls

| Lang | Title | Body |
|------|-------|------|
| EN | `Simple Controls. Pure Arcade Action.` | `Move left. Move right. Don't crash. Master the basics in seconds, spend hours chasing your high score.` |
| ES | `Controles Simples. Acción Arcade Pura.` | `Izquierda. Derecha. No choques. Domina lo básico en segundos y pasa horas persiguiendo tu récord.` |
| CA | `Controls Simples. Acció Arcade Pura.` | `Esquerra. Dreta. No xoques. Domina l'essencial en segons i passa hores perseguint el teu rècord.` |

### Slide 3 — Themes

| Lang | Title | Body |
|------|-------|------|
| EN | `Choose Your Retro Aesthetic` | `From classic pocket consoles green to lcd handheld games, customize your visual experience with iconic retro themes.` |
| ES | `Elige Tu Estética Retro` | `Del verde de las consolas de bolsillo clásicas a los juegos de mano LCD, personaliza tu experiencia visual con temas retro icónicos.` |
| CA | `Tria la Teua Estètica Retro` | `Del verd de les consoles de butxaca clàssiques als jocs de mà LCD, personalitza la teua experiència visual amb temes retro icònics.` |

### Slide 4 — Tension

| Lang | Title | Body |
|------|-------|------|
| EN | `One Wrong Move. Game Over.` | `The speed climbs. One mistake ends your run. Chase your high score!` |
| ES | `Un Error. Game Over.` | `La velocidad sube. Un fallo termina tu partida. ¡Supera tu récord!` |
| CA | `Un Error. Game Over.` | `La velocitat puja. Un error acaba la teua partida. Supera el teu rècord!` |

### Slide 5 — Customisation

| Lang | Title | Body |
|------|-------|------|
| EN | `Customize Your Experience` | `Adjust volume, choose haptic feedback, select your theme, and fine-tune controls. RetroRapid! adapts to your play style.` |
| ES | `Personaliza Tu Experiencia` | `Ajusta el volumen, elige la respuesta háptica, selecciona tu tema y afina los controles. RetroRapid! se adapta a tu estilo de juego.` |
| CA | `Personalitza la Teua Experiència` | `Ajusta el volum, tria la retroalimentació hàptica, selecciona el teu tema i afina els controls. RetroRapid! s'adapta al teu estil de joc.` |

### Slide 6 — Accessibility

| Lang | Title | Body |
|------|-------|------|
| EN | `Built For Accessibility.` | `VoiceOver, audio cues, haptics, and adaptable gameplay settings.` |
| ES | `Diseñado para la Accesibilidad.` | `VoiceOver, pistas de audio, hápticos y ajustes de juego adaptables.` |
| CA | `Dissenyat per a l'Accessibilitat.` | `VoiceOver, pistes d'àudio, hàptics i opcions de joc adaptables.` |

### Slide 7 — Game Center

| Lang | Title | Body |
|------|-------|------|
| EN | `Your Best Run Is Next.` | `Game Center leaderboards keep every crash worth restarting.` |
| ES | `La Próxima Será la Mejor.` | `Las clasificaciones de Game Center hacen que cada choque merezca un reinicio.` |
| CA | `La Pròxima Serà la Millor.` | `Les classificacions de Game Center fan que cada xoc valga la pena reiniciar.` |

> **TODO — iPad & macOS screenshots**: Both platforms currently have only the original 5-slide set (en-US only) and do not yet include the accessibility or Game Center slides. Once the iPhone set is finalised and exported, apply the same 7-slide sequence and all three localizations (using this table) to the `ipad` and `mac` sets in ScreenshotStudio. Shot composition may need adjustment for the larger canvas (especially macOS).

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
