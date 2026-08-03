//
//  ScriptCommandCatalog.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public struct ScriptExecutable: Sendable, Equatable {
    public let name: String
    public let purpose: String

    public init(name: String, purpose: String) {
        self.name = name
        self.purpose = purpose
    }
}

public struct ScriptRecipeStep: Sendable, Equatable {
    public let executable: String
    public let arguments: [String]

    public init(executable: String, arguments: [String] = []) {
        self.executable = executable
        self.arguments = arguments
    }
}

public enum ScriptDispatchPlan: Sendable, Equatable {
    case help
    case list
    case interactiveMenu
    case runSwiftExecutable(executable: String, arguments: [String])
    case runSwiftTestPackage(arguments: [String])
    case runCheckRecipe
}

public enum ScriptCommandCatalog {
    /// Executable product names in `Scripts/Package.swift`, excluding `retrorapid`.
    public static let packageExecutableProductNames: [String] = [
        "run-tests",
        "run-xcodebuild-parallel-canary",
        "check-documentation",
        "asset-audit",
        "optimize-runtime-assets",
        "generate-road-dash-masks",
        "sync-screenshot-studio-localizations",
        "capture-app-store-screenshots",
        "generate-metadata-docs",
        "apply-retrorapid-metadata",
        "apply-iap-localizations",
        "apply-game-center-eu-localizations",
        "print-game-center-eu-localizations",
        "submit-testflight-build",
        "swap-app-store-screenshots",
    ]

    public static let executables: [ScriptExecutable] = [
        ScriptExecutable(
            name: "run-tests",
            purpose: "Runs the shared and universal iOS unit-test targets"
        ),
        ScriptExecutable(
            name: "run-xcodebuild-parallel-canary",
            purpose: "Runs shared and universal unit tests with parallel workers as a canary"
        ),
        ScriptExecutable(
            name: "check-documentation",
            purpose: "Validates markdown links and App Store metadata sync"
        ),
        ScriptExecutable(
            name: "asset-audit",
            purpose: "Audits runtime asset idioms, pixel caps, and compiled catalog budgets"
        ),
        ScriptExecutable(
            name: "optimize-runtime-assets",
            purpose: "Regenerates optimized runtime asset-catalog renditions"
        ),
        ScriptExecutable(
            name: "generate-road-dash-masks",
            purpose: "Renders the lane and lap-strip mask assets"
        ),
        ScriptExecutable(
            name: "sync-screenshot-studio-localizations",
            purpose: "Synchronizes Screenshot Studio copy, manifests, and shared locale images"
        ),
        ScriptExecutable(
            name: "capture-app-store-screenshots",
            purpose: "Captures localized App Store screenshots via UI tests"
        ),
        ScriptExecutable(
            name: "generate-metadata-docs",
            purpose: "Generates metadata copy and validation documents from the canonical JSON catalog"
        ),
        ScriptExecutable(
            name: "apply-retrorapid-metadata",
            purpose: "Applies validated metadata through Helm"
        ),
        ScriptExecutable(
            name: "apply-iap-localizations",
            purpose: "Uploads EU Unlimited Plays IAP localizations through Helm or the ASC API"
        ),
        ScriptExecutable(
            name: "apply-game-center-eu-localizations",
            purpose: "Uploads EU Game Center achievement and leaderboard localizations via the ASC API"
        ),
        ScriptExecutable(
            name: "print-game-center-eu-localizations",
            purpose: "Prints EU Game Center achievement copy for manual ASC entry"
        ),
        ScriptExecutable(
            name: "submit-testflight-build",
            purpose: "Archives iOS/macOS builds and configures TestFlight via Helm"
        ),
        ScriptExecutable(
            name: "swap-app-store-screenshots",
            purpose: "Swaps two screenshot positions in App Store Connect through Helm"
        ),
    ]

    public static let topLevelCommands: [String] = [
        "list",
        "menu",
        "check",
        "test",
        "docs",
        "metadata",
        "asc",
        "screenshots",
        "assets",
        "testflight",
        "run",
    ]

