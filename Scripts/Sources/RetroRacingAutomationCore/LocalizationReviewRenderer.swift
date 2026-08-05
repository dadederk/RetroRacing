//
//  LocalizationReviewRenderer.swift
//  RetroRacing
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation

public enum LocalizationReviewRenderer {
    public static func csv(for snapshot: LocalizationReviewSnapshot) -> String {
        var rows = [[
            "English source", "Translation", "Layer", "Identifier",
            "Limits", "State", "Reviewer notes",
        ]]
        rows += snapshot.items.map {
            [$0.english, $0.translation, $0.layer, $0.identifier, $0.limit, $0.state, ""]
        }
        return rows.map { $0.map(escapeCSV).joined(separator: ",") }
            .joined(separator: "\n") + "\n"
    }

    public static func index(for snapshots: [LocalizationReviewSnapshot]) -> String {
        var lines = [
            "# Localisation review sheets",
            "",
            "Generated from the canonical in-app, App Store, IAP, Game Center, screenshot, and TestFlight sources. Do not edit the CSV copy as a source; record reviewer notes there, then apply approved edits to the canonical layer.",
            "",
            "An approval is valid only when `approvedContentDigest` in `review-status.json` matches the digest below. Any copy change changes the digest and reopens review.",
            "",
            "| Locale | Catalog | Status | Items | Current digest | Reviewer | Date |",
            "|---|---|---|---:|---|---|---|",
        ]
        for snapshot in snapshots {
            let record = snapshot.record
            lines.append(
                "| [\(snapshot.locale)](reviews/\(snapshot.locale).csv) | `\(record.catalogLocale)` | \(record.status.rawValue) | \(snapshot.items.count) | `\(snapshot.digest)` | \(record.reviewer ?? "—") | \(record.reviewedAt ?? "—") |"
            )
        }
        lines += ["", "## Locale guidance", ""]
        for snapshot in snapshots {
            lines.append("- **\(snapshot.locale):** \(snapshot.record.guidance)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private static func escapeCSV(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"")
                || value.contains("\n") || value.contains("\r") else {
            return value
        }
        return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
