# Plans Index

## Purpose

Single status entrypoint for roadmap and themed plans. Requirements define shipped in-app behavior; plans track remaining work, release operations, and campaign playbooks.

## Read This First

- For feature implementation, read the relevant `/Requirements/` contract files first.
- For App Store listing, metadata, screenshots, and ASO execution, start with `../AppStore/README.md`.
- For ASO campaigns, featuring, and pricing experiments, read `aso/README.md`.
- Completed or superseded campaign packs stay in `aso/` with explicit status labels.

## Task Routing

| Task | Start here | Optional |
|---|---|---|
| 2.0 launch and later personalization, Apple TV, Vision Pro stages | `staged_release_plan.md` | `aso/11-release-2-0-duo-shareplay.md`, `../Requirements/debug_simulation.md` |
| App Store metadata, screenshots, release notes, ASO | `../AppStore/README.md` | `AppStore/docs/`, `aso/README.md` |
| ASO campaigns, GAAD featuring, pricing tests | `aso/README.md` | `AppStore/docs/04-metadata-strategy.md`, `05-metadata-copy.md` |
| SharePlay release campaign | `aso/10-shareplay-release-campaign.md` | `../AppStore/README.md`, `../Requirements/shareplay_multiplayer.md` |
| Version 2.0 SharePlay + iPhone Duo launch | `aso/11-release-2-0-duo-shareplay.md` | `../Docs/iphone-duo-shareplay-nomination-2026.md` |
| Game Center challenge infrastructure | `challenges_infrastructure_and_asc_admin_plan.md` | `../Requirements/leaderboard_implementation.md` |
| SharePlay competitive mode | `../Requirements/shareplay_multiplayer.md` | `shareplay_competitive_mode_plan.md` (planning record) |
| SharePlay deterministic traffic | `shareplay_deterministic_traffic_plan.md` | `../Requirements/shareplay_multiplayer.md`, `shareplay_competitive_mode_plan.md` |
| SharePlay on macOS | `shareplay_macos_plan.md` | `../Requirements/shareplay_multiplayer.md`, `shareplay_competitive_mode_plan.md` |
| visionOS Classic/Tabletop game and Polygon theme | `visionos_spatial_game_plan.md` | `../Requirements/theming_system.md`, `../Requirements/launch_flow.md` |
| Alternate app icons for Unlimited Plays | `alternate_app_icon_plan.md` | `../Requirements/monetization.md`, `../Requirements/theming_system.md` |
| Apple TV public launch | `staged_release_plan.md` | `../Requirements/launch_flow.md`, `../AppStore/README.md` |
| Portfolio infrastructure parity | `portfolio_infrastructure_parity_plan.md` | `../Scripts/README.md`, `../Scripts/CONVENTIONS.md` |

## Themed Plans

| Theme | Doc | Notes |
|---|---|---|
| Four staged releases | [staged_release_plan.md](staged_release_plan.md) | 2.0 SharePlay + Duo is current; 2.1 personalization, 2.2 Apple TV, and 2.3 Vision Pro are working slots, each with its own acceptance gate. |
| ASO & App Store growth | [aso/README.md](aso/README.md) | Metadata, screenshots, pricing, GAAD featuring |
| Game Center challenges & ASC admin | [challenges_infrastructure_and_asc_admin_plan.md](challenges_infrastructure_and_asc_admin_plan.md) | Infrastructure IDs, not release copy |
| SharePlay competitive mode | [shareplay_competitive_mode_plan.md](shareplay_competitive_mode_plan.md) | ✅ Implemented (2026-07-22); manual 2-device QA passed on 2026-07-23. One small glitch remains as non-blocking polish. |
| SharePlay deterministic traffic | [shareplay_deterministic_traffic_plan.md](shareplay_deterministic_traffic_plan.md) | ✅ Implemented (2026-08-01); both SharePlay players use the same indexed traffic-row sequence per round. |
| SharePlay on macOS | [shareplay_macos_plan.md](shareplay_macos_plan.md) | Implemented in code; manual macOS SharePlay QA pending before public claims. |
| SharePlay release campaign | [aso/10-shareplay-release-campaign.md](aso/10-shareplay-release-campaign.md) | Historical campaign groundwork; current 2.0 execution is in the next row. |
| Version 2.0 SharePlay + iPhone Duo launch | [aso/11-release-2-0-duo-shareplay.md](aso/11-release-2-0-duo-shareplay.md) | Current release and featuring sequence, including the Xcode 27.1 gate. |
| visionOS spatial game and Polygon theme | [visionos_spatial_game_plan.md](visionos_spatial_game_plan.md) | Later public stage after Apple TV; physical-device acceptance still required. |
| Alternate app icons | [alternate_app_icon_plan.md](alternate_app_icon_plan.md) | Next planned personalization stage after 2.0; Pocket/LCD/Cartridge/CRT/Disc are layered, three Special Editions use approved flattened artwork, and Polygon remains to convert. |
| Developer CLI (`retrorapid`) | [retrorapid_developer_cli_plan.md](retrorapid_developer_cli_plan.md) | ✅ Done (2026-07-23); unified `./retrorapid` wrapper over Scripts executables and README recipes. |
| Portfolio infrastructure parity | [portfolio_infrastructure_parity_plan.md](portfolio_infrastructure_parity_plan.md) | Proposed; add platform-boundary enforcement, documentation budgets, developer diagnostics, and verified release-E2E evidence while retaining RetroRapid's proven safety foundations. |

## Maintenance Rules

- Do not duplicate canonical App Store copy in plan files; link to `AppStore/docs/` instead.
- Mark superseded metadata packs explicitly; do not apply historical packs without review.
- Do not keep a hardcoded App Store file list in `AGENTS.md`; route through this index and `AppStore/README.md`.
