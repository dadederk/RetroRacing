import Foundation

/// Single source of truth for external URLs used across shared views.
enum ExternalLinks {
    static let appSite = URL(string: "https://accessibilityupto11.com/apps/retrorapid/")
    static let ammec = URL(string: "https://www.ammec.org/")
    static let pressStart2P = URL(string: "https://fonts.google.com/specimen/Press+Start+2P")
    static let pressStart2PLicense = URL(
        string: "https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/OFL.txt"
    )
    static let openDyslexic = URL(string: "https://opendyslexic.org")
    static let openDyslexicLicense = URL(
        string: "https://raw.githubusercontent.com/antijingoist/opendyslexic/main/OFL.txt"
    )
    static let atkinsonHyperlegible = URL(string: "https://www.brailleinstitute.org/freefont/")
    static let atkinsonHyperlegibleLicense = URL(
        string: "https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegiblenext/OFL.txt"
    )
    static let lexend = URL(string: "https://www.lexend.com/")
    static let lexendLicense = URL(
        string: "https://raw.githubusercontent.com/google/fonts/main/ofl/lexend/OFL.txt"
    )
}
