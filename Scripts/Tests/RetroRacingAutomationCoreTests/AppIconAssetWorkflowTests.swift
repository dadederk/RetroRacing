//
//  AppIconAssetWorkflowTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 14/08/2026.
//

import Foundation
import ImageIO
import Testing

@testable import RetroRacingAutomationCore
import ScriptSupport

@Test
func givenPilotCatalogWhenResolvingSourcesThenNamesAndCanonicalInputsStayStable() throws {
    let root = try appIconRepositoryRoot()

    #expect(AppIconPilotID.allCases.map(\.rawValue) == [
        "RetroRapidPocket",
        "RetroRapidLCD",
        "RetroRapidCartridge",
        "RetroRapidCRT",
        "RetroRapidGameCartridge",
        "RetroRapidVideoGame",
    ])
    #expect(AppIconPilotID.pocket.sourceArtworkPath.contains("playersCar-GameBoy-ipad.png"))
    #expect(AppIconPilotID.lcd.sourceArtworkPath.contains("playersCar-LCD-ipad.png"))
    #expect(AppIconPilotID.cartridge.sourceArtworkPath.contains("playersCar-8Bit-ipad.png"))
    #expect(AppIconPilotID.crt.sourceArtworkPath.contains("playersCar-16Bit-ipad.png"))
    #expect(AppIconPilotID.retroCartridge.sourceArtworkPath.hasSuffix("retro-cartridge-v4.png"))
    #expect(AppIconPilotID.retroVideoGame.sourceArtworkPath.hasSuffix("retro-video-game-v4.png"))
    #expect(AppIconPilotID.pocket.darkSourceArtworkPath == nil)
    #expect(AppIconPilotID.lcd.darkSourceArtworkPath == nil)
    #expect(AppIconPilotID.cartridge.darkSourceArtworkPath == nil)
    #expect(AppIconPilotID.crt.darkSourceArtworkPath == nil)
    #expect(
        AppIconPilotID.retroCartridge.darkSourceArtworkPath?
            .hasSuffix("retro-cartridge-dark-v5.png") == true
    )
    #expect(
        AppIconPilotID.retroVideoGame.darkSourceArtworkPath?
            .hasSuffix("retro-video-game-dark-v5.png") == true
    )
    for iconID in AppIconPilotID.allCases {
        #expect(FileManager.default.fileExists(atPath: root.appending(path: iconID.sourceArtworkPath).path))
        if let darkSourceArtworkPath = iconID.darkSourceArtworkPath {
            #expect(
                FileManager.default.fileExists(
                    atPath: root.appending(path: darkSourceArtworkPath).path
                )
            )
        }
    }
}

@Test
func givenThemeGeometryWhenGeneratingThenRoadAndDashesShareAConvergingCanvas() throws {
    for geometry in [AppIconRoadGeometry.pocket, .lcd, .cartridge, .crt] {
        let road = try #require(
            String(data: AppIconSVGRenderer.road(geometry: geometry), encoding: .utf8)
        )
        let laneMarks = try #require(
            String(data: AppIconSVGRenderer.laneMarks(geometry: geometry), encoding: .utf8)
        )

        for source in [road, laneMarks] {
            #expect(source.contains("width=\"1024\""))
            #expect(source.contains("height=\"1024\""))
            #expect(source.contains("viewBox=\"0 0 1024 1024\""))
        }
        #expect(laneMarks.contains(",0.000"))
        #expect(laneMarks.contains(",1024.000"))
        for topX in geometry.boundaryTopXs {
            let bottomX = geometry.projectedX(topX: topX, y: 1024)
            let topRatio = (topX - geometry.vanishingPointX) / -geometry.vanishingPointY
            let bottomRatio = (bottomX - geometry.vanishingPointX)
                / (1024 - geometry.vanishingPointY)
            #expect(abs(topRatio - bottomRatio) < 0.000_001)
        }
    }

    let pocketMarks = try #require(
        String(data: AppIconSVGRenderer.laneMarks(geometry: .pocket), encoding: .utf8)
    )
    let lcdMarks = try #require(
        String(data: AppIconSVGRenderer.laneMarks(geometry: .lcd), encoding: .utf8)
    )
    let cartridgeMarks = try #require(
        String(data: AppIconSVGRenderer.laneMarks(geometry: .cartridge), encoding: .utf8)
    )
    let crtMarks = try #require(
        String(data: AppIconSVGRenderer.laneMarks(geometry: .crt), encoding: .utf8)
    )
    #expect(pocketMarks.components(separatedBy: "<polygon ").count - 1 == 27)
    #expect(lcdMarks.components(separatedBy: "<polygon ").count - 1 == 36)
    #expect(cartridgeMarks.components(separatedBy: "<polygon ").count - 1 == 36)
    #expect(crtMarks.components(separatedBy: "<polygon ").count - 1 == 36)
    #expect(AppIconRoadGeometry.pocket.projectedX(topX: 435, y: 1024) < 0)
    #expect(AppIconRoadGeometry.lcd.projectedX(topX: 674, y: 1024) > 1024)
    let crt = AppIconRoadGeometry.crt
    #expect(
        crt.projectedX(topX: crt.boundaryTopXs[0], y: 320)
            > crt.projectedX(topX: crt.roadTopLeftX, y: 320)
    )
    #expect(
        crt.projectedX(topX: crt.boundaryTopXs[3], y: 320)
            < crt.projectedX(topX: crt.roadTopRightX, y: 320)
    )
}

