# Achievements Rollout Checklist (ASC + Developer Portal)

## Scope

This checklist is for production rollout of the 22-achievement set (700 of 1,000 available points; 300 pts reserved for future achievements), including:

1. Existing achievement IDs (including `com.accessibilityUpTo11.RetroRacing.achievement.control.gamecontroller`).
2. New GAAD event achievement (`com.accessibilityUpTo11.RetroRacing.achievement.event.gaad.assistive`).
3. Capability and provisioning validation across shipped app bundle IDs.

## ID Constraints (ASC)

1. Achievement IDs must be 100 characters or fewer (single-byte assumption).
2. IDs are immutable in App Store Connect after creation, so prefix/shape must be final before release.
3. Current longest canonical ID is `com.accessibilityUpTo11.RetroRacing.achievement.control.gamecontroller` (70 characters).

## Bundle IDs To Validate

1. Universal app (iOS/macOS): `com.accessibilityUpTo11.RetroRacing`
2. watchOS app: `com.accessibilityUpTo11.RetroRacing.watchkitapp`
3. tvOS app: `com.accessibilityUpTo11.RetroRacing-for-tvOS`
4. visionOS app: `com.accessibilityUpTo11.RetroRacing-for-visionOS`

## Developer Portal Checklist (Certificates, IDs & Profiles)

For each bundle ID above:

1. Confirm App ID exists and matches the bundle ID exactly.
2. Confirm Game Center capability is enabled on the App ID.
3. Regenerate provisioning profiles if capability state changed.
4. Verify CI/local signing picks updated profiles for Release config.
5. Confirm no target is shipping with stale capability entitlements.

## App Store Connect Checklist (Per App Record)

For each app record corresponding to the bundle IDs above:

1. Open the app record.
2. Go to Game Center -> Achievements.
3. Ensure all 22 achievements exist exactly as listed in the registry below (reference name + ID).
4. Ensure each achievement has the correct point value from the registry `Points` column.
5. Ensure each achievement has localized metadata in EN/ES/CA.
6. Ensure `com.accessibilityUpTo11.RetroRacing.achievement.control.gamecontroller` is present (alignment with code).
7. Ensure `com.accessibilityUpTo11.RetroRacing.achievement.event.gaad.assistive` exists with GAAD localization text.
8. Attach the Game Center configuration to the active release version/build for each platform app record.

## Achievement Registry (English US)

Use this registry as source of truth per achievement entry in App Store Connect.

1. `Reference Name` maps to code symbols (for example `AchievementIdentifier` case names).
2. `Achievement ID` must match exactly and stay immutable once created.
3. Streak user-facing family: all `run.overtakes.*` entries.
4. Overlander user-facing family: all `total.overtakes.*` entries.

