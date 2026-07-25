//
//  AppStoreScreenshotTests.swift
//  RetroRacingUniversalUITests
//
//  Created by Dani Devesa on 23/07/2026.
//

import XCTest

final class AppStoreScreenshotTests: XCTestCase {
    #if os(macOS)
    private let readinessTimeout: TimeInterval = 90
    #else
    private let readinessTimeout: TimeInterval = 45
    #endif
    private let layoutSettlePollInterval: TimeInterval = 0.15
    private let layoutSettleMaxWait: TimeInterval = 2.0
    private let landscapeVisualSettle: TimeInterval = 1.5

    override func setUpWithError() throws {
        continueAfterFailure = false
        #if os(iOS)
        if ScreenshotCaptureHelper.prefersLandscapeCapture() {
            XCUIDevice.shared.orientation = .landscapeRight
            Thread.sleep(forTimeInterval: landscapeVisualSettle)
        }
        #endif
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

    func testCaptureAccessibilitySettingsForEnglishUS() throws {
        try captureScreenshotOnce(
            locale: "en-US",
            slideIndex: 3,
            outputURL: ScreenshotCaptureHelper.outputURL(locale: "en-US", slideIndex: 3)
        )
    }

    private func captureScreenshotOnce(
        locale: String,
        slideIndex: Int,
        outputURL: URL
    ) throws {
        let app = XCUIApplication()
        ScreenshotCaptureHelper.configureLaunch(for: app, locale: locale, slideIndex: slideIndex)
        ScreenshotCaptureHelper.removeReadinessSignals(slideIndex: slideIndex)
        app.launch()

        defer {
            app.terminate()
        }

        #if os(macOS)
        app.activate()
        Thread.sleep(forTimeInterval: 2.0)
        if app.windows.firstMatch.waitForExistence(timeout: 5) == false {
            openCaptureWindowIfNeeded(app: app)
        }
        let window = app.windows.firstMatch
        guard window.waitForExistence(timeout: 30) else {
            print("Mac screenshot capture debug (no window):\n\(app.debugDescription)")
            throw ScreenshotCaptureError.windowMissing
        }
        window.click()
        Thread.sleep(forTimeInterval: 1.0)
        #endif

        let readinessIdentifier = ScreenshotCaptureHelper.readinessIdentifier(slideIndex: slideIndex)
        let readyElement = app.descendants(matching: .any).matching(identifier: readinessIdentifier).firstMatch
        #if os(macOS)
        let readiness = try waitForMacReadiness(
            app: app,
            slideIndex: slideIndex,
            readinessIdentifier: readinessIdentifier,
            readyElement: readyElement
        )
        try waitForLayoutStability(
            app: app,
            readinessElement: readyElement,
            requiresAccessibilityElement: readiness.accessibilityReady
        )
        #else
        guard readyElement.waitForExistence(timeout: readinessTimeout) else {
            throw ScreenshotCaptureError.readinessTimedOut(readinessIdentifier)
        }
        try waitForLayoutStability(app: app, readinessElement: readyElement)
        #endif
        try waitForVisualSettleBeforeCapture()

        let screenshot = takeScreenshotWithRetry(app: app)
        try ScreenshotCaptureHelper.saveScreenshot(screenshot, to: outputURL)
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw ScreenshotCaptureError.missingOutputFile(outputURL.lastPathComponent)
        }
    }

    #if os(macOS)
    private func openCaptureWindowIfNeeded(app: XCUIApplication) {
        app.typeKey("n", modifierFlags: [.command])
        Thread.sleep(forTimeInterval: 1.0)
        if app.windows.firstMatch.waitForExistence(timeout: 2) {
            return
        }
        let fileMenu = app.menuBars.menuBarItems["File"]
        guard fileMenu.waitForExistence(timeout: 2), fileMenu.isHittable else { return }
        fileMenu.click()
        let newWindowItem = fileMenu.menuItems["New Window"]
        guard newWindowItem.waitForExistence(timeout: 2), newWindowItem.isHittable else { return }
        newWindowItem.click()
    }

    private struct MacReadinessState {
        let signalReady: Bool
        let accessibilityReady: Bool
    }

    private func waitForMacReadiness(
        app: XCUIApplication,
        slideIndex: Int,
        readinessIdentifier: String,
        readyElement: XCUIElement
    ) throws -> MacReadinessState {
        let deadline = Date().addingTimeInterval(readinessTimeout)
        while Date() < deadline {
            if readyElement.exists {
                return MacReadinessState(signalReady: false, accessibilityReady: true)
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        print("Mac screenshot readiness debug (accessibility tree):\n\(app.debugDescription)")
        throw ScreenshotCaptureError.readinessTimedOut(readinessIdentifier)
    }
    #endif

    private func waitForLayoutStability(
        app: XCUIApplication,
        readinessElement: XCUIElement,
        requiresAccessibilityElement: Bool = true
    ) throws {
        let deadline = Date().addingTimeInterval(layoutSettleMaxWait)
        while Date() < deadline {
            if requiresAccessibilityElement {
                guard readinessElement.exists else {
                    throw ScreenshotCaptureError.readinessTimedOut(readinessElement.identifier)
                }
            }
            if app.debugDescription.contains("Loading") == false {
                return
            }
            Thread.sleep(forTimeInterval: layoutSettlePollInterval)
        }
    }

    private func waitForVisualSettleBeforeCapture() throws {
        #if os(iOS)
        if ScreenshotCaptureHelper.prefersLandscapeCapture() {
            Thread.sleep(forTimeInterval: landscapeVisualSettle)
        }
        #endif
    }

    private func takeScreenshotWithRetry(app: XCUIApplication) -> XCUIScreenshot {
        for attempt in 1...3 {
            if attempt > 1 {
                Thread.sleep(forTimeInterval: 0.5)
                print("  screenshot retry \(attempt)/3")
            }
            #if os(macOS)
            let window = app.windows.firstMatch
            if window.exists {
                return window.screenshot()
            }
            #endif
            #if os(iOS)
            if ScreenshotCaptureHelper.prefersLandscapeCapture() {
                return XCUIScreen.main.screenshot()
            }
            #endif
            return app.screenshot()
        }
        #if os(macOS)
        return app.windows.firstMatch.screenshot()
        #else
        #if os(iOS)
        if ScreenshotCaptureHelper.prefersLandscapeCapture() {
            return XCUIScreen.main.screenshot()
        }
        #endif
        return app.screenshot()
        #endif
    }
}

enum ScreenshotCaptureError: LocalizedError {
    case readinessTimedOut(String)
    case windowMissing
    case landscapeOrientationTimedOut
    case screenshotTimedOut
    case missingOutputFile(String)
    case emptyScreenshotData
    case portraitOutputInLandscapeCapture(width: Int, height: Int)

    var errorDescription: String? {
        switch self {
        case let .readinessTimedOut(identifier):
            "Timed out waiting for \(identifier)."
        case .windowMissing:
            "Timed out waiting for the RetroRapid! capture window."
        case .landscapeOrientationTimedOut:
            "Timed out waiting for landscape orientation before capture."
        case .screenshotTimedOut:
            "Timed out while requesting screenshot."
        case let .missingOutputFile(fileName):
            "Expected screenshot file was not written: \(fileName)."
        case .emptyScreenshotData:
            "Screenshot data was empty."
        case let .portraitOutputInLandscapeCapture(width, height):
            "Expected landscape iPad capture but output was \(width)x\(height)."
        }
    }
}
