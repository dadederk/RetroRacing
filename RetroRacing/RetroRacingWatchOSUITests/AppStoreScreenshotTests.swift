//
//  AppStoreScreenshotTests.swift
//  RetroRacingWatchOSUITests
//
//  Created by Dani Devesa on 24/07/2026.
//

import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    private let readinessTimeout: TimeInterval = 45
    private let layoutSettlePollInterval: TimeInterval = 0.15
    private let layoutSettleMaxWait: TimeInterval = 2.0

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment[AppStoreScreenshotCaptureConstants.captureEnabledKey] == "1",
            "App Store screenshot UI tests run only through ./retrorapid screenshots capture."
        )
        continueAfterFailure = false
    }

    func testCaptureConfiguredScreenshot() throws {
        let plan = ScreenshotCaptureHelper.capturePlan()
        guard plan.targets.count == 1, let target = plan.targets.first else {
            XCTFail(
                "Expected exactly one screenshot target in \(ScreenshotCaptureHelper.filePlanFileName). " +
                "Run capture-app-store-screenshots instead of invoking this test directly."
            )
            return
        }

        print(
            "Screenshot capture plan: \(target.key) -> " +
            "\(ScreenshotCaptureHelper.outputURL(locale: target.locale, slideIndex: target.slideIndex).path)"
        )

        let outputURL = ScreenshotCaptureHelper.outputURL(
            locale: target.locale,
            slideIndex: target.slideIndex
        )

        do {
            try captureScreenshotOnce(
                locale: target.locale,
                slideIndex: target.slideIndex,
                outputURL: outputURL
            )
            try ScreenshotCaptureHelper.writeReport(
                captured: [target.key],
                skippedExisting: [],
                failures: []
            )
        } catch {
            try? ScreenshotCaptureHelper.writeReport(
                captured: [],
                skippedExisting: [],
                failures: [
                    ScreenshotCaptureReportFailure(
                        target: target.key,
                        attempts: 1,
                        error: error.localizedDescription
                    ),
                ]
            )
            throw error
        }
    }

    private func captureScreenshotOnce(
        locale: String,
        slideIndex: Int,
        outputURL: URL
    ) throws {
        let app = XCUIApplication()
        ScreenshotCaptureHelper.configureLaunch(for: app, locale: locale, slideIndex: slideIndex)
        app.launch()

        defer {
            app.terminate()
        }

        let readinessIdentifier = ScreenshotCaptureHelper.readinessIdentifier(slideIndex: slideIndex)
        let readyElement = app.descendants(matching: .any).matching(identifier: readinessIdentifier).firstMatch
        guard readyElement.waitForExistence(timeout: readinessTimeout) else {
            throw ScreenshotCaptureError.readinessTimedOut(readinessIdentifier)
        }
        try waitForLayoutStability(app: app, readinessElement: readyElement)
        Thread.sleep(forTimeInterval: 0.5)

        let screenshot = XCUIScreen.main.screenshot()
        try ScreenshotCaptureHelper.saveScreenshot(screenshot, to: outputURL)
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ScreenshotCaptureError.missingOutputFile(outputURL.lastPathComponent)
        }
    }

    private func waitForLayoutStability(
        app: XCUIApplication,
        readinessElement: XCUIElement
    ) throws {
        let deadline = Date().addingTimeInterval(layoutSettleMaxWait)
        while Date() < deadline {
            guard readinessElement.exists else {
                throw ScreenshotCaptureError.readinessTimedOut(readinessElement.identifier)
            }
            if app.debugDescription.contains("Loading") == false {
                return
            }
            Thread.sleep(forTimeInterval: layoutSettlePollInterval)
        }
    }
}
