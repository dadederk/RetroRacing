# Documentation Style for Agents

## Purpose

Keep agent-facing docs high-signal and low-token. Routers (`AGENTS.md`, `Requirements/INDEX.md`) point to detail; playbooks, skills, examples, and requirement contracts hold depth. Use git history for change tracking — do not add changelogs to `AGENTS.md`.

## Line Budgets

| Doc | Target |
|---|---|
| `AGENTS.md` | under ~150 lines |
| Playbook (`AGENTS_PLAYBOOKS/`) | under ~80 lines |
| `Requirements/INDEX.md` | task routing table + minimal catalog |
| Requirement contract | 40–90 lines; split or move detail when a file grows beyond that |
| TechDoc (`TechDocs/`) | concise explainer with diagrams when helpful |

## Router vs Detail

| Layer | Files | Agent loads when |
|---|---|---|
| Contract | `AGENTS.md` | Every task (rules, skills table, validation) |
| Index | `Requirements/INDEX.md` | Before implementing or reviewing behavior |
| Playbook | `AGENTS_PLAYBOOKS/` | Cross-cutting ops (MCP, tooling) |
| Skill | `.cursor/skills/`, `.agents/skills/` | DI, SpriteKit, conventions, a11y |
| Examples | `AGENTS_EXAMPLES.md` | Optional patterns — not for routine changes |
| Contract | `Requirements/*.md` | Shipped behavior for the task area |
| TechDoc | `TechDocs/*.md` | Durable plain-English architecture and flow explainers |

Do not duplicate routing tables across layers. Reference paths instead of copying rules.

## Content Ownership

| Content | Canonical home |
|---|---|
| Shipped runtime behavior and invariants | `Requirements/` |
| App Store Connect, TestFlight, screenshots, IAP, Game Center operations | `AppStore/` |
| Future work, campaigns, historical plans | `Plans/` |
| Durable architecture maps and onboarding explainers | `TechDocs/` |
| Drafts not yet folded into a canonical hub | `Docs/` |
| Repository automation commands and mutation safety | `Scripts/` |

Delete or link to historical detail instead of preserving it inside requirements. Use git history for old implementation reports, verification transcripts, and changelogs.

## Routing Over TOC

- **Task routing tables** are the primary agent navigation (task → file).
- **Classic TOC** only on long operational hubs (>~100 lines, many sections), e.g. `AppStore/README.md`.
- Do **not** add TOC to `AGENTS.md`, playbooks, or short indexes.

Hub pattern: **Agent quick-start** table first, then optional TOC for humans.

## Required Front Matter

**Playbooks:** `Purpose` + `Read This When`.

**Requirement contracts:** overview or purpose section. Add `Agent summary` when file exceeds ~90 lines.

**TechDocs:** short purpose paragraph, links to the canonical requirement contract when one exists, and diagrams only where they clarify object relationships or flows.

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
- Avoid code snippets in requirements unless the exact API shape is itself the contract.
- Avoid full test inventories in requirements; name behavior classes of tests instead.
- Avoid “Last updated”, author, and changelog blocks in requirements unless generated tooling requires them.

## Maintenance

When adding or renaming requirement files, update `Requirements/INDEX.md` in the same change. When behavior changes, update the contract before or with the code change.

Durable explainers belong in `TechDocs/`; keep `Docs/` for drafts that have not been folded into a canonical router.
