import XCTest
@testable import RetroRacingShared

final class HighestScoreStoreTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!
    private var store: UserDefaultsHighestScoreStore!

    override func setUp() {
        super.setUp()
        suiteName = "test.highestscore.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = UserDefaultsHighestScoreStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        if let suiteName {
            UserDefaults().removePersistentDomain(forName: suiteName)
        }
        userDefaults = nil
        store = nil
        suiteName = nil
        super.tearDown()
    }

    func testGivenNoStoredScoresWhenReadingCurrentBestThenAllDifficultiesReturnZero() {
        // Given / When / Then
        XCTAssertEqual(store.currentBest(for: .rapid), 0)
        XCTAssertEqual(store.currentBest(for: .fast), 0)
        XCTAssertEqual(store.currentBest(for: .cruise), 0)
    }

    func testGivenHigherScoreWhenUpdatingThenScoreIsStored() {
        // Given / When
        XCTAssertTrue(store.updateIfHigher(10, for: .rapid))

        // Then
        XCTAssertEqual(store.currentBest(for: .rapid), 10)
    }

    func testGivenStoredScoreWhenUpdatingWithLowerOrEqualScoreThenStoredScoreIsUnchanged() {
        // Given
        _ = store.updateIfHigher(10, for: .rapid)

        // When / Then
        XCTAssertFalse(store.updateIfHigher(9, for: .rapid))
        XCTAssertFalse(store.updateIfHigher(10, for: .rapid))
        XCTAssertEqual(store.currentBest(for: .rapid), 10)
    }

    func testGivenRemoteScoreIsHigherWhenSyncingThenStoredScoreIsReplaced() {
        // Given
        _ = store.updateIfHigher(15, for: .rapid)

        // When
        store.syncFromRemote(bestScore: 20, for: .rapid)

        // Then
        XCTAssertEqual(store.currentBest(for: .rapid), 20)
    }

    func testGivenRemoteScoreIsLowerWhenSyncingThenStoredScoreIsUnchanged() {
        // Given
        _ = store.updateIfHigher(25, for: .rapid)

        // When
        store.syncFromRemote(bestScore: 10, for: .rapid)

        // Then
        XCTAssertEqual(store.currentBest(for: .rapid), 25)
    }

    func testGivenScoresAcrossDifficultiesWhenUpdatingThenEachDifficultyStoresItsOwnBest() {
        // Given / When
        _ = store.updateIfHigher(30, for: .cruise)
        _ = store.updateIfHigher(90, for: .rapid)
        _ = store.updateIfHigher(55, for: .fast)

        // Then
        XCTAssertEqual(store.currentBest(for: .cruise), 30)
        XCTAssertEqual(store.currentBest(for: .fast), 55)
        XCTAssertEqual(store.currentBest(for: .rapid), 90)
    }
}
