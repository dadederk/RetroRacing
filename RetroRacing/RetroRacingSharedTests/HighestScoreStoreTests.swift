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

    func testDefaultsToZero() {
        XCTAssertEqual(store.currentBest(for: .rapid), 0)
        XCTAssertEqual(store.currentBest(for: .fast), 0)
        XCTAssertEqual(store.currentBest(for: .cruise), 0)
    }

    func testStoresHigherScore() {
        XCTAssertTrue(store.updateIfHigher(10, for: .rapid))
        XCTAssertEqual(store.currentBest(for: .rapid), 10)
    }

    func testDoesNotStoreLowerOrEqualScore() {
        _ = store.updateIfHigher(10, for: .rapid)
        XCTAssertFalse(store.updateIfHigher(9, for: .rapid))
        XCTAssertFalse(store.updateIfHigher(10, for: .rapid))
        XCTAssertEqual(store.currentBest(for: .rapid), 10)
    }

    func testSyncFromRemoteOverridesWhenHigher() {
        _ = store.updateIfHigher(15, for: .rapid)
        store.syncFromRemote(bestScore: 20, for: .rapid)
        XCTAssertEqual(store.currentBest(for: .rapid), 20)
    }

    func testSyncFromRemoteIgnoresWhenLower() {
        _ = store.updateIfHigher(25, for: .rapid)
        store.syncFromRemote(bestScore: 10, for: .rapid)
        XCTAssertEqual(store.currentBest(for: .rapid), 25)
    }

    func testStoresBestScorePerDifficultyIndependently() {
        _ = store.updateIfHigher(30, for: .cruise)
        _ = store.updateIfHigher(90, for: .rapid)
        _ = store.updateIfHigher(55, for: .fast)

        XCTAssertEqual(store.currentBest(for: .cruise), 30)
        XCTAssertEqual(store.currentBest(for: .fast), 55)
        XCTAssertEqual(store.currentBest(for: .rapid), 90)
    }
}
