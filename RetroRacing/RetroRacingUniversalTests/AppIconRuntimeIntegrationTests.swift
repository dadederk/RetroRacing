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
        let bundleIcons = try XCTUnwrap(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        )
        let alternateIcons = try XCTUnwrap(
            bundleIcons["CFBundleAlternateIcons"] as? [String: Any]
        )

        // When
        let service = AppIconService(
            changer: UIApplicationAppIconChanger(application: SharedUIApplicationAppIconProxy()),
            isGalleryPlatformEnabled: true,
            availableThemeIDsProvider: {
                [.pocket, .lcd, .eightBit, .sixteenBit]
            }
        )

        // Then
        XCTAssertTrue(BuildConfiguration.shouldShowDebugFeatures)
        XCTAssertEqual(Set(alternateIcons.keys), Set(AppIconCatalog.alternateSystemIconNames))
        XCTAssertEqual(
            service.availableOptions.map(\.id),
            [.classic, .pocket, .lcd, .cartridge, .crt, .retroCartridge, .retroVideoGame, .retroGameBox]
        )
        XCTAssertEqual(service.supportsAlternateIcons, UIApplication.shared.supportsAlternateIcons)
        XCTAssertTrue(service.isGalleryAvailable)
    }
}
#endif
