//
//  HelmScreenshotModels.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

public enum HelmScreenshotPlatform: String, Sendable, CaseIterable {
    case iphone
    case ipad
    case mac
    case watch

    public var ascPlatformCode: String {
        switch self {
        case .iphone, .ipad, .watch:
            "IOS"
        case .mac:
            "MAC_OS"
        }
    }

    public var deviceTypes: Set<String> {
        switch self {
        case .iphone:
            ["APP_IPHONE_65", "APP_IPHONE_67"]
        case .ipad:
            ["APP_IPAD_PRO_3GEN_129"]
        case .mac:
            ["APP_DESKTOP"]
        case .watch:
            ["APP_WATCH_ULTRA"]
        }
    }
}

public struct HelmScreenshotDownloadResponse: Decodable, Sendable {
    public let rootPath: String
    public let status: String?
}

public struct HelmAppVersionSummary: Decodable, Sendable {
    public let id: String
    public let platform: String
    public let state: String
    public let versionString: String
}

public struct HelmScreenshotSwapOptions: Sendable {
    public static let defaultAppID = "6758641625"
    public static let defaultVersion = "1.5"

    public let helmPath: String
    public let versionID: String?
    public let appID: String
    public let versionString: String
    public let ascPlatformCode: String
    public let platform: HelmScreenshotPlatform
    public let firstPosition: Int
    public let secondPosition: Int
    public let locales: [String]
    public let dryRun: Bool
    public let checkOnly: Bool

    public init(
        helmPath: String,
        versionID: String?,
        appID: String,
        versionString: String,
        ascPlatformCode: String,
        platform: HelmScreenshotPlatform,
        firstPosition: Int,
        secondPosition: Int,
        locales: [String],
        dryRun: Bool,
        checkOnly: Bool
    ) {
        self.helmPath = helmPath
        self.versionID = versionID
        self.appID = appID
        self.versionString = versionString
        self.ascPlatformCode = ascPlatformCode
        self.platform = platform
        self.firstPosition = firstPosition
        self.secondPosition = secondPosition
        self.locales = locales
        self.dryRun = dryRun
        self.checkOnly = checkOnly
    }
}

public struct HelmScreenshotSwapSummary: Sendable {
    public let rootPath: String
    public let localesTouched: Int
    public let deviceSwaps: Int
    public let stagingPath: String?

    public init(
        rootPath: String,
        localesTouched: Int,
        deviceSwaps: Int,
        stagingPath: String?
    ) {
        self.rootPath = rootPath
        self.localesTouched = localesTouched
        self.deviceSwaps = deviceSwaps
        self.stagingPath = stagingPath
    }
}
