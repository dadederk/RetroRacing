import XCTest
@testable import RetroRacingShared

final class BigCarsSettingTests: XCTestCase {
    private static let suiteName = "test.BigCarsSettingTests"
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

    func testGivenAccessibilityTextSizeWhenResolvingSystemDefaultValueThenReturnsTrue() {
        // Given / When
        let isEnabled = BigCarsSetting.systemDefaultValue(isAccessibilityTextSize: true)

        // Then
        XCTAssertTrue(isEnabled)
    }

    func testGivenRegularTextSizeWhenResolvingSystemDefaultValueThenReturnsFalse() {
        // Given / When
        let isEnabled = BigCarsSetting.systemDefaultValue(isAccessibilityTextSize: false)

        // Then
        XCTAssertFalse(isEnabled)
    }

    func testGivenStoredOverrideWhenResolvingCurrentSelectionThenReturnsStoredValue() {
        // Given
        var conditionalDefault = ConditionalDefault<BigCarsSetting>()
        conditionalDefault.setUserOverride(BigCarsSetting(isEnabled: true))
        conditionalDefault.save(
            to: userDefaults,
            key: BigCarsSetting.conditionalDefaultStorageKey
        )

        // When
        let selection = BigCarsPreference.currentSelection(from: userDefaults)

        // Then
        XCTAssertTrue(selection)
    }
}