@Test
func givenCRTOverlayWhenGeneratingAppearancesThenDarkRetainsAnEdgeFocusedDisplayEffect() throws {
    let defaultOverlay = try #require(
        String(data: AppIconSVGRenderer.crtOverlay(dark: false), encoding: .utf8)
    )
    let darkOverlay = try #require(
        String(data: AppIconSVGRenderer.crtOverlay(dark: true), encoding: .utf8)
    )

    #expect(defaultOverlay.contains("viewBox=\"0 0 1024 1024\""))
    #expect(defaultOverlay.contains("fill-opacity=\"0.18\""))
    #expect(defaultOverlay.contains("stop-opacity=\"0.26\""))
    #expect(darkOverlay.contains("fill-opacity=\"0.14\""))
    #expect(darkOverlay.contains("offset=\"58%\""))
    #expect(darkOverlay.contains("stop-opacity=\"0.30\""))
    #expect(defaultOverlay != darkOverlay)
}

@Test
func givenGeneratedPilotAssetsWhenRenderingTwiceThenOutputsAreDeterministic() throws {
    let root = try appIconRepositoryRoot()
    let first = try AppIconAssetWorkflow.generatedFiles(repositoryRoot: root)
    let second = try AppIconAssetWorkflow.generatedFiles(repositoryRoot: root)
    let firstByPath = Dictionary(uniqueKeysWithValues: first.map { ($0.url.path, $0.data) })
    let secondByPath = Dictionary(uniqueKeysWithValues: second.map { ($0.url.path, $0.data) })

    #expect(first.count == 44)
    #expect(firstByPath == secondByPath)
    #expect(try AppIconAssetWorkflow.stalePaths(repositoryRoot: root).isEmpty)

    for file in first where file.url.pathExtension == "png" {
        let expectedDimensions = file.url.path.contains("Assets.xcassets")
            ? (512, 512)
            : (1024, 1024)
        let dimensions = try #require(imageDimensions(data: file.data))
        #expect(dimensions == expectedDimensions)
    }
}

