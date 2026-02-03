//
//  FontRegistrar.swift
//  RetroRacingShared
//
//  Created by Codex on 03/02/2026.
//

import Foundation
import CoreText

/// Registers shared custom fonts bundled with RetroRacing.
public enum FontRegistrar {

    /// Registers the PressStart2P font across supported platforms.
    /// - Parameter additionalBundles: Extra bundles to search (e.g., app bundle). The shared bundle is searched first.
    /// - Returns: true when the font was successfully registered.
    @discardableResult
    public static func registerPressStart2P(additionalBundles: [Bundle] = []) -> Bool {
        let fontFileName = "PressStart2P-Regular.ttf"
        let sharedBundle = Bundle(for: GameScene.self)
        let candidateBundles = [sharedBundle] + additionalBundles

        let urls: [URL] = candidateBundles.flatMap { bundle in
            [
                bundle.url(forResource: "PressStart2P-Regular", withExtension: "ttf"),
                bundle.url(forResource: fontFileName, withExtension: nil),
                bundle.resourceURL?.appendingPathComponent("Resources/Font/\(fontFileName)", isDirectory: false),
                bundle.resourceURL?.appendingPathComponent("Font/\(fontFileName)", isDirectory: false)
            ]
        }.compactMap { $0 }

        for url in urls where (try? url.checkResourceIsReachable()) == true {
            var error: Unmanaged<CFError>?
            if CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                AppLog.log(AppLog.font, "font registered from \(url.lastPathComponent)")
                return true
            }
            if let error = error?.takeRetainedValue() {
                AppLog.error(AppLog.font, "font registration error: \(error.localizedDescription)")
            }
        }

        AppLog.error(AppLog.font, "font '\(fontFileName)' NOT registered (no reachable URL)")
        return false
    }
}

