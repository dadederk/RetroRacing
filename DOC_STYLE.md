# Documentation Style for Agents

## Purpose

Keep agent-facing docs high-signal and low-token. Routers (`AGENTS.md`, `Requirements/INDEX.md`) point to detail; playbooks, skills, examples, and requirement contracts hold depth. Use git history for change tracking — do not add changelogs to `AGENTS.md`.

## Line Budgets

| Doc | Target |
|---|---|
| `AGENTS.md` | under ~150 lines |
| Playbook (`AGENTS_PLAYBOOKS/`) | under ~80 lines |
| `Requirements/INDEX.md` | task routing table + minimal catalog |
| Requirement contract | 40–90 lines (longer files use `Agent summary` until split) |

## Router vs Detail

| Layer | Files | Agent loads when |
|---|---|---|
| Contract | `AGENTS.md` | Every task (rules, skills table, validation) |
| Index | `Requirements/INDEX.md` | Before implementing or reviewing behavior |
| Playbook | `AGENTS_PLAYBOOKS/` | Cross-cutting ops (MCP, tooling) |
| Skill | `.cursor/skills/`, `.agents/skills/` | DI, SpriteKit, conventions, a11y |
| Examples | `AGENTS_EXAMPLES.md` | Optional patterns — not for routine changes |
| Contract | `Requirements/*.md` | Shipped behavior for the task area |

Do not duplicate routing tables across layers. Reference paths instead of copying rules.

## Routing Over TOC

- **Task routing tables** are the primary agent navigation (task → file).
- **Classic TOC** only on long operational hubs (>~100 lines, many sections), e.g. `AppStore/README.md`.
- Do **not** add TOC to `AGENTS.md`, playbooks, or short indexes.

Hub pattern: **Agent quick-start** table first, then optional TOC for humans.

## Required Front Matter

**Playbooks:** `Purpose` + `Read This When`.

**Requirement contracts:** overview or purpose section. Add `Agent summary` when file exceeds ~90 lines.

**Appendices:** appendix header when applicable.

## Agent Summary Template

Place after title, before the first major `##` section:

```markdown
## Agent summary

> Narrow tasks may stop here; open the full contract for implementation or review.

- **Scope:** one-line what this file governs
- **Must not break:** 2–4 critical invariants
- **Key files:** primary Swift paths (when helpful)
- **Open:** only if unresolved open items exist
```

## Appendix Header

```markdown
> **Appendix.** Load only when `Requirements/INDEX.md` routes here. Not required for routine changes.
```

## Writing Rules

- Prefer bullet lists and tables over prose blocks.
- One behavior or invariant per bullet.
- Reference `AGENTS.md` and skills — do not copy their full rule text.
- Mark open decisions clearly so agents do not implement without instruction.

## Maintenance

When adding or renaming requirement files, update `Requirements/INDEX.md` in the same change. When behavior changes, update the contract before or with the code change.
