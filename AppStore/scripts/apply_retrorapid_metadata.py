#!/usr/bin/env python3
"""Apply RetroRapid App Store metadata to 1.5 drafts via helm-asc."""

from __future__ import annotations

import json
import subprocess
import sys
from dataclasses import dataclass

HELM = "/Applications/Helm.app/Contents/Helpers/helm-asc"


@dataclass(frozen=True)
class LocalePack:
    label: str
    localization_id: str
    name: str
    subtitle: str
    keywords: str
    promotional_text: str
    description: str
    whats_new: str


LOCALES: dict[str, LocalePack] = {
    "en-US": LocalePack(
        label="en-US",
        localization_id="",  # filled per platform below
        name="RetroRapid: Arcade Racer",
        subtitle="Dodge Traffic Across 3 Lanes",
        keywords="car,high,score,overtake,reflex,offline,voiceover,haptics,controller,leaderboard,handheld,lcd,endless",
        promotional_text="Dodge traffic and chase high scores in quick retro races, with Game Center, Apple Watch support, and accessibility-first controls.",
        description="""RetroRapid! is a fast 3-lane arcade racer built for quick sessions and high-score chasing.

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

Crash, restart, and beat your best.""",
        whats_new="This update sharpens RetroRapid! with bug fixes and racing polish. The Game Center update is still the star: earn achievements, chase friends on the track, and share clean snapshots of your best runs. Thanks for racing with us.",
    ),
    "en-GB": LocalePack(
        label="en-GB",
        localization_id="",
        name="RetroRapid: Arcade Racer",
        subtitle="Dodge Traffic Across 3 Lanes",
        keywords="endless,accessible,swift,highway,skill,vintage,drive,watch,game,nostalgia,pixel,boost,classic,reflex",
        promotional_text="Dodge traffic and chase high scores in quick retro races, with Game Center, Apple Watch support, and accessibility-first controls.",
        description="""RetroRapid! is a fast 3-lane arcade racer built for quick sessions and high-score chasing.

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

Crash, restart, and beat your best.""",
        whats_new="This update sharpens RetroRapid! with bug fixes and racing polish. The Game Center update is still the star: earn achievements, chase friends on the track, and share clean snapshots of your best runs. Thanks for racing with us.",
    ),
    "en-AU": LocalePack(
        label="en-AU",
        localization_id="",
        name="RetroRapid: Arcade Racer",
        subtitle="Overtake Rivals. Beat Records",
        keywords="chase,mobile,quick,offline,voiceover,haptic,controller,handheld,lcd,leaderboard,high,score,ipad,mac",
        promotional_text="Dodge traffic and chase high scores in quick retro races, with Game Center, Apple Watch support, and accessibility-first controls.",
        description="""RetroRapid! is a fast 3-lane arcade racer built for quick sessions and high-score chasing.

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

Crash, restart, and beat your best.""",
        whats_new="This update sharpens RetroRapid! with bug fixes and racing polish. The Game Center update is still the star: earn achievements, chase friends on the track, and share clean snapshots of your best runs. Thanks for racing with us.",
    ),
    "en-CA": LocalePack(
        label="en-CA",
        localization_id="",
        name="RetroRapid: Arcade Racer",
        subtitle="Chase Records in Quick Races",
        keywords="scoreboard,watch,game,classic,pixel,vintage,boost,nostalgia,ipad,mobile,haptic,lane,mac,drive,swift",
        promotional_text="Dodge traffic and chase high scores in quick retro races, with Game Center, Apple Watch support, and accessibility-first controls.",
        description="""RetroRapid! is a fast 3-lane arcade racer built for quick sessions and high-score chasing.

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

Crash, restart, and beat your best.""",
        whats_new="This update sharpens RetroRapid! with bug fixes and racing polish. The Game Center update is still the star: earn achievements, chase friends on the track, and share clean snapshots of your best runs. Thanks for racing with us.",
    ),
    "es-ES": LocalePack(
        label="es-ES",
        localization_id="",
        name="RetroRapid: Carreras Arcade",
        subtitle="Esquiva tráfico en 3 carriles",
        keywords="coche,record,adelantar,reflejos,clasico,mando,ranking,infinito,puntuacion,conexion,voiceover,logros",
        promotional_text="Esquiva tráfico y supera tu récord en carreras retro rápidas, con Game Center, Apple Watch y controles accesibles.",
        description="""RetroRapid! es un arcade de carreras de 3 carriles pensado para partidas rápidas y para perseguir tu mejor puntuación.

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

Choca, reinicia y supera tu marca.""",
        whats_new="Esta actualización hace que RetroRapid! sea más estable y fiable. Game Center sigue siendo la estrella: logros, amigos en la pista y capturas limpias para compartir tus mejores partidas. Gracias por correr con nosotros.",
    ),
    "ca": LocalePack(
        label="ca",
        localization_id="",
        name="RetroRapid: Carreres Arcade",
        subtitle="Esquiva trànsit en 3 carrils",
        keywords="cotxe,avancaments,reflexos,comandament,lcd,accessibilitat,joc,reloj,puntuacio,connexio,velocitat,mac",
        promotional_text="Esquiva trànsit i supera el teu rècord en carreres retro ràpides, amb Game Center, Apple Watch i controls accessibles.",
        description="""RetroRapid! és un arcade de carreres de 3 carrils pensat per a partides ràpides i per a perseguir la teua millor puntuació.

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

Xoca, reinicia i supera la teua marca.""",
        whats_new="Esta actualització fa que RetroRapid! siga més estable i fiable. Game Center continua sent l'estrela: assoliments, amistats en la pista i captures netes per a compartir les teues millors partides. Gràcies per córrer amb nosaltres.",
    ),
    "es-MX": LocalePack(
        label="es-MX",
        localization_id="",
        name="RetroRapid: Carreras Arcade",
        subtitle="Esquiva carros en 3 carriles",
        keywords="rebasar,reflejos,record,control,ranking,clasico,infinito,puntuacion,reloj,internet,trafico,logros",
        promotional_text="Esquiva carros y supera tu récord en carreras retro rápidas, con Game Center, Apple Watch y controles accesibles.",
        description="""RetroRapid! es un arcade de carreras de 3 carriles pensado para partidas rápidas y para perseguir tu mejor récord.

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

Choca, reinicia y supera tu récord.""",
        whats_new="Esta actualización hace que RetroRapid! sea más estable y fiable. Game Center sigue siendo la estrella: logros, amigos en la pista y capturas limpias para compartir tus mejores partidas. Gracias por correr con nosotros.",
    ),
}

