import XCTest
@testable import RetroRacingShared

final class DirectTouchSettingTests: XCTestCase {
    private static let suiteName = "test.DirectTouchSettingTests"
    private var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: Self.suiteName)!
        userDefaults.removePersistentDomain(forName: Self.suiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: Self.suiteName)
        userDefaults = nil
        super.tearDown()
    }

    func testGivenSystemDefaultWhenResolvingDirectTouchThenEnabledIsTrue() {
        // Given / When
        let isEnabled = DirectTouchSetting.systemDefault.isEnabled

        // Then
        XCTAssertTrue(isEnabled)
    }

    func testGivenNoStoredOverrideWhenResolvingCurrentSelectionThenDirectTouchIsEnabled() {
        // Given / When
        let isEnabled = DirectTouchPreference.currentSelection(from: userDefaults)

        // Then
        XCTAssertTrue(isEnabled)
    }

    func testGivenStoredDisabledOverrideWhenResolvingCurrentSelectionThenDirectTouchIsDisabled() {
        // Given
        DirectTouchPreference.setUserOverride(false, in: userDefaults)

        // When
        let isEnabled = DirectTouchPreference.currentSelection(from: userDefaults)

        // Then
        XCTAssertFalse(isEnabled)
    }

    func testGivenStoredEnabledOverrideWhenResolvingCurrentSelectionThenDirectTouchIsEnabled() {
        // Given
        DirectTouchPreference.setUserOverride(true, in: userDefaults)

        // When
        let isEnabled = DirectTouchPreference.currentSelection(from: userDefaults)

        // Then
        XCTAssertTrue(isEnabled)
    }
}
