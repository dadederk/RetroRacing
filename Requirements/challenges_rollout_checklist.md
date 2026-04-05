# Challenges Rollout Checklist (ASC + Developer Portal)

## Scope

This checklist is for production rollout of the 20-achievement challenge set, including:

1. Existing challenge IDs (including `com.accessibilityUpTo11.RetroRacing.ach.control.gamecontroller`).
2. New GAAD event challenge (`com.accessibilityUpTo11.RetroRacing.ach.event.gaad.assistive`).
3. Capability and provisioning validation across shipped app bundle IDs.

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
3. Ensure all 20 challenge IDs exist exactly as listed below.
4. Ensure each achievement has localized metadata in EN/ES/CA.
5. Ensure `com.accessibilityUpTo11.RetroRacing.ach.control.gamecontroller` is present (alignment with code).
6. Ensure `com.accessibilityUpTo11.RetroRacing.ach.event.gaad.assistive` exists with GAAD localization text.
7. Attach the Game Center configuration to the active release version/build for each platform app record.

## Achievement IDs (Must Match Code Exactly)

Run overtakes:

1. `com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0100`
2. `com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0200`
3. `com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0500`
4. `com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0600`
5. `com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0700`
6. `com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0800`

Total overtakes:

1. `com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.001k`
2. `com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.005k`
3. `com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.010k`
4. `com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.020k`
5. `com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.050k`
6. `com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.100k`
7. `com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.200k`

Control:

1. `com.accessibilityUpTo11.RetroRacing.ach.control.tap`
2. `com.accessibilityUpTo11.RetroRacing.ach.control.swipe`
3. `com.accessibilityUpTo11.RetroRacing.ach.control.keyboard`
4. `com.accessibilityUpTo11.RetroRacing.ach.control.voiceover`
5. `com.accessibilityUpTo11.RetroRacing.ach.control.crown`
6. `com.accessibilityUpTo11.RetroRacing.ach.control.gamecontroller`

Event:

1. `com.accessibilityUpTo11.RetroRacing.ach.event.gaad.assistive`

## GAAD Localization Payload (New Achievement)

1. EN title: `GAAD Assistive Week`
2. EN description: `Complete a run during GAAD week while using an assistive technology.`
3. ES title: `Semana GAAD Asistiva`
4. ES description: `Completa una partida durante la semana de GAAD usando una tecnología de asistencia.`
5. CA title: `Setmana GAAD Assistiva`
6. CA description: `Completa una partida durant la setmana de GAAD usant una tecnologia d'assistència.`

## Sandbox Validation Checklist

Run these checks in Game Center sandbox accounts:

1. Fresh account can unlock normal challenges and receive achievement sync.
2. GAAD challenge unlocks only when:
   - Run completes in GAAD week window for local device year.
   - Qualifying assistive technology is active.
3. Outside GAAD week, GAAD challenge does not unlock even with assistive technology active.
4. Offline/auth-delayed unlocks eventually sync after authentication via replay triggers.
5. watchOS path qualifies via VoiceOver-only behavior (v1 scope).

## Sign-Off

Before shipping:

1. Confirm all four app records have synchronized achievement sets.
2. Confirm there are no extra/stale achievement IDs in ASC.
3. Confirm release notes/internal QA note mention GAAD week behavior (third Thursday of May; Monday-Sunday window).
