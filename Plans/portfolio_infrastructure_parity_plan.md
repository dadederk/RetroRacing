# Portfolio Infrastructure Parity Plan

**Status:** Proposed

**Status index:** [`INDEX.md`](INDEX.md)

## Summary

Adopt the strongest enforcement and test-evidence patterns proven in Xarra while retaining RetroRapid's mature CLI, safe process runner, asset validation, localization approval workflow, mutation rollback, and Xcode Cloud model as portfolio reference implementations.

This plan changes repository infrastructure only. Shipped multi-platform behavior remains canonical in [`Requirements/`](../Requirements/INDEX.md), and current product work remains in its routed feature plans.

## Current Baseline

- `./retrorapid` and `./retroRapidCli` expose a tested command catalog, interactive menu, composite check recipe, and direct-executable escape hatch.
- ScriptSupport provides file-backed captured output, timeout handling, interrupt cleanup, environment merging, and a large-output regression test.
- Asset generation/audit, localization approvals, metadata, Screenshot Studio synchronization, IAP, Game Center, documentation links, and generated output are checked deterministically.
- Xcode Cloud already documents a protected-branch merge gate and a manually triggered release lane with product-specific archive boundaries.
- Platform-sharing and `#if os()` rules are documented but are not enforced by the Scripts check recipe.
- Documentation validation checks links and metadata sync but does not enforce requirement line budgets or index coverage.
- App-test automation lacks Xarra's unified verified-result, inactivity-watchdog, structured-log, and release-E2E evidence model.

## Portfolio Decisions

- Preserve both existing root CLI names; parity concerns command behavior and safety, not wrapper naming.
- `--check` remains read-only, and mutating workflows retain `--dry-run` or a transactional generation/apply boundary.
- RetroRapid's robust process, asset, localization, rollback, and cloud-release patterns remain local reference implementations rather than a shared package.
- Platform-specific test matrices and game policies remain owned by RetroRapid.

## Phase 1 — Enforce Platform Boundaries

- [ ] Port Xarra's source scanner into RetroRacingAutomationCore with RetroRapid-specific protected roots and adapter/bootstrap allowlists.
- [ ] Reject forbidden platform framework imports and `#if os()` branches in shared service, domain, model, and feature logic.
- [ ] Permit platform conditionals only at declared composition, adapter, UI-entry, and target-boundary files.
- [ ] Emit file/line diagnostics and require every allowlist entry to explain its boundary role.
- [ ] Add positive, negative, and allowlist-fixture tests, then add the validator to `./retrorapid check` and `./retrorapid docs` documentation.
- [ ] Route genuine architecture exceptions through the relevant requirement before expanding the allowlist.

## Phase 2 — Documentation Budgets And Developer Doctor

- [ ] Extend documentation validation with requirement soft/hard line budgets consistent with repository doc style.
- [ ] Verify every main requirement is routed by `Requirements/INDEX.md` and every active plan is routed by this index.
- [ ] Exclude appendices, generated reports, vendored skills, build output, asset-source provenance, and external URLs according to explicit tested policy.
- [ ] Add `doctor` to the existing CLI catalog, reporting Xcode/Swift versions, simulator runtimes, Helm, App Store credentials presence, and the pinned ImageMagick version without printing secrets.
- [ ] Make release-oriented diagnostics fail on unsupported/beta toolchains while ordinary development diagnostics remain informative and non-mutating.

## Phase 3 — Verified Release Test Evidence

- [ ] Introduce a supervised xcodebuild runner that verifies `.xcresult` outcomes, records bounded command/log artifacts, and terminates only after a configurable inactivity interval.
- [ ] Define a small blocking release-E2E catalog for critical launch, gameplay, purchase-state, accessibility, and cross-platform handoff journeys; keep exhaustive behavior in lower-level tests.
- [ ] Reuse typed simulator/destination profiles across app tests and screenshot capture without merging their retry or artifact policies.
- [ ] Preserve RetroRapid's shared, Universal, Watch, tvOS, and visionOS matrices as explicit product configuration.
- [ ] Keep deterministic failures fail-fast, retry only classified infrastructure failures within finite bounds, and make descendant cleanup observable.
- [ ] Document physical-device, Game Center account, StoreKit, SharePlay, and multi-device gaps rather than hiding them behind unreliable automation.

## Phase 4 — Preserve And Share Proven Contracts

- [ ] Keep process-runner large-output, timeout, interrupt, and rollback tests as mandatory regression coverage.
- [ ] Keep asset manifests, optimization checks, localization approval digests, and App Store mutation preflights product-specific and deterministic.
- [ ] Document reusable infrastructure behavior in [`Scripts/CONVENTIONS.md`](../Scripts/CONVENTIONS.md) so sibling apps can port interfaces without copying game policy.
- [ ] Reassess a versioned shared tooling package only after equivalent APIs have shipped independently in the other repositories.

## Acceptance

- `./retrorapid test package`, `./retrorapid docs`, and `./retrorapid check` pass and leave no tracked-file changes.
- Platform-boundary fixtures prove forbidden shared imports/conditionals fail and declared adapters pass.
- Documentation validation rejects broken links, unrouted contracts/plans, and hard line-budget violations.
- `./retrorapid doctor` reports actionable dependency/toolchain state without exposing credentials or changing configuration.
- Release-E2E accepts only verified passing result bundles, retains bounded evidence, handles inactivity, and cleans descendants.
- Existing asset, localization, metadata, IAP, Game Center, screenshot, and Xcode Cloud checks remain green.

## Dependencies

- Boundary policy must follow existing folder-structure, concurrency, and platform requirement contracts.
- Release-E2E scope must follow public platform status and must not turn tvOS or visionOS implementation into a public shipping promise.
- Xcode Cloud and branch-protection configuration remains a human-authorized external setup step.

## Non-goals

- Replacing RetroRapid's CLI, process runner, asset workflow, localization approval system, or Xcode Cloud model.
- Sharing product identifiers, Game Center configuration, simulator matrices, or release policy with sibling apps.
- Making every UI test blocking or automating unreliable multi-device/account-dependent flows.
- Extracting a cross-repository Swift package in this plan.
