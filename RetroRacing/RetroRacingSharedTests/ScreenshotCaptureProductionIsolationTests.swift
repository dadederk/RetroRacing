//
//  ScreenshotCaptureProductionIsolationTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 25/07/2026.
//

import XCTest
@testable import RetroRacingShared

/// Verifies screenshot capture mode is DEBUG-only and ignored in Release builds.
final class ScreenshotCaptureProductionIsolationTests: XCTestCase {
    private var priorCaptureFlag: String?
    private var priorSlideFlag: String?

    override func setUp() {
        super.setUp()
        priorCaptureFlag = ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.captureEnabledKey]
        priorSlideFlag = ProcessInfo.processInfo.environment[ScreenshotCaptureIdentifiers.slideIndexKey]
    }

    override func tearDown() {
        restoreEnvironment(key: ScreenshotCaptureIdentifiers.captureEnabledKey, value: priorCaptureFlag)
        restoreEnvironment(key: ScreenshotCaptureIdentifiers.slideIndexKey, value: priorSlideFlag)
        super.tearDown()
    }

    func testGivenDebugBuildWhenCaptureEnvironmentIsSetThenCaptureModeCanActivate() {
        #if DEBUG
        setEnvironment(key: ScreenshotCaptureIdentifiers.captureEnabledKey, value: "1")
        setEnvironment(key: ScreenshotCaptureIdentifiers.slideIndexKey, value: "0")
        XCTAssertTrue(ScreenshotCaptureConfiguration.isCaptureModeEnabled)
        XCTAssertNotNil(ScreenshotCaptureConfiguration.current)
        #else
        XCTAssertFalse(BuildConfiguration.isDebug)
        #endif
    }

    func testGivenReleaseBuildWhenCaptureEnvironmentIsSetThenCaptureModeStaysDisabled() {
        #if DEBUG
        XCTAssertTrue(BuildConfiguration.isDebug)
        #else
        setEnvironment(key: ScreenshotCaptureIdentifiers.captureEnabledKey, value: "1")
        setEnvironment(key: ScreenshotCaptureIdentifiers.slideIndexKey, value: "0")
        XCTAssertFalse(ScreenshotCaptureConfiguration.isCaptureModeEnabled)
        XCTAssertNil(ScreenshotCaptureConfiguration.current)
        XCTAssertNil(WatchScreenshotCaptureConfiguration.current)
        #endif
    }

    func testGivenBuildConfigurationWhenCheckingIsDebugThenMatchesCompilationCondition() {
        #if DEBUG
        XCTAssertTrue(BuildConfiguration.isDebug)
        #else
        XCTAssertFalse(BuildConfiguration.isDebug)
        #endif
    }

    private func setEnvironment(key: String, value: String) {
        setenv(key, value, 1)
    }

    private func restoreEnvironment(key: String, value: String?) {
        if let value {
            setenv(key, value, 1)
        } else {
            unsetenv(key)
        }
    }
}
