//
//  GameKitImageSerialization.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 26/06/2026.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Cross-platform PNG serialization for GameKit-loaded bitmaps.
enum GameKitImageSerialization {
#if canImport(UIKit)
    static func pngData(from image: UIImage) -> Data? {
        image.pngData()
    }
#elseif canImport(AppKit)
    static func pngData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
#endif

    static func pngData(from image: Any) -> Data? {
#if canImport(UIKit)
        guard let image = image as? UIImage else { return nil }
        return pngData(from: image)
#elseif canImport(AppKit)
        guard let image = image as? NSImage else { return nil }
        return pngData(from: image)
#else
        return nil
#endif
    }
}
