//
//  SwiftExecutableLocator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum SwiftExecutableLocator {
    public static func resolve() -> String {
        if let override = ProcessInfo.processInfo.environment["RETRORAPID_SWIFT"],
           override.isEmpty == false,
           FileManager.default.isExecutableFile(atPath: override) {
            return override
        }

        let candidates = [
            "/usr/bin/swift",
            "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift",
        ]
        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return candidate
        }
        return "/usr/bin/swift"
    }
}