@Test(arguments: [AppIconPilotID.retroCartridge, .retroVideoGame])
func givenSpecialEditionGenerationWhenRenderingThenApprovedDefaultAndDarkArtworkAreCopied(
    iconID: AppIconPilotID
) throws {
    let root = try appIconRepositoryRoot()
    let files = try AppIconAssetWorkflow.generatedFiles(repositoryRoot: root)

    let packagePath = "\(iconID.rawValue).icon/Assets/"
    let defaultFile = try #require(files.first {
        $0.url.path.contains(packagePath) && $0.url.lastPathComponent == "Default.png"
    })
    let darkFile = try #require(files.first {
        $0.url.path.contains(packagePath) && $0.url.lastPathComponent == "Dark.png"
    })
    let approvedV4 = try Data(contentsOf: root.appending(path: iconID.sourceArtworkPath))
    let darkSourcePath = try #require(iconID.darkSourceArtworkPath)
    let approvedDarkV5 = try Data(contentsOf: root.appending(path: darkSourcePath))

    #expect(defaultFile.data == approvedV4)
    #expect(darkFile.data == approvedDarkV5)
    #expect(darkFile.data != defaultFile.data)
    let darkDimensions = try #require(imageDimensions(data: darkFile.data))
    #expect(darkDimensions == (1024, 1024))

    let plasticPoints: [(Int, Int)] = switch iconID {
    case .retroCartridge:
        [(32, 32), (100, 512), (512, 265), (900, 512)]
    case .retroVideoGame:
        [(32, 32), (512, 80), (100, 512), (512, 720), (900, 512)]
    case .pocket, .lcd, .cartridge, .crt:
        []
    }
    for point in plasticPoints {
        let defaultPlastic = try #require(
            imagePixel(data: defaultFile.data, x: point.0, y: point.1)
        )
        let darkPlastic = try #require(
            imagePixel(data: darkFile.data, x: point.0, y: point.1)
        )
        #expect(darkPlastic != defaultPlastic, "Expected plastic at \(point) to change")
        #expect(
            darkPlastic.channelSpread <= 8,
            "Expected plastic at \(point) to become neutral grey"
        )
        #expect(
            darkPlastic.luminance < defaultPlastic.luminance,
            "Expected plastic at \(point) to darken"
        )
    }
}

@Test(arguments: AppIconPilotID.allCases)
func givenGeneratedPilotPreviewWhenParsingThenDefaultAndDarkAppearancesStayAdaptive(
    iconID: AppIconPilotID
) throws {
    let root = try appIconRepositoryRoot()
    let files = try AppIconAssetWorkflow.generatedFiles(repositoryRoot: root)
    let previewPath = "\(iconID.previewAssetName).imageset/"
    let defaultFilename = "\(iconID.previewAssetName).png"
    let darkFilename = "\(iconID.previewAssetName)Dark.png"
    let defaultFile = try #require(files.first {
        $0.url.path.contains(previewPath) && $0.url.lastPathComponent == defaultFilename
    })
    let darkFile = try #require(files.first {
        $0.url.path.contains(previewPath) && $0.url.lastPathComponent == darkFilename
    })
    let contentsFile = try #require(files.first {
        $0.url.path.contains(previewPath) && $0.url.lastPathComponent == "Contents.json"
    })
    let contents = try #require(
        JSONSerialization.jsonObject(with: contentsFile.data) as? [String: Any]
    )
    let images = try #require(contents["images"] as? [[String: Any]])

    #expect(defaultFile.data != darkFile.data)
    #expect(images.count == 2)
    let defaultEntry = try #require(images.first { $0["filename"] as? String == defaultFilename })
    let darkEntry = try #require(images.first { $0["filename"] as? String == darkFilename })
    #expect(defaultEntry["appearances"] == nil)
    let darkAppearances = try #require(darkEntry["appearances"] as? [[String: Any]])
    #expect(darkAppearances.contains { appearance in
        appearance["appearance"] as? String == "luminosity"
            && appearance["value"] as? String == "dark"
    })
    for entry in [defaultEntry, darkEntry] {
        #expect(entry["idiom"] as? String == "universal")
        #expect(entry["scale"] as? String == "1x")
    }
}

@Test(arguments: [AppIconPilotID.pocket, .lcd, .cartridge])
func givenLayeredThemeIconComposerManifestWhenParsingThenAppearanceContractsArePresent(
    iconID: AppIconPilotID
) throws {
    let manifest = try pilotManifest(iconID: iconID)
    let groups = try #require(manifest["groups"] as? [[String: Any]])
    let appearances = appearanceNames(in: manifest)

    #expect(groups.count == 2)
    expectDocumentFillAppearances(manifest: manifest)
    #expect(appearances.contains("dark"))
    #expect(appearances.contains("tinted"))
    #expect(groups[0]["name"] as? String == "Subject")
    #expect(groups[1]["name"] as? String == "World")
    let subjectLayers = try #require(groups[0]["layers"] as? [[String: Any]])
    let worldLayers = try #require(groups[1]["layers"] as? [[String: Any]])
    #expect(subjectLayers.compactMap { defaultImageName(in: $0) } == [
        "Car.png",
        "LaneMarks.svg",
    ])
    #expect(worldLayers.compactMap { defaultImageName(in: $0) } == [
        "Road.svg",
    ])
    #expect(containsLegacySpecializationSlot(in: manifest) == false)
    expectAppearanceImageSources(
        layer: subjectLayers[1],
        defaultImageName: "LaneMarks.svg",
        darkImageName: "LaneMarksDark.svg"
    )
    expectAppearanceImageSources(
        layer: worldLayers[0],
        defaultImageName: "Road.svg",
        darkImageName: "RoadDark.svg"
    )
    #expect((subjectLayers[0]["opacity"] as? NSNumber)?.doubleValue == 1)
    expectAppearanceOpacities(layer: subjectLayers[1], mono: 0.75)
    expectAppearanceOpacities(layer: worldLayers[0], mono: 0.45)
}

