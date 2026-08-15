//
//  AppIconAssetWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 14/08/2026.
//

import AppKit
import Foundation
import ScriptSupport

public enum AppIconAssetWorkflow {
    public static func run(repositoryRoot: URL, mode: AppIconAssetMode) throws {
        let files = try generatedFiles(repositoryRoot: repositoryRoot)
        let obsolete = obsoletePilotFiles(repositoryRoot: repositoryRoot)

        switch mode {
        case .write:
            try FileWork.writeAtomically(files)
            for url in obsolete where FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            print("Generated app icon pilot sources and previews.")
        case .check:
            let stale = stalePaths(
                repositoryRoot: repositoryRoot,
                generatedFiles: files,
                obsoleteFiles: obsolete
            )
            guard stale.isEmpty else {
                throw AppIconAssetWorkflowError.generatedAssetsOutOfDate(stale.sorted())
            }
            print("App icon pilot sources and previews are current.")
        case .dryRun:
            let paths = files.map { FileWork.relativePath(for: $0.url, from: repositoryRoot) }
            print("Would generate \(paths.count) app icon pilot files:")
            for path in paths.sorted() {
                print("  \(path)")
            }
            for url in obsolete where FileManager.default.fileExists(atPath: url.path) {
                print("  remove \(FileWork.relativePath(for: url, from: repositoryRoot))")
            }
        }
    }

    public static func stalePaths(repositoryRoot: URL) throws -> [String] {
        stalePaths(
            repositoryRoot: repositoryRoot,
            generatedFiles: try generatedFiles(repositoryRoot: repositoryRoot),
            obsoleteFiles: obsoletePilotFiles(repositoryRoot: repositoryRoot)
        )
    }

    public static func generatedFiles(repositoryRoot: URL) throws -> [GeneratedFile] {
        let assetsRoot = repositoryRoot.appending(
            path: "RetroRacing/RetroRacingUniversal/Assets"
        )
        let catalogRoot = repositoryRoot.appending(
            path: "RetroRacing/RetroRacingUniversal/Assets.xcassets"
        )
        var files: [GeneratedFile] = []

        let pocket = try themeFiles(
            id: .pocket,
            repositoryRoot: repositoryRoot,
            assetsRoot: assetsRoot,
            catalogRoot: catalogRoot,
            palette: AppIconPilotPalette.pocketDefault,
            darkPalette: AppIconPilotPalette.pocketDark,
            roadGeometry: .pocket,
            spritePath: AppIconPilotID.pocket.sourceArtworkPath,
            carRect: NSRect(x: 122, y: 74, width: 780, height: 520)
        )
        files += pocket

        let lcd = try themeFiles(
            id: .lcd,
            repositoryRoot: repositoryRoot,
            assetsRoot: assetsRoot,
            catalogRoot: catalogRoot,
            palette: AppIconPilotPalette.lcdDefault,
            darkPalette: AppIconPilotPalette.lcdDark,
            roadGeometry: .lcd,
            spritePath: AppIconPilotID.lcd.sourceArtworkPath,
            carRect: NSRect(x: 122, y: 62, width: 780, height: 556)
        )
        files += lcd

        let cartridge = try themeFiles(
            id: .cartridge,
            repositoryRoot: repositoryRoot,
            assetsRoot: assetsRoot,
            catalogRoot: catalogRoot,
            palette: AppIconPilotPalette.cartridgeDefault,
            darkPalette: AppIconPilotPalette.cartridgeDark,
            roadGeometry: .cartridge,
            spritePath: AppIconPilotID.cartridge.sourceArtworkPath,
            carRect: NSRect(x: 72, y: 152, width: 880, height: 614)
        )
        files += cartridge

        files += try specialEditionFiles(
            id: .retroCartridge,
            repositoryRoot: repositoryRoot,
            assetsRoot: assetsRoot,
            catalogRoot: catalogRoot,
            conceptPath: AppIconPilotID.retroCartridge.sourceArtworkPath,
            darkConceptPath: try darkSourcePath(for: .retroCartridge)
        )
        files += try specialEditionFiles(
            id: .retroVideoGame,
            repositoryRoot: repositoryRoot,
            assetsRoot: assetsRoot,
            catalogRoot: catalogRoot,
            conceptPath: AppIconPilotID.retroVideoGame.sourceArtworkPath,
            darkConceptPath: try darkSourcePath(for: .retroVideoGame)
        )
        return files
    }