PLATFORM_IDS: dict[str, dict[str, str]] = {
    "iOS": {
        "en-US": "232e55bc-5bbb-43b0-95b9-d877c10a44a8",
        "en-GB": "56d24d0e-2c28-4a6d-a659-8f0803af1405",
        "en-AU": "d809f973-7f44-463f-8ae6-a5e7e931a1e5",
        "en-CA": "6911ddd4-89d8-4628-8be0-c47f7d658a3b",
        "es-ES": "47a0349f-5c5e-4fa8-be97-b94148583211",
        "ca": "2cd5433c-858b-4385-8628-f702e2a0015f",
        "es-MX": "1bc0a5d0-bdcc-4255-8c05-95405c3c2919",
    },
    "macOS": {
        "en-US": "1d3832e5-947d-4e8a-9819-2478b0342e04",
        "en-GB": "b4ac4ead-2da5-4ce1-87c4-b88bbaae000e",
        "en-AU": "78af339a-8f05-4545-b046-de606f8332c4",
        "en-CA": "114533d9-3138-4b72-9914-a0bb4817926f",
        "es-ES": "b64f919a-3b44-4e77-b9b7-8a79a3f02a94",
        "ca": "f01d2437-0653-49af-b3b3-6e5e80c50d7e",
        "es-MX": "110854bd-e0e9-44b4-b49c-7d2c4d9f306e",
    },
}