@Test
func givenCRTIconComposerManifestWhenParsingThenFrontmostEffectAndAppearancesArePresent() throws {
    let manifest = try pilotManifest(iconID: .crt)
    let groups = try #require(manifest["groups"] as? [[String: Any]])

    #expect(groups.count == 3)
    expectDocumentFillAppearances(manifest: manifest)
    #expect(groups[0]["name"] as? String == "Accents")
    #expect(groups[1]["name"] as? String == "Subject")
    #expect(groups[2]["name"] as? String == "World")
    let accentLayers = try #require(groups[0]["layers"] as? [[String: Any]])
    let subjectLayers = try #require(groups[1]["layers"] as? [[String: Any]])
    let worldLayers = try #require(groups[2]["layers"] as? [[String: Any]])
    #expect(accentLayers.compactMap { defaultImageName(in: $0) } == ["CRTOverlay.svg"])
    #expect(subjectLayers.compactMap { defaultImageName(in: $0) } == [
        "Car.png",
        "LaneMarks.svg",
    ])
    #expect(worldLayers.compactMap { defaultImageName(in: $0) } == ["Road.svg"])
    expectAppearanceImageSources(
        layer: accentLayers[0],
        defaultImageName: "CRTOverlay.svg",
        darkImageName: "CRTOverlayDark.svg"
    )
    expectAppearanceImageSources(
        layer: subjectLayers[1],
        defaultImageName: "LaneMarks.svg",
        darkImageName: "LaneMarksDark.svg"
    )
    expectAppearanceImageSources(
        layer: worldLayers[0],
        defaultImageName: "Road.svg",
        darkImageName: "RoadDark.svg"
    )
    #expect((subjectLayers[0]["opacity"] as? NSNumber)?.doubleValue == 1)
    expectAppearanceOpacities(layer: accentLayers[0], mono: 0.60)
    expectAppearanceOpacities(layer: subjectLayers[1], mono: 0.75)
    expectAppearanceOpacities(layer: worldLayers[0], mono: 0.45)
    #expect(containsLegacySpecializationSlot(in: manifest) == false)
}

@Test(arguments: [AppIconPilotID.retroCartridge, .retroVideoGame])
func givenSpecialEditionIconComposerManifestWhenParsingThenAppearanceContractsArePresent(
    iconID: AppIconPilotID
) throws {
    let manifest = try pilotManifest(iconID: iconID)
    let groups = try #require(manifest["groups"] as? [[String: Any]])
    let appearances = appearanceNames(in: manifest)

    #expect(groups.count == 1)
    expectDocumentFillAppearances(manifest: manifest)
    #expect(appearances.contains("dark"))
    #expect(appearances.contains("tinted"))
    #expect(groups[0]["name"] as? String == "Approved v4 Artwork")
    let layers = try #require(groups[0]["layers"] as? [[String: Any]])
    #expect(layers.compactMap { defaultImageName(in: $0) } == [
        "Default.png",
    ])
    #expect(containsLegacySpecializationSlot(in: manifest) == false)
    expectAppearanceImageSources(
        layer: layers[0],
        defaultImageName: "Default.png",
        darkImageName: "Dark.png"
    )
}

private func pilotManifest(iconID: AppIconPilotID) throws -> [String: Any] {
    let root = try appIconRepositoryRoot()
    let manifestURL = root.appending(
        path: "RetroRacing/RetroRacingUniversal/Assets/\(iconID.rawValue).icon/icon.json"
    )
    let data = try Data(contentsOf: manifestURL)
    let manifest = try #require(
        JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    for filename in iconID.layerFilenames {
        #expect(data.range(of: Data(filename.utf8)) != nil)
    }
    let groups = try #require(manifest["groups"] as? [[String: Any]])
    #expect((1...4).contains(groups.count))
    return manifest
}

