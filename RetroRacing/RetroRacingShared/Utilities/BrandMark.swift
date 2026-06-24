import SwiftUI

/// Branding helpers for RetroRapid!
///
/// ## Brand mark rules
///
/// | Context | Treatment |
/// |---|---|
/// | Nav titles, settings labels, about links | `RetroRapid!` via `text`, `phrase`, or `fullName` |
/// | Mid-sentence UI when easy (e.g. "Rate RetroRapid!") | Use `phrase`; italicize `!`; keep trailing punctuation |
/// | Flowing copy and long localized paragraphs | Often `RetroRapid` without `!` for readability |
/// | Repo/project name (`RetroRacing`), bundle IDs, App Store metadata fields | No `!` unless the store listing itself uses the brand mark |
enum BrandMark {
    static let baseName = "RetroRapid"
    static let fullName = "\(baseName)!"

    /// Standalone product name with an italic brand mark.
    static var text: Text {
        Text(baseName) + Text("!").italic()
    }

    /// Product name embedded in UI copy, e.g. `phrase(prefix: "Rate ")` → "Rate RetroRapid!".
    static func phrase(prefix: String = "", suffix: String = "") -> Text {
        Text("\(prefix)\(baseName)") + Text("!").italic() + Text(suffix)
    }

    /// App-page style section heading: "Why RetroRapid!?"
    static var whySectionTitle: Text {
        phrase(prefix: "Why ", suffix: "?")
    }
}
