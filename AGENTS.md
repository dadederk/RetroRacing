# AGENTS.md

AI agent operating contract for **RetroRacing** (repo/project name). User-facing product brand: **RetroRapid!**.

## Quick Profile

- **Role**: Senior Apple-platform engineer focused on SwiftUI, SpriteKit, accessibility, and multi-platform game development.
- **Platforms**: iOS 26.0+, watchOS 26.0+, tvOS 26.0+, macOS 26.0+, visionOS 26.0+.
- **Primary stack**: SwiftUI, SpriteKit, Game Center, StoreKit, protocol-driven architecture.
- `@AGENTS.md` refers to this file.
- Doc authoring rules: [`DOC_STYLE.md`](DOC_STYLE.md).

## Non-Negotiable Rules

1. Route implementation and review through `Requirements/INDEX.md` before implementing features.
2. Keep the app compiling after every code change; unit tests must pass after code changes.
3. Update affected requirement docs when behavior changes.
4. Use protocol-based dependency injection — no default instantiations in `init` for business dependencies.
5. Maximize code reuse — platform-agnostic logic goes in `RetroRacingShared/`.
6. Never use `#if os()` in the service layer — use configuration injection.
7. Never duplicate logic between platforms — refactor to the shared module.
8. Never force-unwrap optionals — guard and fail safely.
9. Use standard file headers for new Swift source files with `Created by Dani Devesa`.
10. Route App Store listing and ASO work through `Plans/INDEX.md`; do not hardcode store doc paths in `AGENTS.md`.
11. Route repository automation through `Scripts/README.md` and `Scripts/CONVENTIONS.md`.

## Start Here

1. Open `Requirements/INDEX.md` and the routed contract files for the task.
2. Load **retrorapid-conventions** or `AGENTS_EXAMPLES.md` only when patterns are unclear.
3. Consult the applicable skill for SwiftUI, concurrency, accessibility, or testing.
4. Review nearby implementation/tests before editing.
5. Validate and summarize changed behavior, tests affected, and residual risk.

High-risk supplemental reading:

| Change area | Read when needed |
|---|---|
| Architecture, DI, SpriteKit patterns | `.cursor/skills/retrorapid-conventions/SKILL.md` |
| Code examples (optional) | `AGENTS_EXAMPLES.md` |
| App Store metadata, ASO, screenshots | `Plans/INDEX.md` → `AppStore/README.md` |
| Repository automation / `Scripts/` | `Scripts/README.md`, `Scripts/CONVENTIONS.md` |
| Agent skills install, MCP config | `AGENTS_PLAYBOOKS/agent_tooling.md` |

## Documentation Routing

Do not duplicate task routing tables in this file. Use the index or hub for each tree:

| Kind | Path | Use for |
|---|---|---|
| — | `Requirements/INDEX.md` | Shipped in-app behavior (task routing + contract files) |
| INDEX | `Plans/INDEX.md` | Roadmap, themed plans, App Store task routing |
| README | `AppStore/README.md` | Listing copy, ASO, screenshots, rollout |
| README | `Plans/aso/README.md` | ASO campaigns and featuring playbooks |
| README | `Scripts/README.md` | Script commands, recipes, mutation safety |
| — | `Scripts/CONVENTIONS.md` | Script engineering standards and package layout |
| — | `AGENTS_PLAYBOOKS/` | Cross-cutting operational checklists |
| — | `Docs/` | Working drafts only (see `Docs/README.md`) |

### Naming conventions

- **Top-level doc trees:** PascalCase (`Requirements`, `Plans`, `AppStore`, `Docs`).
- **Sub-routers and catalogs:** lowercase (`appendices`, `aso`, `docs`).
- **Hub files:** `INDEX.md` for plan routers; `README.md` for operational hubs.
- **Themed reference docs:** numbered kebab-case under `AppStore/docs/`.
- **Legacy monoliths** at a tree root redirect to the hub; do not edit them as canonical source.

## Engineering Guardrails

