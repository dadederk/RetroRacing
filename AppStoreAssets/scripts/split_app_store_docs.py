#!/usr/bin/env python3
"""Initial migration helper: split monolithic App Store docs into themed files.

The themed files under AppStoreAssets/docs/ and Plans/aso/ are the canonical
source after migration. Re-running requires restoring the original monolith content
into RETRORAPID_APP_STORE_REFERENCE.md and retrorapid_aso_growth_plan.md first.
"""

from __future__ import annotations

from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
REF = REPO / "AppStoreAssets" / "RETRORAPID_APP_STORE_REFERENCE.md"
GROWTH = REPO / "Plans" / "retrorapid_aso_growth_plan.md"
DOCS = REPO / "AppStoreAssets" / "docs"
ASO = REPO / "Plans" / "aso"


def lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8").splitlines(keepends=True)


def slice_content(src: list[str], start: int, end: int) -> str:
    # 1-based inclusive line numbers
    return "".join(src[start - 1 : end])


def themed_header(
    title: str,
    *,
    hub_label: str,
    hub_path: str,
    parent_label: str,
    parent_path: str,
    updated: str,
    see_also: list[tuple[str, str]] | None = None,
) -> str:
    parts = [
        f"# {title}\n",
        f"\n",
        f"Part of [{hub_label}]({hub_path}). "
        f"Index: [{parent_label}]({parent_path}).\n",
        f"\n",
        f"Last updated: {updated}\n",
    ]
    if see_also:
        parts.append("\n**See also:** ")
        parts.append(" · ".join(f"[{label}]({path})" for label, path in see_also))
        parts.append("\n")
    parts.append("\n---\n\n")
    return "".join(parts)


def write_doc(filename: str, body: str, **header_kw) -> None:
    path = DOCS / filename
    path.write_text(themed_header(**header_kw) + body.lstrip("\n"), encoding="utf-8")


def write_aso(filename: str, body: str, **header_kw) -> None:
    path = ASO / filename
    path.write_text(themed_header(**header_kw) + body.lstrip("\n"), encoding="utf-8")


DOC_HEADER = {
    "hub_label": "App Store docs hub",
    "hub_path": "../README.md",
    "parent_label": "RETRORAPID_APP_STORE_REFERENCE.md",
    "parent_path": "../RETRORAPID_APP_STORE_REFERENCE.md",
}

ASO_HEADER = {
    "hub_label": "ASO & growth plans",
    "hub_path": "README.md",
    "parent_label": "retrorapid_aso_growth_plan.md",
    "parent_path": "../retrorapid_aso_growth_plan.md",
}


def split_reference() -> None:
    src = lines(REF)
    updated = "2026-06-24"

    write_doc(
        "01-limits-and-sources.md",
        slice_content(src, 13, 31),
        title="App Store Limits & Sources",
        updated=updated,
        **DOC_HEADER,
        see_also=[
            ("Metadata copy", "05-metadata-copy.md"),
            ("Validation", "12-validation-results.md"),
        ],
    )

    write_doc(
        "02-listing-snapshot.md",
        slice_content(src, 33, 65),
        title="Current Public Listing Snapshot",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("Metadata strategy", "04-metadata-strategy.md"),
            ("Submission gate", "03-submission-quality-gate.md"),
        ],
    )

    write_doc(
        "03-submission-quality-gate.md",
        slice_content(src, 67, 114),
        title="Submission Quality Gate & Helm Rollout",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("Metadata copy", "05-metadata-copy.md"),
            ("90-day plan", "11-execution-90-day.md"),
            ("Apply script", "../scripts/apply_retrorapid_metadata.py"),
        ],
    )

    strategy = (
        slice_content(src, 116, 153)
        + slice_content(src, 179, 238)
        + slice_content(src, 375, 382)
    )
    write_doc(
        "04-metadata-strategy.md",
        strategy,
        title="Metadata Strategy & ASO Review",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("Metadata copy (staged)", "05-metadata-copy.md"),
            ("Screenshots", "06-screenshots.md"),
            ("Locale expansion", "08-locale-expansion.md"),
        ],
    )

    copy = slice_content(src, 155, 177) + slice_content(src, 240, 373)
    write_doc(
        "05-metadata-copy.md",
        copy,
        title="Staged Metadata Copy",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("Strategy", "04-metadata-strategy.md"),
            ("Validation", "12-validation-results.md"),
            ("Apply script", "../scripts/apply_retrorapid_metadata.py"),
        ],
    )

    write_doc(
        "06-screenshots.md",
        slice_content(src, 384, 464),
        title="Screenshot Assets & Storyboard",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("ES/CA slide copy", "../../Plans/aso/02-screenshot-localization-copy.md"),
            ("PPO", "09-product-page-optimization.md"),
        ],
    )

    write_doc(
        "07-release-notes-voice.md",
        slice_content(src, 466, 490),
        title="Release-Note Voice",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[("What's New copy", "05-metadata-copy.md#whats-new-candidate")],
    )

    write_doc(
        "08-locale-expansion.md",
        slice_content(src, 492, 564),
        title="Country & Language Expansion",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("Cross-localization", "04-metadata-strategy.md#cross-localization-strategy"),
            ("Localization requirements", "../../Requirements/localization.md"),
        ],
    )

    write_doc(
        "09-product-page-optimization.md",
        slice_content(src, 566, 577),
        title="Product Page Optimization",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("Screenshot ASO variants", "06-screenshots.md#screenshot-title-aso-variants-first-three-slides"),
            ("Improvement loop", "10-aso-improvement-loop.md"),
        ],
    )

    write_doc(
        "10-aso-improvement-loop.md",
        slice_content(src, 579, 592),
        title="Next ASO Improvement Loop",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("90-day execution", "11-execution-90-day.md"),
            ("Listing snapshot", "02-listing-snapshot.md"),
        ],
    )

    write_doc(
        "11-execution-90-day.md",
        slice_content(src, 594, 630),
        title="90-Day Execution Plan",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("Submission gate", "03-submission-quality-gate.md"),
            ("ASO growth plan", "../../Plans/aso/README.md"),
        ],
    )

    write_doc(
        "12-validation-results.md",
        slice_content(src, 632, 646),
        title="Metadata Validation Results",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[
            ("Metadata copy", "05-metadata-copy.md"),
            ("Limits", "01-limits-and-sources.md"),
        ],
    )

    write_doc(
        "13-open-questions.md",
        slice_content(src, 648, 655),
        title="Open Questions",
        hub="../README.md",
        parent="../RETRORAPID_APP_STORE_REFERENCE.md",
        updated=updated,
        see_also=[("Submission gate", "03-submission-quality-gate.md")],
    )


