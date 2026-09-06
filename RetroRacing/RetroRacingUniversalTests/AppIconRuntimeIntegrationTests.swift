//
//  AppIconRuntimeIntegrationTests.swift
//  RetroRacingUniversalTests
//
//  Created by Dani Devesa on 13/08/2026.
//

#if os(iOS)
import XCTest
import UIKit
import RetroRacingShared
@testable import RetroRacingUniversal

final class AppIconRuntimeIntegrationTests: XCTestCase {
    @MainActor
    func testGivenRunningApplicationWhenResolvingAlternateIconsThenUIKitAndCatalogAgree() throws {
        // Given
        let suiteName = "AppIconRuntimeIntegrationTests.featureFlag"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let bundleIcons = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        )
        let alternateIcons = try XCTUnwrap(
            bundleIcons["CFBundleAlternateIcons"] as? [String: Any]
        )

        let features = ReleaseFeatureStore(
            platform: .iPhone, userDefaults: defaults, allowsOverrides: true
        )
        features.setOverride(.enabled, for: .alternateIcons)

        // When
        let service = AppIconService(
            changer: UIApplicationAppIconChanger(application: SharedUIApplicationAppIconProxy()),
            featureFlag: ReleaseAppIconFeatureFlag(features: features),
            isGalleryPlatformEnabled: true
        )

        // Then
        XCTAssertTrue(BuildConfiguration.shouldShowDebugFeatures)
        XCTAssertEqual(Set(alternateIcons.keys), Set(AppIconCatalog.alternateSystemIconNames))
        XCTAssertEqual(service.supportsAlternateIcons, UIApplication.shared.supportsAlternateIcons)
        XCTAssertTrue(service.isGalleryAvailable)
    }
}
#endif
