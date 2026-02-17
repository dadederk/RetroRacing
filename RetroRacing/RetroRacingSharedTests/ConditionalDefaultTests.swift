//
//  ConditionalDefaultTests.swift
//  RetroRacingSharedTests
//
//  Tests for ConditionalDefault infrastructure
//

import XCTest
@testable import RetroRacingShared

final class ConditionalDefaultTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "test.ConditionalDefaultTests")!
        userDefaults.removePersistentDomain(forName: "test.ConditionalDefaultTests")
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "test.ConditionalDefaultTests")
        userDefaults = nil
        super.tearDown()
    }
    
    // MARK: - Test helper type
    
    enum TestDifficulty: String, Codable, Equatable, ConditionalDefaultValue {
        case easy
        case medium
        case hard
        
        static var systemDefault: TestDifficulty {
            return .medium
        }
    }
    
    // MARK: - Initialization tests
    
    func testGivenNoStoredValueWhenInitializingThenUsesSystemDefault() {
        // Given / When
        let defaultValue = ConditionalDefault<TestDifficulty>()
        
        // Then
        XCTAssertTrue(defaultValue.isUsingSystemDefault)
        XCTAssertEqual(defaultValue.effectiveValue, .medium)
        XCTAssertNil(defaultValue.userOverride)
    }
    
    func testGivenUserOverrideWhenInitializingThenUsesOverride() {
        // Given / When
        let defaultValue = ConditionalDefault<TestDifficulty>(userOverride: .hard)
        
        // Then
        XCTAssertFalse(defaultValue.isUsingSystemDefault)
        XCTAssertEqual(defaultValue.effectiveValue, .hard)
        XCTAssertEqual(defaultValue.userOverride, .hard)
    }
    
    // MARK: - User override tests
    
    func testGivenSystemDefaultWhenSettingUserOverrideThenEffectiveValueChanges() {
        // Given
        var defaultValue = ConditionalDefault<TestDifficulty>()
        
        // When
        defaultValue.setUserOverride(.easy)
        
        // Then
        XCTAssertFalse(defaultValue.isUsingSystemDefault)
        XCTAssertEqual(defaultValue.effectiveValue, .easy)
        XCTAssertEqual(defaultValue.userOverride, .easy)
    }
    
    func testGivenUserOverrideWhenResettingToSystemDefaultThenUsesSystemDefault() {
        // Given
        var defaultValue = ConditionalDefault<TestDifficulty>(userOverride: .hard)
        
        // When
        defaultValue.resetToSystemDefault()
        
        // Then
        XCTAssertTrue(defaultValue.isUsingSystemDefault)
        XCTAssertEqual(defaultValue.effectiveValue, .medium)
        XCTAssertNil(defaultValue.userOverride)
    }
    
    // MARK: - Persistence tests
    
    func testGivenSystemDefaultWhenSavingAndLoadingThenPreservesSystemDefault() {
        // Given
        let original = ConditionalDefault<TestDifficulty>()
        let key = "test_key"
        
        // When
        original.save(to: userDefaults, key: key)
        let loaded = ConditionalDefault<TestDifficulty>.load(from: userDefaults, key: key)
        
        // Then
        XCTAssertTrue(loaded.isUsingSystemDefault)
        XCTAssertEqual(loaded.effectiveValue, .medium)
    }
    
    func testGivenUserOverrideWhenSavingAndLoadingThenPreservesOverride() {
        // Given
        let original = ConditionalDefault<TestDifficulty>(userOverride: .easy)
        let key = "test_key"
        
        // When
        original.save(to: userDefaults, key: key)
        let loaded = ConditionalDefault<TestDifficulty>.load(from: userDefaults, key: key)
        
        // Then
        XCTAssertFalse(loaded.isUsingSystemDefault)
        XCTAssertEqual(loaded.effectiveValue, .easy)
        XCTAssertEqual(loaded.userOverride, .easy)
    }
    
    func testGivenNoStoredDataWhenLoadingThenReturnsSystemDefault() {
        // Given
        let key = "nonexistent_key"
        
        // When
        let loaded = ConditionalDefault<TestDifficulty>.load(from: userDefaults, key: key)
        
        // Then
        XCTAssertTrue(loaded.isUsingSystemDefault)
        XCTAssertEqual(loaded.effectiveValue, .medium)
    }
    
    // MARK: - GameDifficulty integration tests
    
    func testGivenNoOverrideWhenGettingCurrentSelectionThenUsesSystemDefault() {
        // Given
        userDefaults.removeObject(forKey: GameDifficulty.conditionalDefaultStorageKey)
        
        // When
        let selection = GameDifficulty.currentSelection(from: userDefaults)
        
        // Then
        // System default depends on VoiceOver state; we just verify it returns a valid value
        XCTAssertTrue([.cruise, .fast, .rapid].contains(selection))
    }
    
    func testGivenUserOverrideWhenGettingCurrentSelectionThenUsesOverride() {
        // Given
        var conditionalDefault = ConditionalDefault<GameDifficulty>()
        conditionalDefault.setUserOverride(.fast)
        conditionalDefault.save(to: userDefaults, key: GameDifficulty.conditionalDefaultStorageKey)
        
        // When
        let selection = GameDifficulty.currentSelection(from: userDefaults)
        
        // Then
        XCTAssertEqual(selection, .fast)
    }
    
    func testGivenDifferentDifficultiesWhenSettingAndLoadingThenEachPersistsCorrectly() {
        // Given
        let key = GameDifficulty.conditionalDefaultStorageKey
        
        // When/Then: cruise
        var conditionalDefault = ConditionalDefault<GameDifficulty>()
        conditionalDefault.setUserOverride(.cruise)
        conditionalDefault.save(to: userDefaults, key: key)
        XCTAssertEqual(GameDifficulty.currentSelection(from: userDefaults), .cruise)
        
        // When/Then: rapid
        conditionalDefault.setUserOverride(.rapid)
        conditionalDefault.save(to: userDefaults, key: key)
        XCTAssertEqual(GameDifficulty.currentSelection(from: userDefaults), .rapid)
    }

    func testGivenNoAudioOverrideWhenGettingCurrentSelectionThenReturnsValidSystemDefault() {
        // Given
        userDefaults.removeObject(forKey: AudioFeedbackMode.conditionalDefaultStorageKey)

        // When
        let selection = AudioFeedbackMode.currentSelection(from: userDefaults)

        // Then
        XCTAssertTrue(AudioFeedbackMode.allCases.contains(selection))
    }

    func testGivenAudioOverrideWhenGettingCurrentSelectionThenUsesOverride() {
        // Given
        var conditionalDefault = ConditionalDefault<AudioFeedbackMode>()
        conditionalDefault.setUserOverride(.cueLanePulses)
        conditionalDefault.save(to: userDefaults, key: AudioFeedbackMode.conditionalDefaultStorageKey)

        // When
        let selection = AudioFeedbackMode.currentSelection(from: userDefaults)

        // Then
        XCTAssertEqual(selection, .cueLanePulses)
    }
}
