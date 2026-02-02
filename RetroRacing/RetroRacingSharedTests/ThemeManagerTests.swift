//
//  ThemeManagerTests.swift
//  RetroRacingSharedTests
//

import XCTest
import SwiftUI
@testable import RetroRacingShared

private struct StubTheme: GameTheme {
    let id: String
    let name: String
    let isPremium: Bool
    init(id: String = "stub", name: String = "Stub", isPremium: Bool = false) {
        self.id = id
        self.name = name
        self.isPremium = isPremium
    }
    func backgroundColor(for state: GameState) -> Color { .clear }
    func gridLineColor() -> Color { .gray }
    func gridCellColor() -> Color { .white }
    func playerCarColor() -> Color { .blue }
    func rivalCarColor() -> Color { .red }
    func crashColor() -> Color { .orange }
    func textColor() -> Color { .primary }
    func cellBorderWidth() -> CGFloat { 1 }
    func cornerRadius() -> CGFloat { 0 }
    func playerCarSprite() -> String? { nil }
    func rivalCarSprite() -> String? { nil }
    func crashSprite() -> String? { nil }
    func lifeSprite() -> String? { nil }
}

@MainActor
final class ThemeManagerTests: XCTestCase {

    func testInitialThemeIsFirstWhenNoStoredSelection() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "selectedThemeID")
        defer { defaults.removeObject(forKey: "selectedThemeID") }

        let themes: [GameTheme] = [StubTheme(id: "a"), StubTheme(id: "b")]
        let manager = ThemeManager(initialThemes: themes, userDefaults: defaults)

        XCTAssertEqual(manager.currentTheme.id, "a")
    }

    func testDefaultThemeIDUsedWhenNoStoredSelection() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "selectedThemeID")
        defer { defaults.removeObject(forKey: "selectedThemeID") }

        let themes: [GameTheme] = [StubTheme(id: "a"), StubTheme(id: "b")]
        let manager = ThemeManager(initialThemes: themes, defaultThemeID: "b", userDefaults: defaults)

        XCTAssertEqual(manager.currentTheme.id, "b")
    }

    func testSetThemeUpdatesCurrentAndPersists() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "selectedThemeID")
        defer { defaults.removeObject(forKey: "selectedThemeID") }

        let themes: [GameTheme] = [StubTheme(id: "a"), StubTheme(id: "b")]
        let manager = ThemeManager(initialThemes: themes, userDefaults: defaults)

        manager.setTheme(themes[1])

        XCTAssertEqual(manager.currentTheme.id, "b")
        XCTAssertEqual(defaults.string(forKey: "selectedThemeID"), "b")
    }

    func testIsThemeAvailableFreeThemeReturnsTrue() {
        let themes: [GameTheme] = [StubTheme(id: "free", isPremium: false)]
        let manager = ThemeManager(initialThemes: themes, userDefaults: .standard)

        XCTAssertTrue(manager.isThemeAvailable(themes[0]))
    }

    func testIsThemeAvailablePremiumUnlockedReturnsTrue() {
        let premium = StubTheme(id: "premium", isPremium: true)
        let manager = ThemeManager(initialThemes: [StubTheme(id: "free"), premium], userDefaults: .standard)
        manager.unlockTheme(premium)

        XCTAssertTrue(manager.isThemeAvailable(premium))
    }

    func testUnlockPremiumThemesAddsAllPremiumIDs() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "unlockedThemes")
        defer { defaults.removeObject(forKey: "unlockedThemes") }

        let free = StubTheme(id: "free", isPremium: false)
        let p1 = StubTheme(id: "p1", isPremium: true)
        let p2 = StubTheme(id: "p2", isPremium: true)
        let manager = ThemeManager(initialThemes: [free, p1, p2], userDefaults: defaults)

        manager.unlockPremiumThemes()

        XCTAssertTrue(manager.unlockedThemeIDs.contains("p1"))
        XCTAssertTrue(manager.unlockedThemeIDs.contains("p2"))
    }
}