def split_growth_plan() -> None:
    src = lines(GROWTH)
    updated = "2026-03-14 (campaign); brand status refreshed 2026-06-24"

    write_aso(
        "01-decisions-and-priorities.md",
        slice_content(src, 7, 34),
        title="ASO Decisions & Priorities",
        hub="README.md",
        parent="../retrorapid_aso_growth_plan.md",
        updated=updated,
        see_also=[
            ("Canonical metadata", "../../AppStoreAssets/docs/05-metadata-copy.md"),
            ("90-day plan", "../../AppStoreAssets/docs/11-execution-90-day.md"),
        ],
    )

    write_aso(
        "02-screenshot-localization-copy.md",
        slice_content(src, 36, 135),
        title="Screenshot Localization Copy (All Slides)",
        hub="README.md",
        parent="../retrorapid_aso_growth_plan.md",
        updated=updated,
        see_also=[
            ("Current storyboard", "../../AppStoreAssets/docs/06-screenshots.md"),
        ],
    )

    write_aso(
        "03-metadata-v1-superseded.md",
        slice_content(src, 137, 233),
        title="Metadata Pack v1 (Superseded)",
        hub="README.md",
        parent="../retrorapid_aso_growth_plan.md",
        updated=updated,
        see_also=[
            ("Current staged copy", "../../AppStoreAssets/docs/05-metadata-copy.md"),
            ("Current strategy", "../../AppStoreAssets/docs/04-metadata-strategy.md"),
        ],
    )

    write_aso(
        "04-pricing-strategy.md",
        slice_content(src, 235, 259),
        title="IAP Pricing Test Strategy",
        hub="README.md",
        parent="../retrorapid_aso_growth_plan.md",
        updated=updated,
        see_also=[("Monetization requirements", "../../Requirements/monetization.md")],
    )

    write_aso(
        "05-operational-checklist-60-day.md",
        slice_content(src, 287, 308),
        title="60-Day Operational Checklist (Historical)",
        hub="README.md",
        parent="../retrorapid_aso_growth_plan.md",
        updated=updated,
        see_also=[
            ("Current 90-day plan", "../../AppStoreAssets/docs/11-execution-90-day.md"),
        ],
    )

    write_aso(
        "06-gaad-featuring.md",
        slice_content(src, 310, 506),
        title="GAAD Featuring Nomination",
        hub="README.md",
        parent="../retrorapid_aso_growth_plan.md",
        updated=updated,
        see_also=[
            ("GAAD nomination draft", "../../Docs/GAADYS_2026_RETRORAPID_NOMINATION_DRAFT.md"),
            ("Screenshots", "../../AppStoreAssets/docs/06-screenshots.md"),
        ],
    )

    write_aso(
        "07-sources.md",
        slice_content(src, 508, 522),
        title="ASO Plan Sources",
        hub="README.md",
        parent="../retrorapid_aso_growth_plan.md",
        updated=updated,
        see_also=[("App Store limits", "../../AppStoreAssets/docs/01-limits-and-sources.md")],
    )

    # Wave 1/2 locale expansion from growth plan - brief pointer file
    locale_body = (
        slice_content(src, 261, 285)
        + "\n> **Canonical expansion tiers:** see "
        "[Country & Language Expansion](../../AppStoreAssets/docs/08-locale-expansion.md).\n"
    )
    write_aso(
        "08-locale-expansion-waves.md",
        locale_body,
        title="Locale Expansion Waves (Summary)",
        hub="README.md",
        parent="../retrorapid_aso_growth_plan.md",
        updated=updated,
        see_also=[
            ("Full expansion strategy", "../../AppStoreAssets/docs/08-locale-expansion.md"),
        ],
    )


def main() -> None:
    split_reference()
    split_growth_plan()
    print("Split complete.")


if __name__ == "__main__":
    main()