| Reference Name | Achievement ID | Display Name | Earned Description | Pre-earned Description | Points | Hidden |
| --- | --- | --- | --- | --- | --- | --- |
| `runOvertakes100` | `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0100` | `Streak 100` | `You overtook 100 cars in one run.` | `Overtake 100 cars in one run.` | 5 | No |
| `runOvertakes200` | `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0200` | `Streak 200` | `You overtook 200 cars in one run.` | `Overtake 200 cars in one run.` | 5 | No |
| `runOvertakes300` | `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0300` | `Streak 300` | `You overtook 300 cars in one run.` | `Overtake 300 cars in one run.` | 10 | No |
| `runOvertakes400` | `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0400` | `Streak 400` | `You overtook 400 cars in one run.` | `Overtake 400 cars in one run.` | 15 | No |
| `runOvertakes500` | `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0500` | `Streak 500` | `You overtook 500 cars in one run.` | `Overtake 500 cars in one run.` | 20 | No |
| `runOvertakes600` | `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0600` | `Streak 600` | `You overtook 600 cars in one run.` | `Overtake 600 cars in one run.` | 35 | **Yes** |
| `runOvertakes700` | `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0700` | `Streak 700` | `You overtook 700 cars in one run.` | `Overtake 700 cars in one run.` | 65 | **Yes** |
| `runOvertakes800` | `com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0800` | `Streak 800` | `You overtook 800 cars in one run.` | `Overtake 800 cars in one run.` | 100 | **Yes** |
| `totalOvertakes1k` | `com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.001k` | `Overlander 1K` | `You overtook 1,000 cars in total.` | `Overtake 1,000 cars in total.` | 5 | No |
| `totalOvertakes5k` | `com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.005k` | `Overlander 5K` | `You overtook 5,000 cars in total.` | `Overtake 5,000 cars in total.` | 10 | No |
| `totalOvertakes10k` | `com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.010k` | `Overlander 10K` | `You overtook 10,000 cars in total.` | `Overtake 10,000 cars in total.` | 20 | No |
| `totalOvertakes20k` | `com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.020k` | `Overlander 20K` | `You overtook 20,000 cars in total.` | `Overtake 20,000 cars in total.` | 30 | No |
| `totalOvertakes50k` | `com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.050k` | `Overlander 50K` | `You overtook 50,000 cars in total.` | `Overtake 50,000 cars in total.` | 50 | No |
| `totalOvertakes100k` | `com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.100k` | `Overlander 100K` | `You overtook 100,000 cars in total.` | `Overtake 100,000 cars in total.` | 75 | No |
| `totalOvertakes200k` | `com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.200k` | `Overlander 200K` | `You overtook 200,000 cars in total.` | `Overtake 200,000 cars in total.` | 100 | **Yes** |
| `controlTap` | `com.accessibilityUpTo11.RetroRacing.achievement.control.tap` | `Tap Controls` | `You completed a run using Tap controls.` | `Complete a run using Tap controls.` | 5 | No |
| `controlSwipe` | `com.accessibilityUpTo11.RetroRacing.achievement.control.swipe` | `Swipe Controls` | `You completed a run using Swipe controls.` | `Complete a run using Swipe controls.` | 5 | No |
| `controlKeyboard` | `com.accessibilityUpTo11.RetroRacing.achievement.control.keyboard` | `Keyboard Controls` | `You completed a run using Keyboard controls.` | `Complete a run using Keyboard controls.` | 10 | No |
| `controlVoiceOver` | `com.accessibilityUpTo11.RetroRacing.achievement.control.voiceover` | `VoiceOver Controls` | `You completed a run using VoiceOver controls.` | `Complete a run using VoiceOver controls.` | 30 | No |
| `controlDigitalCrown` | `com.accessibilityUpTo11.RetroRacing.achievement.control.crown` | `Digital Crown Controls` | `You completed a run using Digital Crown controls.` | `Complete a run using Digital Crown controls.` | 15 | No |
| `controlGameController` | `com.accessibilityUpTo11.RetroRacing.achievement.control.gamecontroller` | `Game Controller Controls` | `You completed a run using Game Controller controls.` | `Complete a run using Game Controller controls.` | 15 | No |
| `eventGAADAssistive` | `com.accessibilityUpTo11.RetroRacing.achievement.event.gaad.assistive` | `GAAD Assistive Week` | `You completed a run during GAAD week using assistive technology.` | `Complete a run during GAAD week while using assistive technology.` | 75 | No |

## GAAD Localization Payload (New Achievement)

1. EN title: `GAAD Assistive Week`
2. EN description: `Complete a run during GAAD week while using an assistive technology.`
3. ES title: `Semana GAAD Asistiva`
4. ES description: `Completa una partida durante la semana de GAAD usando una tecnología de asistencia.`
5. CA title: `Setmana GAAD Assistiva`
6. CA description: `Completa una partida durant la setmana de GAAD usant una tecnologia d'assistència.`

## Sandbox Validation Checklist

Run these checks in Game Center sandbox accounts:

1. Fresh account can unlock normal achievements and receive achievement sync.
2. GAAD achievement unlocks only when:
   - Run completes in GAAD week window for local device year.
   - Qualifying assistive technology is active.
3. Outside GAAD week, GAAD achievement does not unlock even with assistive technology active.
4. Offline/auth-delayed unlocks eventually sync after authentication via replay triggers.
5. watchOS path qualifies via VoiceOver-only behavior (v1 scope).

