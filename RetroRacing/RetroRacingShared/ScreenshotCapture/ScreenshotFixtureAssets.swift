//
//  ScreenshotFixtureAssets.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum ScreenshotFixtureAssets {
    static let sharedBundle = Bundle(for: BundleAnchor.self)

    static var johnAppleseedAvatarPNGData: Data? {
        pngData(forAssetNamed: "johnAppleseedAvatar")
    }

    private static func pngData(forAssetNamed name: String) -> Data? {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        guard let image = UIImage(named: name, in: sharedBundle, compatibleWith: nil) else {
            return nil
        }
        return image.pngData()
        #elseif canImport(AppKit)
        guard let image = sharedBundle.image(forResource: NSImage.Name(name)),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}

private final class BundleAnchor {}
