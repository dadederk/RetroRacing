//
//  IPhoneDuoScreenshotWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 18/10/2026.
//

import Foundation

public enum IPhoneDuoScreenshotPresentation: String, Sendable {
    case open
    case closed

    public static func forSlide(_ slideIndex: Int) -> Self {
        slideIndex.isMultiple(of: 2) ? .open : .closed
    }
}

public enum IPhoneDuoScreenshotWorkflow {
    private static let captureOrder: [IPhoneDuoScreenshotPresentation] = [.open, .closed]
    public static let hostCaptureTokenEnvironmentKey =
        "RETRORAPID_SCREENSHOT_HOST_CAPTURE_TOKEN"

    public static func shouldApply(platform: String) -> Bool {
        AppStoreScreenshotCaptureDefaults.normalizedPlatform(platform) == "iphoneDuo"
    }

    public static func shouldUseHostCapture(slideIndex: Int, platform: String) -> Bool {
        shouldApply(platform: platform)
            && IPhoneDuoScreenshotPresentation.forSlide(slideIndex) == .open
    }

    public static func hostCaptureSignalURL(
        signal: String,
        token: String
    ) -> URL {
        URL(fileURLWithPath: "/tmp/retrorapid-duo-capture-\(signal)-\(token)")
    }

    public static func orderedTargets(
        _ targets: [ScreenshotCaptureTarget],
        platform: String,
        localeOrder: [String]
    ) -> [ScreenshotCaptureTarget] {
        guard shouldApply(platform: platform) else { return targets }
        let localeRanks = Dictionary(
            uniqueKeysWithValues: localeOrder.enumerated().map { ($0.element, $0.offset) }
        )
        return targets.sorted { lhs, rhs in
            let lhsPresentation = IPhoneDuoScreenshotPresentation.forSlide(lhs.slideIndex)
            let rhsPresentation = IPhoneDuoScreenshotPresentation.forSlide(rhs.slideIndex)
            let lhsPresentationRank = captureOrder.firstIndex(of: lhsPresentation) ?? captureOrder.count
            let rhsPresentationRank = captureOrder.firstIndex(of: rhsPresentation) ?? captureOrder.count
            if lhsPresentationRank != rhsPresentationRank {
                return lhsPresentationRank < rhsPresentationRank
            }
            if lhs.slideIndex != rhs.slideIndex {
                return lhs.slideIndex < rhs.slideIndex
            }
            let lhsRank = localeRanks[lhs.locale] ?? localeOrder.count
            let rhsRank = localeRanks[rhs.locale] ?? localeOrder.count
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            return lhs.locale < rhs.locale
        }
    }

    public static func confirmationPrompt(
        for presentation: IPhoneDuoScreenshotPresentation
    ) -> String {
        "Set the iPhone Duo Simulator to \(presentation.rawValue), then type "
            + "\(presentation.rawValue.uppercased()) and press Return to capture this batch:"
    }

    public static func confirmReady(
        _ presentation: IPhoneDuoScreenshotPresentation,
        dryRun: Bool,
        readConfirmation: () -> String? = { readLine() }
    ) throws {
        let prompt = confirmationPrompt(for: presentation)
        if dryRun {
            print("Would pause before the \(presentation.rawValue) iPhone Duo batch:")
            print(prompt)
            return
        }
        print(prompt, terminator: " ")
        guard let response = readConfirmation()?.trimmingCharacters(in: .whitespacesAndNewlines),
              response.caseInsensitiveCompare(presentation.rawValue) == .orderedSame else {
            throw AppStoreScreenshotCaptureError.duoPoseConfirmationRequired(
                presentation.rawValue
            )
        }
    }
}
