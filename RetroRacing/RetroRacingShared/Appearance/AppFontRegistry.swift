//
//  AppFontRegistry.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import CoreText
import Foundation

/// Registers and validates all bundled app font faces.
@MainActor
public enum AppFontRegistry {
    @discardableResult
    public static func registerBundledFonts(additionalBundles: [Bundle] = []) -> AppFontAvailability {
        let bundles = uniqueBundles([Bundle(for: GameScene.self)] + additionalBundles)
        let faces = AppFontStyle.allCases.flatMap(\.availableFaces)
        var availableNames = Set<String>()

        for face in faces {
            if isPostScriptNameAvailable(face.postScriptName) {
                availableNames.insert(face.postScriptName)
                logAvailable(face: face, reason: "already_registered")
                continue
            }

            guard let url = resourceURL(for: face.fileName, bundles: bundles) else {
                AppLog.warning(
                    AppLog.font,
                    "FONT_RESOURCE",
                    outcome: .failed,
                    fields: [
                        .reason("file_unreachable"),
                        .string("file", face.fileName),
                        .string("postScriptName", face.postScriptName)
                    ]
                )
                continue
            }

            var registrationError: Unmanaged<CFError>?
            let didRegister = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &registrationError)
            if isPostScriptNameAvailable(face.postScriptName) {
                availableNames.insert(face.postScriptName)
                logAvailable(face: face, reason: didRegister ? "registered" : "registered_by_system")
                continue
            }

            let fields: [AppLog.Field] = [
                .reason("registration_error"),
                .string("file", face.fileName),
                .string("postScriptName", face.postScriptName)
            ]
            if let error = registrationError?.takeRetainedValue() {
                AppLog.error(
                    AppLog.font,
                    "FONT_REGISTER",
                    outcome: .failed,
                    fields: fields + AppLog.Field.error(error)
                )
            } else {
                AppLog.error(AppLog.font, "FONT_REGISTER", outcome: .failed, fields: fields)
            }
        }

        return AppFontAvailability(availablePostScriptNames: availableNames)
    }

    public static func isPostScriptNameAvailable(_ postScriptName: String) -> Bool {
        let font = CTFontCreateWithName(postScriptName as CFString, 12, nil)
        return (CTFontCopyPostScriptName(font) as String) == postScriptName
    }

    private static func uniqueBundles(_ bundles: [Bundle]) -> [Bundle] {
        var seenURLs = Set<URL>()
        return bundles.filter { seenURLs.insert($0.bundleURL).inserted }
    }

    private static func resourceURL(for fileName: String, bundles: [Bundle]) -> URL? {
        let file = fileName as NSString
        let resourceName = file.deletingPathExtension
        let fileExtension = file.pathExtension

        for bundle in bundles {
            let candidates = [
                bundle.url(forResource: resourceName, withExtension: fileExtension),
                bundle.url(forResource: fileName, withExtension: nil),
                bundle.url(forResource: resourceName, withExtension: fileExtension, subdirectory: "Resources/Font"),
                bundle.url(forResource: resourceName, withExtension: fileExtension, subdirectory: "Font")
            ]
            if let url = candidates.compactMap({ $0 }).first(where: { (try? $0.checkResourceIsReachable()) == true }) {
                return url
            }
        }
        return nil
    }

    private static func logAvailable(face: AppFontFace, reason: String) {
        AppLog.info(
            AppLog.font,
            "FONT_REGISTER",
            outcome: .succeeded,
            fields: [
                .reason(reason),
                .string("file", face.fileName),
                .string("postScriptName", face.postScriptName)
            ]
        )
    }
}
