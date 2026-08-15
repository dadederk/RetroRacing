//
//  AppIconAssetModels.swift
//  RetroRacing
//
//  Created by Dani Devesa on 14/08/2026.
//

import Foundation

public enum AppIconAssetMode: Sendable {
    case write
    case check
    case dryRun
}

public enum AppIconPilotID: String, CaseIterable, Sendable {
    case pocket = "RetroRapidPocket"
    case lcd = "RetroRapidLCD"
    case cartridge = "RetroRapidCartridge"
    case crt = "RetroRapidCRT"
    case retroCartridge = "RetroRapidGameCartridge"
    case retroVideoGame = "RetroRapidVideoGame"

    public var previewAssetName: String {
        switch self {
        case .pocket: "AppIconPreviewPocket"
        case .lcd: "AppIconPreviewLCD"
        case .cartridge: "AppIconPreviewCartridge"
        case .crt: "AppIconPreviewCRT"
        case .retroCartridge: "AppIconPreviewRetroCartridge"
        case .retroVideoGame: "AppIconPreviewRetroVideoGame"
        }
    }

    var layerFilenames: [String] {
        switch self {
        case .pocket, .lcd, .cartridge:
            ["Road.svg", "RoadDark.svg", "LaneMarks.svg", "LaneMarksDark.svg", "Car.png"]
        case .crt:
            [
                "Road.svg", "RoadDark.svg", "LaneMarks.svg", "LaneMarksDark.svg",
                "Car.png", "CRTOverlay.svg", "CRTOverlayDark.svg",
            ]
        case .retroCartridge, .retroVideoGame:
            ["Default.png", "Dark.png"]
        }
    }

    var sourceArtworkPath: String {
        switch self {
        case .pocket:
            "RetroRacing/RetroRacingShared/Assets.xcassets/Sprites/GameBoy/playersCar-GameBoy.imageset/playersCar-GameBoy-ipad.png"
        case .lcd:
            "RetroRacing/RetroRacingShared/Assets.xcassets/Sprites/LCD/playersCar-LCD.imageset/playersCar-LCD-ipad.png"
        case .cartridge:
            "RetroRacing/RetroRacingShared/Assets.xcassets/Sprites/8Bit/playersCar-8Bit.imageset/playersCar-8Bit-ipad.png"
        case .crt:
            "RetroRacing/RetroRacingShared/Assets.xcassets/Sprites/16Bit/playersCar-16Bit.imageset/playersCar-16Bit-ipad.png"
        case .retroCartridge:
            "Plans/assets/alternate-app-icon-concepts/retro-cartridge-v4.png"
        case .retroVideoGame:
            "Plans/assets/alternate-app-icon-concepts/retro-video-game-v4.png"
        }
    }

    var darkSourceArtworkPath: String? {
        switch self {
        case .pocket, .lcd, .cartridge, .crt:
            nil
        case .retroCartridge:
            "Plans/assets/alternate-app-icon-concepts/retro-cartridge-dark-v5.png"
        case .retroVideoGame:
            "Plans/assets/alternate-app-icon-concepts/retro-video-game-dark-v5.png"
        }
    }
}

struct AppIconPalette: Sendable {
    let canvas: String
    let road: String?
    let marks: String?
}

enum AppIconPilotPalette {
    static let pocketDefault = AppIconPalette(
        canvas: "#C8DC82",
        road: "#AFC566",
        marks: "#5F6A36"
    )
    static let pocketDark = AppIconPalette(
        canvas: "#171B18",
        road: "#232A22",
        marks: "#C8DC82"
    )
    static let lcdDefault = AppIconPalette(
        canvas: "#F5EBD2",
        road: "#ECE1C8",
        marks: "#8C8679"
    )
    static let lcdDark = AppIconPalette(
        canvas: "#1B1A18",
        road: "#282622",
        marks: "#F5EBD2"
    )
    static let cartridgeDefault = AppIconPalette(
        canvas: "#A6A9B0",
        road: "#858990",
        marks: "#FFE000"
    )
    static let cartridgeDark = AppIconPalette(
        canvas: "#191B21",
        road: "#272A31",
        marks: "#FFE000"
    )
    static let crtDefault = AppIconPalette(
        canvas: "#087D17",
        road: "#151D29",
        marks: "#FFD11A"
    )
    static let crtDark = AppIconPalette(
        canvas: "#3A413B",
        road: "#10141B",
        marks: "#F6C928"
    )
}

public enum AppIconAssetWorkflowError: LocalizedError {
    case generatedAssetsOutOfDate([String])
    case imageLoadFailed(String)
    case imageRenderFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .generatedAssetsOutOfDate(paths):
            "App icon pilot assets are out of date:\n" + paths.joined(separator: "\n")
        case let .imageLoadFailed(path):
            "Could not load app icon source image: \(path)"
        case let .imageRenderFailed(name):
            "Could not render app icon asset: \(name)"
        }
    }
}
