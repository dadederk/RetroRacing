//
//  ThemeID.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

public struct ThemeID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let pocket = ThemeID(rawValue: "pocket")
    public static let lcd = ThemeID(rawValue: "lcd")
    public static let eightBit = ThemeID(rawValue: "8bit")
    public static let sixteenBit = ThemeID(rawValue: "16bit")
    public static let thirtyTwoBit = ThemeID(rawValue: "32bit")
    public static let sixtyFourBit = ThemeID(rawValue: "64bit")
}