    public static let checkRecipeSteps: [ScriptRecipeStep] = [
        ScriptRecipeStep(executable: "optimize-runtime-assets", arguments: ["--check"]),
        ScriptRecipeStep(executable: "asset-audit", arguments: ["--check"]),
        ScriptRecipeStep(executable: "generate-road-dash-masks", arguments: ["--check"]),
        ScriptRecipeStep(
            executable: "sync-screenshot-studio-localizations",
            arguments: ["--check"]
        ),
        ScriptRecipeStep(executable: "generate-metadata-docs", arguments: ["--check"]),
        ScriptRecipeStep(executable: "check-documentation"),
        ScriptRecipeStep(executable: "apply-iap-localizations", arguments: ["--check"]),
        ScriptRecipeStep(executable: "apply-game-center-eu-localizations", arguments: ["--check"]),
    ]

    public static func executable(named name: String) -> ScriptExecutable? {
        executables.first { $0.name == name }
    }

    public static func isKnownExecutable(_ name: String) -> Bool {
        executable(named: name) != nil
    }

    public static func suggestExecutable(near query: String) -> String? {
        ScriptCommandSuggestion.nearestMatch(
            in: executables.map(\.name),
            query: query
        )
    }

    public static func suggestTopLevelCommand(near query: String) -> String? {
        ScriptCommandSuggestion.nearestMatch(
            in: topLevelCommands,
            query: query
        )
    }

    public static func helpText() -> String {
        """
        RetroRapid developer CLI

        Usage:
          ./retroRapidCli [command] [subcommand] [flags…]
          ./retrorapid …                 # equivalent alias

        Commands:
          list                         List executables and common recipes
          menu                         Interactive command menu (same as no args)
          check                        Verify assets, generated masks, screenshots, metadata, IAP/GC, and docs
          test [flags…]                Run app unit tests (run-tests)
          test parallel-canary [flags…] Run app unit tests with parallel workers as a canary
          test package [flags…]        Run Scripts package unit tests
          docs                         Validate documentation links and metadata sync
          metadata generate [--check]  Generate metadata documents
          metadata apply [--dry-run]   Apply metadata through Helm
          asc iap [flags…]             Upload EU IAP localizations
          asc game-center [flags…]     Upload EU Game Center localizations
          asc game-center print        Print EU Game Center copy for manual entry
          asc screenshots swap [flags…] Swap two screenshot positions through Helm
          screenshots capture [flags…] Capture App Store screenshots
          screenshots sync [flags…]    Sync Screenshot Studio localizations
          assets audit [flags…]        Audit runtime asset footprint
          assets optimize [flags…]     Generate or check optimized runtime assets
          assets masks [flags…]        Generate or check road dash mask assets
          testflight [args…]           Archive and upload TestFlight builds
          run <executable> [flags…]    Run any cataloged executable directly

        Global flags:
          --help, -h                   Show this help

        Direct invocation (advanced):
          swift run --package-path Scripts <executable> [flags…]
        """
    }

    public static func listText() -> String {
        var lines = ["Executables:", ""]
        for executable in executables {
            lines.append("  \(executable.name)")
            lines.append("    \(executable.purpose)")
            lines.append("")
        }
        lines.append("Recipes:")
        lines.append("  ./retrorapid check")
        lines.append("  ./retrorapid assets audit --check")
        lines.append("  ./retrorapid assets optimize --check")
        lines.append("  ./retrorapid test")
        lines.append("  ./retrorapid test parallel-canary --workers 2,4")
        lines.append("  ./retrorapid test package")
        lines.append("  ./retrorapid metadata generate --check")
        lines.append("  ./retrorapid metadata apply --dry-run")
        lines.append("  ./retrorapid asc iap --dry-run")
        lines.append("  ./retrorapid asc game-center --leaderboards-only")
        lines.append("  ./retrorapid asc game-center print")
        lines.append("  ./retrorapid asc screenshots swap --first 3 --second 4 --dry-run")
        lines.append("  ./retrorapid screenshots capture --dry-run")
        lines.append("  ./retrorapid screenshots capture --all-platforms --force")
        lines.append("  ./retrorapid testflight all --dry-run")
        return lines.joined(separator: "\n")
    }
}