def apply(
    pack: LocalePack,
    localization_id: str,
    platform: str,
    *,
    include_app_info: bool,
    keywords_only: bool,
) -> dict:
    command = [
        HELM,
        "localization",
        localization_id,
        "update",
        "--keywords",
        pack.keywords,
        "--agent",
    ]
    if not keywords_only:
        command[6:6] = [
            "--promotional-text",
            pack.promotional_text,
            "--description",
            pack.description,
            "--whats-new",
            pack.whats_new,
        ]
    if include_app_info:
        command[4:4] = [
            "--name",
            pack.name,
            "--subtitle",
            pack.subtitle,
        ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    try:
        payload = json.loads(result.stdout) if result.stdout.strip() else {}
    except json.JSONDecodeError:
        payload = {"raw_stdout": result.stdout, "raw_stderr": result.stderr, "returncode": result.returncode}
    if result.returncode != 0 and "error" not in payload:
        payload = {"error": {"message": result.stderr or result.stdout}, "returncode": result.returncode}
    payload["platform"] = platform
    payload["locale"] = pack.label
    payload["localization_id"] = localization_id
    return payload


def main() -> int:
    keywords_only = "--keywords-only" in sys.argv
    results: list[dict] = []
    failures = 0
    version_failures = 0

    for platform, locale_ids in PLATFORM_IDS.items():
        for locale, localization_id in locale_ids.items():
            pack = LOCALES[locale]
            label = f"Keywords {platform} {locale}" if keywords_only else f"{platform} {locale}"
            print(f"Applying {label} ({localization_id})...", flush=True)
            outcome = apply(
                pack,
                localization_id,
                platform,
                include_app_info=False,
                keywords_only=keywords_only,
            )
            results.append(outcome)
            if outcome.get("status") != "ok":
                version_failures += 1
                failures += 1
                print(json.dumps(outcome, indent=2, ensure_ascii=False), flush=True)
            else:
                fields = outcome.get("updatedFields", [])
                print(f"  ok: {', '.join(fields)}", flush=True)

    if keywords_only:
        print("\n=== Summary ===", flush=True)
        for outcome in results:
            status = outcome.get("status", "error")
            label = f"{outcome.get('platform')} {outcome.get('locale')}"
            if status == "ok":
                print(f"OK  {label}: {', '.join(outcome.get('updatedFields', []))}")
            else:
                message = outcome.get("error", {}).get("message", outcome)
                print(f"ERR {label}: {str(message)[:180]}")
        return 1 if version_failures else 0

    print("\nAttempting shared App Information name/subtitle (may be ASC-locked)...", flush=True)
    attempted_app_info: set[str] = set()
    for platform, locale_ids in PLATFORM_IDS.items():
        for locale, localization_id in locale_ids.items():
            if locale in attempted_app_info:
                continue
            attempted_app_info.add(locale)
            pack = LOCALES[locale]
            outcome = apply(
                pack,
                localization_id,
                platform,
                include_app_info=True,
                keywords_only=False,
            )
            results.append(outcome)
            label = f"App Info {locale}"
            if outcome.get("status") == "ok":
                print(f"OK  {label}: {', '.join(outcome.get('updatedFields', []))}")
            else:
                failures += 1
                message = outcome.get("error", {}).get("message", outcome)
                print(f"ERR {label}: {str(message)[:180]}")

    print("\n=== Summary ===", flush=True)
    for outcome in results:
        status = outcome.get("status", "error")
        label = f"{outcome.get('platform')} {outcome.get('locale')}"
        if status == "ok":
            print(f"OK  {label}: {', '.join(outcome.get('updatedFields', []))}")
        else:
            message = outcome.get("error", {}).get("message", outcome)
            print(f"ERR {label}: {str(message)[:180]}")

    return 1 if version_failures else 0


if __name__ == "__main__":
    sys.exit(main())