- Top-level methods read as orchestration; extract cohesive logic into well-named helpers.
- Views orchestrate; services own business logic; models store state.
- ~200 lines of production code per file (guideline; exclude `#Preview` blocks).
- Preserve user changes in a dirty working tree; do not revert unrelated work.
- Prefer self-documenting names; comment only non-obvious reasoning.

### Skills

Load on demand. Paths use upstream package names — never fork-rename the directory or `name` field in `SKILL.md`. Update vendored skills with the upstream tool (e.g. `npx skills update ios-accessibility`).

| Skill | Path | Use when |
|---|---|---|
| `retrorapid-conventions` | `.cursor/skills/` | DI, SpriteKit+SwiftUI, logging, shared module boundaries |
| `ios-accessibility` | `.agents/skills/` | VoiceOver, Dynamic Type, SpriteKit labels, game UI |
| `swiftui-expert-skill` | `.agents/skills/` | SwiftUI structure and performance |
| `swift-concurrency` | `.agents/skills/` | Strict concurrency, `@MainActor`, Sendable |
| `swift-testing-expert` | `.agents/skills/` | Swift Testing in `Scripts/`; XCTest migration guidance |
| `app-store-aso` | `.agents/skills/` | ASO review; Scripts metadata pipeline is canonical |

Project-specific rules stay in **retrorapid-conventions**; vendored skills remain generic references. Retro accessibility overlays: `.agents/skills/ios-accessibility/references/retrorapid-patterns.md`. Skills install paths and MCP session defaults: `AGENTS_PLAYBOOKS/agent_tooling.md`.

## Public Shipping vs Implemented Targets

All six platform targets are implemented in Xcode. Public App Store shipping differs:

| Platform | Target | Public status |
|---|---|---|
| iPhone / iPad / macOS | `RetroRacingUniversal` | Shipping |
| Apple Watch | `RetroRacingWatchOS` | Shipping |
| tvOS | `RetroRacingTvOS` | Built, not publicly listed |
| visionOS | `RetroRacingVisionOS` | Public placeholder ("Coming Soon") |

Do not treat tvOS or visionOS as equal shipping promises in metadata, screenshots, or user-facing copy. See `AppStore/docs/02-listing-snapshot.md` and `AppStore/docs/06-screenshots.md`.

## Validation

```bash
swift test --package-path Scripts
swift run --package-path Scripts run-tests
```

Documentation checks: `swift run --package-path Scripts check-documentation`

## Brand Mark

User-facing product name is **RetroRapid!** (repo/project folder remains `RetroRacing`).

| Context | Treatment |
|---|---|
| Installed app display name | `RetroRapid!` |
| Nav titles, settings labels, about links | `RetroRapid!` — use `BrandMark.text`, `BrandMark.phrase`, or `BrandMark.fullName` |
| Mid-sentence UI when easy (e.g. "Rate RetroRapid!") | Keep the brand mark; italicize `!` via `BrandMark.phrase`; keep trailing punctuation |
| Flowing copy and long localized paragraphs | Often `RetroRapid` without `!` for readability |
| App Store listing name (`RetroRapid: Arcade Racer`), bundle IDs, internal types | No `!` |

Implementation: `RetroRacingShared/Utilities/BrandMark.swift`.

## Workspace Shortcuts

- Requirements: `Requirements/INDEX.md`
- Shared code: `RetroRacing/RetroRacingShared/`
- Services: `RetroRacing/RetroRacingShared/Services/`
- Platform UIs: `RetroRacingUniversal/`, `RetroRacingWatchOS/`, `RetroRacingTvOS/`, `RetroRacingVisionOS/`
- Tests: `RetroRacingUniversalTests/`, `RetroRacingSharedTests/`
- Localization: `RetroRacing/RetroRacingShared/Localizable.xcstrings`
- Scripts: `Scripts/README.md`, `Scripts/CONVENTIONS.md`
- Agent tooling: `AGENTS_PLAYBOOKS/agent_tooling.md`