    private static func themeFiles(
        id: AppIconPilotID,
        repositoryRoot: URL,
        assetsRoot: URL,
        catalogRoot: URL,
        palette: AppIconPalette,
        darkPalette: AppIconPalette,
        roadGeometry: AppIconRoadGeometry,
        spritePath: String,
        carRect: NSRect
    ) throws -> [GeneratedFile] {
        let roadGeometryData = AppIconSVGRenderer.road(geometry: roadGeometry)
        let marksGeometryData = AppIconSVGRenderer.laneMarks(geometry: roadGeometry)
        let road = tintedSVG(roadGeometryData, hex: palette.road ?? palette.canvas)
        let darkRoad = tintedSVG(
            roadGeometryData,
            hex: darkPalette.road ?? darkPalette.canvas
        )
        let marks = tintedSVG(marksGeometryData, hex: palette.marks ?? "#000000")
        let darkMarks = tintedSVG(
            marksGeometryData,
            hex: darkPalette.marks ?? "#FFFFFF"
        )
        let car = try AppIconRasterRenderer.themeCar(
            sourceURL: repositoryRoot.appending(path: spritePath),
            destinationRect: carRect,
            name: "\(id.rawValue) car"
        )
        let defaultPreview = try AppIconRasterRenderer.preview(
            canvasHex: palette.canvas,
            layers: [
                road,
                marks,
                car,
            ],
            name: "\(id.rawValue) preview"
        )
        let darkPreview = try AppIconRasterRenderer.preview(
            canvasHex: darkPalette.canvas,
            layers: [
                darkRoad,
                darkMarks,
                car,
            ],
            name: "\(id.rawValue) Dark preview"
        )
        return packageFiles(
            id: id,
            assetsRoot: assetsRoot,
            catalogRoot: catalogRoot,
            layers: [
                "Road.svg": road,
                "RoadDark.svg": darkRoad,
                "LaneMarks.svg": marks,
                "LaneMarksDark.svg": darkMarks,
                "Car.png": car,
            ],
            defaultPreview: defaultPreview,
            darkPreview: darkPreview
        )
    }

    private static func specialEditionFiles(
        id: AppIconPilotID,
        repositoryRoot: URL,
        assetsRoot: URL,
        catalogRoot: URL,
        conceptPath: String,
        darkConceptPath: String
    ) throws -> [GeneratedFile] {
        let sourceURL = repositoryRoot.appending(path: conceptPath)
        let defaultArtwork = try Data(contentsOf: sourceURL)
        let darkArtwork = try Data(
            contentsOf: repositoryRoot.appending(path: darkConceptPath)
        )
        let defaultPreview = try AppIconRasterRenderer.preview(
            sourceData: defaultArtwork,
            name: "\(id.rawValue) preview"
        )
        let darkPreview = try AppIconRasterRenderer.preview(
            sourceData: darkArtwork,
            name: "\(id.rawValue) Dark preview"
        )
        return packageFiles(
            id: id,
            assetsRoot: assetsRoot,
            catalogRoot: catalogRoot,
            layers: [
                "Default.png": defaultArtwork,
                "Dark.png": darkArtwork,
            ],
            defaultPreview: defaultPreview,
            darkPreview: darkPreview
        )
    }

    private static func darkSourcePath(for id: AppIconPilotID) throws -> String {
        guard let path = id.darkSourceArtworkPath else {
            throw AppIconAssetWorkflowError.imageLoadFailed("Missing Dark artwork for \(id.rawValue)")
        }
        return path
    }

