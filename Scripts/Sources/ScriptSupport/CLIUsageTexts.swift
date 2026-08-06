//
//  CLIUsageTexts.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/07/2026.
//

import Foundation

public enum CLIUsageTexts {
    public static func assetAudit() -> String {
        """
        asset-audit — runtime asset footprint validation

        Usage:
          ./retrorapid assets audit [flags…]

        Flags:
          --check    Enforce manifest rules and compiled catalog byte ceilings
          --full     Also run Release packaging builds and framework-embedding checks
        """
    }

    public static func optimizeRuntimeAssets() -> String {
        """
        optimize-runtime-assets — regenerate runtime asset-catalog renditions

        Usage:
          ./retrorapid assets optimize [flags…]

        Flags:
          --check      Compare generated pixels and catalog JSON without writing
          --dry-run    Print the resolved mutation plan without writing
        """
    }

    public static func captureAppStoreScreenshots() -> String {
        """
        capture-app-store-screenshots — localized App Store screenshots via UI tests

        Usage:
          ./retrorapid screenshots capture [flags…]

        Flags:
          --platform iphone|ipad|mac|watch   Platform (default: iphone)
          --all-platforms                    Run iphone → ipad → mac → watch sequentially
          --locales <csv>                    Source locales (default: all source locales)
          --slides <csv>                     Slide indexes (platform-specific count)
          --appearance light|dark            Capture appearance (default: light)
          --force                            Recapture even when staging files exist
          --install-only                     Install staged files without running simulators
          --staging-dir <path>               Staging directory override
          --destination <value>              xcodebuild destination override
          --retries <n>                      Per-target retry count
          --no-status-bar-override           Skip simctl marketing status bar (iPhone/iPad)
          --status-bar-override              Opt-in watch marketing clock (10:09)
          --dry-run                          Print plan without capturing
          --check                            Validate Screenshot Studio after capture
        """
    }

    public static func syncScreenshotStudioLocalizations() -> String {
        """
        sync-screenshot-studio-localizations — Screenshot Studio copy, manifests, and images

        Usage:
          ./retrorapid screenshots sync [flags…]

        Flags:
          --check    Report plist, manifest, and image drift without writing
        """
    }

    public static func generateMetadataDocs() -> String {
        """
        generate-metadata-docs — render metadata documents from the JSON catalog

        Usage:
          ./retrorapid metadata generate [flags…]

        Flags:
          --check             Verify generated documents match disk without writing
          --catalog <path>    Metadata catalog override (default: 1.6)
        """
    }

    public static func applyRetroRapidMetadata() -> String {
        """
        apply-retrorapid-metadata — apply listing metadata through Helm

        Usage:
          ./retrorapid metadata apply [flags…]

        Flags:
          --dry-run            Print Helm plan without applying
          --keywords-only      Update hidden keywords only
          --include-app-info   Retry shared name/subtitle fields
          --helm <path>        Helm CLI path override
          --catalog <path>     Metadata catalog override (default: 1.6)
        """
    }

    public static func applyIAPLocalizations() -> String {
        """
        apply-iap-localizations — EU IAP localizations via Helm or App Store Connect API

        Usage:
          ./retrorapid asc iap [flags…]

        Flags:
          --check      Validate CSV bundles without network calls
          --dry-run    Print apply plan without writes
          --asc-api    Prefer App Store Connect API over Helm file upload
          --helm <path> Helm CLI path override
        """
    }

    public static func applyGameCenterEULocalizations() -> String {
        """
        apply-game-center-eu-localizations — Game Center EU localizations via ASC API

        Usage:
          ./retrorapid asc game-center [flags…]

        Flags:
          --check               Validate JSON catalogs without network calls
          --dry-run             Print planned operations without writes
          --achievements-only   Upload achievements only
          --leaderboards-only   Upload leaderboards only
          --ensure-leaderboards Create and release missing templated leaderboards
        """
    }

    public static func swapAppStoreScreenshots() -> String {
        """
        swap-app-store-screenshots — swap two screenshot positions in App Store Connect

        Usage:
          ./retrorapid asc screenshots swap [flags…]

        Flags:
          --first <n>              First screenshot position (1-based)
          --second <n>             Second screenshot position (1-based)
          --platform iphone|ipad|mac|watch  Limit to one device set
          --dry-run                Print Helm plan without uploading
          --check                  Verify both positions exist without uploading
          --helm <path>            Helm CLI path override
        """
    }
}
