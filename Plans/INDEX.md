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
| App Store metadata, screenshots, release notes, ASO | `../AppStore/README.md` | `AppStore/docs/`, `aso/README.md` |
| ASO campaigns, GAAD featuring, pricing tests | `aso/README.md` | `AppStore/docs/04-metadata-strategy.md`, `05-metadata-copy.md` |
| SharePlay release campaign | `aso/10-shareplay-release-campaign.md` | `../AppStore/README.md`, `../Requirements/shareplay_multiplayer.md` |
| Game Center challenge infrastructure | `challenges_infrastructure_and_asc_admin_plan.md` | `../Requirements/leaderboard_implementation.md` |
| SharePlay competitive mode | `../Requirements/shareplay_multiplayer.md` | `shareplay_competitive_mode_plan.md` (planning record) |
| SharePlay on macOS | `shareplay_macos_plan.md` | `../Requirements/shareplay_multiplayer.md`, `shareplay_competitive_mode_plan.md` |

## Themed Plans

| Theme | Doc | Notes |
|---|---|---|
| ASO & App Store growth | [aso/README.md](aso/README.md) | Metadata, screenshots, pricing, GAAD featuring |
| Game Center challenges & ASC admin | [challenges_infrastructure_and_asc_admin_plan.md](challenges_infrastructure_and_asc_admin_plan.md) | Infrastructure IDs, not release copy |
| SharePlay competitive mode | [shareplay_competitive_mode_plan.md](shareplay_competitive_mode_plan.md) | ✅ Implemented (2026-07-22); manual 2-device QA passed on 2026-07-23. One small glitch remains as non-blocking polish. |
| SharePlay on macOS | [shareplay_macos_plan.md](shareplay_macos_plan.md) | Planned; extend iOS/iPad SharePlay to macOS via Universal adapter and AppKit sharing presenter. |
| SharePlay release campaign | [aso/10-shareplay-release-campaign.md](aso/10-shareplay-release-campaign.md) | Planned App Store launch package for free SharePlay friend races. |

## Maintenance Rules

- Do not duplicate canonical App Store copy in plan files; link to `AppStore/docs/` instead.
- Mark superseded metadata packs explicitly; do not apply historical packs without review.
- Do not keep a hardcoded App Store file list in `AGENTS.md`; route through this index and `AppStore/README.md`.
