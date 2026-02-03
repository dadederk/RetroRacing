//
//  FontPreferenceStoreTests.swift
//  RetroRacingSharedTests
//

import XCTest
import SwiftUI
@testable import RetroRacingShared

@MainActor
final class FontPreferenceStoreTests: XCTestCase {

    func testInitialStyleIsCustomWhenNoStoredValue() {
        let defaults = UserDefaults(suiteName: "FontPreferenceStoreTests.initial")!
        defaults.removeObject(forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: true)
        XCTAssertEqual(store.currentStyle, .custom)
    }

    func testSetStyleUpdatesAndPersists() {
        let defaults = UserDefaults(suiteName: "FontPreferenceStoreTests.set")!
        defaults.removeObject(forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: true)
        store.currentStyle = .systemMonospaced
        XCTAssertEqual(store.currentStyle, .systemMonospaced)
        XCTAssertEqual(defaults.string(forKey: AppFontStyle.storageKey), AppFontStyle.systemMonospaced.rawValue)
    }

    func testWhenCustomFontUnavailableStoredCustomFallsBackToSystem() {
        let defaults = UserDefaults(suiteName: "FontPreferenceStoreTests.unavailable")!
        defaults.set(AppFontStyle.custom.rawValue, forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: false)
        XCTAssertEqual(store.currentStyle, .system)
        XCTAssertFalse(store.isCustomFontAvailable)
    }
}