private func expectAppearanceImageSources(
    layer: [String: Any],
    defaultImageName: String,
    darkImageName: String
) {
    #expect(imageName(in: layer, appearance: nil) == defaultImageName)
    #expect(imageName(in: layer, appearance: "dark") == darkImageName)
    #expect(imageName(in: layer, appearance: "tinted") == defaultImageName)
}

private func expectDocumentFillAppearances(manifest: [String: Any]) {
    let specializations = manifest["fill-specializations"] as? [[String: Any]] ?? []
    #expect(specializations.contains { $0["appearance"] == nil })
    #expect(specializations.contains { $0["appearance"] as? String == "dark" })
    #expect(specializations.contains { $0["appearance"] as? String == "tinted" })
}

private func expectAppearanceOpacities(layer: [String: Any], mono: Double) {
    let specializations = layer["opacity-specializations"] as? [[String: Any]] ?? []
    #expect(opacity(in: specializations, appearance: nil) == 1)
    #expect(opacity(in: specializations, appearance: "dark") == 1)
    #expect(opacity(in: specializations, appearance: "tinted") == mono)
}

private func opacity(
    in specializations: [[String: Any]],
    appearance: String?
) -> Double? {
    let matching = specializations.first { specialization in
        specialization["appearance"] as? String == appearance
    }
    return (matching?["value"] as? NSNumber)?.doubleValue
}

private func defaultImageName(in layer: [String: Any]) -> String? {
    if let imageName = layer["image-name"] as? String {
        return imageName
    }
    return imageName(in: layer, appearance: nil)
}

private func imageName(in layer: [String: Any], appearance: String?) -> String? {
    let specializations = layer["image-name-specializations"] as? [[String: Any]] ?? []
    let matching = specializations.first { specialization in
        specialization["appearance"] as? String == appearance
    }
    return matching?["value"] as? String
}

private func containsLegacySpecializationSlot(in value: Any) -> Bool {
    if let dictionary = value as? [String: Any] {
        if dictionary["slot"] != nil { return true }
        return dictionary.values.contains(where: containsLegacySpecializationSlot(in:))
    }
    if let array = value as? [Any] {
        return array.contains(where: containsLegacySpecializationSlot(in:))
    }
    return false
}

private func appIconRepositoryRoot() throws -> URL {
    try RepositoryLocator.locate(containing: [
        "RetroRacing/RetroRacingUniversal/Assets/RetroRapidPocket.icon/icon.json",
        "Plans/assets/alternate-app-icon-concepts/retro-cartridge-v4.png",
    ])
}

private func imageDimensions(data: Data) -> (Int, Int)? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int
    else { return nil }
    return (width, height)
}

private struct ImagePixel: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var channelSpread: UInt8 {
        let maximum = max(red, max(green, blue))
        let minimum = min(red, min(green, blue))
        return maximum - minimum
    }

    var luminance: Double {
        (Double(red) * 0.2126) + (Double(green) * 0.7152) + (Double(blue) * 0.0722)
    }
}

private func imagePixel(data: Data, x: Int, y: Int) -> ImagePixel? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
          (0..<image.width).contains(x),
          (0..<image.height).contains(y),
          let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
    else { return nil }
    var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
    guard let context = CGContext(
        data: &pixels,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: image.width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else { return nil }
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    let offset = ((y * image.width) + x) * 4
    return ImagePixel(
        red: pixels[offset],
        green: pixels[offset + 1],
        blue: pixels[offset + 2]
    )
}

private func appearanceNames(in value: Any) -> Set<String> {
    if let dictionary = value as? [String: Any] {
        var names = Set<String>()
        if let appearance = dictionary["appearance"] as? String {
            names.insert(appearance)
        }
        for child in dictionary.values {
            names.formUnion(appearanceNames(in: child))
        }
        return names
    }
    if let array = value as? [Any] {
        return array.reduce(into: Set<String>()) { result, child in
            result.formUnion(appearanceNames(in: child))
        }
    }
    return []
}