## Localization Payload (es-ES + ca-ES Valencian Meridional)

Full localized metadata for all 22 achievements. The GAAD event payload is in its own section above; all other families are here.

### Streak — Spanish (Spain) `es-ES`

| Reference Name | Display Name | Earned Description | Pre-earned Description |
| --- | --- | --- | --- |
| `runOvertakes100` | `Racha 100` | `Has adelantado 100 coches en una sola partida.` | `Adelanta 100 coches en una sola partida.` |
| `runOvertakes200` | `Racha 200` | `Has adelantado 200 coches en una sola partida.` | `Adelanta 200 coches en una sola partida.` |
| `runOvertakes300` | `Racha 300` | `Has adelantado 300 coches en una sola partida.` | `Adelanta 300 coches en una sola partida.` |
| `runOvertakes400` | `Racha 400` | `Has adelantado 400 coches en una sola partida.` | `Adelanta 400 coches en una sola partida.` |
| `runOvertakes500` | `Racha 500` | `Has adelantado 500 coches en una sola partida.` | `Adelanta 500 coches en una sola partida.` |
| `runOvertakes600` | `Racha 600` | `Has adelantado 600 coches en una sola partida.` | `Adelanta 600 coches en una sola partida.` |
| `runOvertakes700` | `Racha 700` | `Has adelantado 700 coches en una sola partida.` | `Adelanta 700 coches en una sola partida.` |
| `runOvertakes800` | `Racha 800` | `Has adelantado 800 coches en una sola partida.` | `Adelanta 800 coches en una sola partida.` |

### Streak — Catalan (Valencian Meridional) `ca-ES`

| Reference Name | Display Name | Earned Description | Pre-earned Description |
| --- | --- | --- | --- |
| `runOvertakes100` | `Ratxa 100` | `Has avançat 100 cotxes en una sola partida.` | `Avança 100 cotxes en una sola partida.` |
| `runOvertakes200` | `Ratxa 200` | `Has avançat 200 cotxes en una sola partida.` | `Avança 200 cotxes en una sola partida.` |
| `runOvertakes300` | `Ratxa 300` | `Has avançat 300 cotxes en una sola partida.` | `Avança 300 cotxes en una sola partida.` |
| `runOvertakes400` | `Ratxa 400` | `Has avançat 400 cotxes en una sola partida.` | `Avança 400 cotxes en una sola partida.` |
| `runOvertakes500` | `Ratxa 500` | `Has avançat 500 cotxes en una sola partida.` | `Avança 500 cotxes en una sola partida.` |
| `runOvertakes600` | `Ratxa 600` | `Has avançat 600 cotxes en una sola partida.` | `Avança 600 cotxes en una sola partida.` |
| `runOvertakes700` | `Ratxa 700` | `Has avançat 700 cotxes en una sola partida.` | `Avança 700 cotxes en una sola partida.` |
| `runOvertakes800` | `Ratxa 800` | `Has avançat 800 cotxes en una sola partida.` | `Avança 800 cotxes en una sola partida.` |

### Overlander — Spanish (Spain) `es-ES`

| Reference Name | Display Name | Earned Description | Pre-earned Description |
| --- | --- | --- | --- |
| `totalOvertakes1k` | `Corredor 1K` | `Has adelantado 1.000 coches en total.` | `Adelanta 1.000 coches en total.` |
| `totalOvertakes5k` | `Corredor 5K` | `Has adelantado 5.000 coches en total.` | `Adelanta 5.000 coches en total.` |
| `totalOvertakes10k` | `Corredor 10K` | `Has adelantado 10.000 coches en total.` | `Adelanta 10.000 coches en total.` |
| `totalOvertakes20k` | `Corredor 20K` | `Has adelantado 20.000 coches en total.` | `Adelanta 20.000 coches en total.` |
| `totalOvertakes50k` | `Corredor 50K` | `Has adelantado 50.000 coches en total.` | `Adelanta 50.000 coches en total.` |
| `totalOvertakes100k` | `Corredor 100K` | `Has adelantado 100.000 coches en total.` | `Adelanta 100.000 coches en total.` |
| `totalOvertakes200k` | `Corredor 200K` | `Has adelantado 200.000 coches en total.` | `Adelanta 200.000 coches en total.` |

