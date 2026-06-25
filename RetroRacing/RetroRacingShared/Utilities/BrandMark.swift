import SwiftUI

/// Branding helpers for RetroRapid!
///
/// ## Brand mark rules
///
/// | Context | Treatment |
/// |---|---|
/// | Installed app display name (`CFBundleDisplayName`) | `RetroRapid!` |
/// | Nav titles, settings labels, about links | `RetroRapid!` via `text`, `phrase`, or `fullName` |
/// | Mid-sentence UI when easy (e.g. "Rate RetroRapid!") | Use `phrase`; italicize `!`; keep trailing punctuation |
/// | Flowing copy and long localized paragraphs | Often `RetroRapid` without `!` for readability |
/// | App Store listing name (`RetroRapid: Arcade Racer`), bundle IDs | No `!` |
enum BrandMark {
    static let baseName = "RetroRapid"
    static let fullName = "\(baseName)!"

    /// Standalone product name with an italic brand mark.
    static var text: Text {
        Text("\(Text(verbatim: baseName))\(Text(verbatim: "!").italic())")
    }

    /// Product name embedded in UI copy, e.g. `phrase(prefix: "Rate ")` → "Rate RetroRapid!".
    static func phrase(prefix: String = "", suffix: String = "") -> Text {
        Text(
            "\(Text(verbatim: "\(prefix)\(baseName)"))\(Text(verbatim: "!").italic())\(Text(verbatim: suffix))"
        )
    }

    /// App-page style section heading: "Why RetroRapid!?"
    static var whySectionTitle: Text {
        phrase(prefix: "Why ", suffix: "?")
    }
}
