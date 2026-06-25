# Script Engineering Conventions

Engineering standards for repository automation in the `Scripts` Swift package.
For commands and recipes, see [README.md](README.md).

## Principles

- **Swift is the default for repository automation.** Active tooling belongs in the local `Scripts` Swift package.
- **Scripts should read like recipes.** Keep executable entry points as short sequences of clearly named operations.
- **Hide implementation detail behind descriptive APIs.** Parsing, validation, rendering, process execution, and filesystem mutation do not belong in `main.swift`.
- **Design mutations explicitly.** Provide `--check`, `--dry-run`, or an equivalent preflight for mutating tools where practical.
- **Test deterministic logic.** Add focused Swift tests for parsing, transformations, validation, and resolved command plans.
- **Document exceptions beside the script.** Non-Swift automation requires a concrete ecosystem constraint that makes Swift impractical.
- **Apply the standard Swift file header** with `Created by Dani Devesa` to new script source files (see `AGENTS.md` Critical Rules).

## Package layout

| Target kind | Role |
|---|---|
| Executable (`Sources/<ToolName>/main.swift`) | CLI parsing and orchestration only |
| Library (`Sources/*Core`, `ScriptSupport`) | Reusable workflows, validation, rendering, process execution |
| Tests (`Tests/`) | Deterministic logic; no subprocesses unless the workflow itself is the subject |

Repository root discovery uses `ScriptSupport.RepositoryLocator` so commands work from any directory inside the repo.

## Mutation safety

Mutating tools must support a non-destructive preflight:

| Flag | Use when |
|---|---|
| `--check` | Comparing generated output or synced files to disk without writing |
| `--dry-run` | Printing the resolved plan or commands without side effects |

Document supported flags in [README.md](README.md) command tables.

## Agent workflow

When changing scripts:

1. Read this file and [README.md](README.md).
2. Keep `main.swift` thin; put logic in library targets.
3. Add or update Swift tests for changed deterministic behavior.
4. Run `swift test --package-path Scripts` and any relevant `--check` / `--dry-run` recipes from the README.

Global agent rules in `AGENTS.md` still apply (unit tests must pass, no force unwraps, explicit dependencies).
