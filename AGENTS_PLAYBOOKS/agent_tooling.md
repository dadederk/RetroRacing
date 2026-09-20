# Agent Tooling Playbook

## Purpose

Canonical setup for agent skills and MCP servers in this repository. `AGENTS.md` lists skills for routing; this playbook holds install paths and MCP session defaults.

## Read This When

- Installing or updating global or project skills.
- Configuring Cursor, Codex, or another agent that reads repo MCP config.
- Using XcodeBuildMCP for interactive build/run/debug across platform schemes.

## Skills Installation

- **Shared upstream skills:** `~/.agents/skills/`, linked into `~/.cursor/skills/` and `~/.claude/skills/`. Install/update globally with `npx skills add <repo> --global --agent codex --skill <name> --yes --copy`.
- **Project conventions:** `.agents/skills/retrorapid-conventions/`, linked into `.cursor/skills/` and `.claude/skills/`.
- **Apple-authored skills:** after updating Xcode, run `xcrun agent skills export --output-dir ~/Downloads/xcode-skills --replace-existing` and refresh the global copies and links.
- Keep upstream skill names unchanged. Project accessibility patterns: `TechDocs/accessibility_patterns.md`.

## MCP Configuration

| Tool | Config file |
|---|---|
| Cursor | `.cursor/mcp.json` |
| Codex | `.codex/config.toml` |

**Prerequisites:** Homebrew `cupertino` at `/opt/homebrew/bin/cupertino`; `npx` for XcodeBuildMCP.

| MCP | Use when |
|---|---|
| `cupertino` | Apple documentation search, symbol lookup, WWDC and framework references |
| `XcodeBuildMCP` | Build, run, test, destination selection, simulator/device interaction, UI inspection, logs |

Codex runs Cupertino with `serve --no-reap` and approval prompts for `search`, `read_document`, and `search_symbols`. Cursor uses `serve` only.

## XcodeBuildMCP Session Defaults

Call `session-set-defaults` before build/run tools:

| Field | Value |
|---|---|
| `projectPath` | `RetroRacing/RetroRacing.xcodeproj` |
| `scheme` | `RetroRacingUniversal` (shipping iOS/iPadOS/macOS), `RetroRacingShared` (shared logic tests) |
| Default iOS destination | `platform=iOS Simulator,name=iPhone 17 Pro` |
| Default macOS destination | `platform=macOS` |

Other schemes (`RetroRacingWatchOS`, `RetroRacingTvOS`, `RetroRacingVisionOS`) only when the task targets those platforms.

Prefer `swift run --package-path Scripts run-tests` and `AGENTS.md` Validation for routine checks. Use XcodeBuildMCP for interactive simulator UI work.
