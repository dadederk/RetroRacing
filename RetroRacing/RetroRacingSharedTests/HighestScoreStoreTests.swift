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
        XCTAssertEqual(store.currentBest(), 0)
    }

    func testStoresHigherScore() {
        XCTAssertTrue(store.updateIfHigher(10))
        XCTAssertEqual(store.currentBest(), 10)
    }

    func testDoesNotStoreLowerOrEqualScore() {
        _ = store.updateIfHigher(10)
        XCTAssertFalse(store.updateIfHigher(9))
        XCTAssertFalse(store.updateIfHigher(10))
        XCTAssertEqual(store.currentBest(), 10)
    }

    func testSyncFromRemoteOverridesWhenHigher() {
        _ = store.updateIfHigher(15)
        store.syncFromRemote(bestScore: 20)
        XCTAssertEqual(store.currentBest(), 20)
    }

    func testSyncFromRemoteIgnoresWhenLower() {
        _ = store.updateIfHigher(25)
        store.syncFromRemote(bestScore: 10)
        XCTAssertEqual(store.currentBest(), 25)
    }
}