    private static func packageFiles(
        id: AppIconPilotID,
        assetsRoot: URL,
        catalogRoot: URL,
        layers: [String: Data],
        defaultPreview: Data,
        darkPreview: Data
    ) -> [GeneratedFile] {
        let packageAssets = assetsRoot.appending(path: "\(id.rawValue).icon/Assets")
        let layerFiles = layers.map { name, data in
            GeneratedFile(url: packageAssets.appending(path: name), data: data)
        }
        let imageSet = catalogRoot.appending(path: "\(id.previewAssetName).imageset")
        let defaultPreviewFile = "\(id.previewAssetName).png"
        let darkPreviewFile = "\(id.previewAssetName)Dark.png"
        return layerFiles + [
            GeneratedFile(
                url: imageSet.appending(path: defaultPreviewFile),
                data: defaultPreview
            ),
            GeneratedFile(
                url: imageSet.appending(path: darkPreviewFile),
                data: darkPreview
            ),
            GeneratedFile(
                url: imageSet.appending(path: "Contents.json"),
                data: previewContents(
                    defaultFilename: defaultPreviewFile,
                    darkFilename: darkPreviewFile
                )
            ),
        ]
    }

    private static func previewContents(
        defaultFilename: String,
        darkFilename: String
    ) -> Data {
        Data(
            """
            {
              "images" : [
                {
                  "filename" : "\(defaultFilename)",
                  "idiom" : "universal",
                  "scale" : "1x"
                },
                {
                  "appearances" : [
                    {
                      "appearance" : "luminosity",
                      "value" : "dark"
                    }
                  ],
                  "filename" : "\(darkFilename)",
                  "idiom" : "universal",
                  "scale" : "1x"
                }
              ],
              "info" : {
                "author" : "xcode",
                "version" : 1
              }
            }

            """.utf8
        )
    }

    private static func tintedSVG(_ data: Data, hex: String) -> Data {
        guard let source = String(data: data, encoding: .utf8) else { return data }
        return Data(source.replacingOccurrences(of: "#000000", with: hex).utf8)
    }

    private static func obsoletePilotFiles(repositoryRoot: URL) -> [URL] {
        let assetsRoot = repositoryRoot.appending(
            path: "RetroRacing/RetroRacingUniversal/Assets"
        )
        var urls = [
            assetsRoot.appending(path: "RetroRapidPocket.icon/Assets/Default.png"),
            assetsRoot.appending(path: "RetroRapidLCD.icon/Assets/Default.png"),
            assetsRoot.appending(path: "RetroRapidCartridge.icon/Assets/Default.png"),
        ]
        let cartridgeLayers = [
            "ShellMolding.svg", "ShellPinkTrim.svg", "LabelBacking.svg", "LabelInk.png",
            "VentBacking.svg", "VentSlots.svg", "ConnectorRecess.svg", "ConnectorPins.svg",
        ]
        let videoGameLayers = [
            "ShellMolding.svg", "ShellPinkTrim.svg",
            "ScreenBezel.svg", "ScreenBacking.svg", "ScreenContent.png", "ControlTray.svg",
            "ControlsPink.svg", "ControlsNavy.svg",
        ]
        for filename in cartridgeLayers {
            urls.append(
                assetsRoot.appending(
                    path: "RetroRapidGameCartridge.icon/Assets/\(filename)"
                )
            )
        }
        for filename in videoGameLayers {
            urls.append(
                assetsRoot.appending(
                    path: "RetroRapidVideoGame.icon/Assets/\(filename)"
                )
            )
        }
        return urls
    }

    private static func stalePaths(
        repositoryRoot: URL,
        generatedFiles: [GeneratedFile],
        obsoleteFiles: [URL]
    ) -> [String] {
        var stale = FileWork.staleFiles(among: generatedFiles, relativeTo: repositoryRoot)
        stale += obsoleteFiles.compactMap { url in
            FileManager.default.fileExists(atPath: url.path)
                ? FileWork.relativePath(for: url, from: repositoryRoot)
                : nil
        }
        return stale.sorted()
    }
}