### Overlander — Catalan (Valencian Meridional) `ca-ES`

| Reference Name | Display Name | Earned Description | Pre-earned Description |
| --- | --- | --- | --- |
| `totalOvertakes1k` | `Corredor 1K` | `Has avançat 1.000 cotxes en total.` | `Avança 1.000 cotxes en total.` |
| `totalOvertakes5k` | `Corredor 5K` | `Has avançat 5.000 cotxes en total.` | `Avança 5.000 cotxes en total.` |
| `totalOvertakes10k` | `Corredor 10K` | `Has avançat 10.000 cotxes en total.` | `Avança 10.000 cotxes en total.` |
| `totalOvertakes20k` | `Corredor 20K` | `Has avançat 20.000 cotxes en total.` | `Avança 20.000 cotxes en total.` |
| `totalOvertakes50k` | `Corredor 50K` | `Has avançat 50.000 cotxes en total.` | `Avança 50.000 cotxes en total.` |
| `totalOvertakes100k` | `Corredor 100K` | `Has avançat 100.000 cotxes en total.` | `Avança 100.000 cotxes en total.` |
| `totalOvertakes200k` | `Corredor 200K` | `Has avançat 200.000 cotxes en total.` | `Avança 200.000 cotxes en total.` |

### Control-Based — Spanish (Spain) `es-ES`

| Reference Name | Display Name | Earned Description | Pre-earned Description |
| --- | --- | --- | --- |
| `controlTap` | `Controles Táctiles` | `Has completado una partida usando los controles táctiles.` | `Completa una partida usando los controles táctiles.` |
| `controlSwipe` | `Controles Deslizantes` | `Has completado una partida usando los controles deslizantes.` | `Completa una partida usando los controles deslizantes.` |
| `controlKeyboard` | `Controles de Teclado` | `Has completado una partida usando el teclado.` | `Completa una partida usando el teclado.` |
| `controlVoiceOver` | `Controles VoiceOver` | `Has completado una partida usando VoiceOver.` | `Completa una partida usando VoiceOver.` |
| `controlDigitalCrown` | `Controles de Corona Digital` | `Has completado una partida usando la Corona Digital.` | `Completa una partida usando la Corona Digital.` |
| `controlGameController` | `Controles de Mando` | `Has completado una partida usando un mando.` | `Completa una partida usando un mando.` |

### Control-Based — Catalan (Valencian Meridional) `ca-ES`

| Reference Name | Display Name | Earned Description | Pre-earned Description |
| --- | --- | --- | --- |
| `controlTap` | `Controls Tàctils` | `Has completat una partida usant els controls tàctils.` | `Completa una partida usant els controls tàctils.` |
| `controlSwipe` | `Controls Lliscants` | `Has completat una partida usant els controls lliscants.` | `Completa una partida usant els controls lliscants.` |
| `controlKeyboard` | `Controls de Teclat` | `Has completat una partida usant el teclat.` | `Completa una partida usant el teclat.` |
| `controlVoiceOver` | `Controls VoiceOver` | `Has completat una partida usant el VoiceOver.` | `Completa una partida usant el VoiceOver.` |
| `controlDigitalCrown` | `Controls de Corona Digital` | `Has completat una partida usant la Corona Digital.` | `Completa una partida usant la Corona Digital.` |
| `controlGameController` | `Controls de Comandament` | `Has completat una partida usant un comandament.` | `Completa una partida usant un comandament.` |

## Sign-Off

Before shipping:

1. Confirm all four app records have synchronized achievement sets.
2. Confirm there are no extra/stale achievement IDs in ASC.
3. Confirm `runOvertakes600`, `runOvertakes700`, `runOvertakes800`, and `totalOvertakes200k` are marked hidden in ASC (not visible to the player until unlocked).
4. Confirm release notes/internal QA note mention GAAD week behavior (third Thursday of May; Monday-Sunday window).
