//
//  ShareImageSnapshotService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 04/04/2026.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

#if !os(watchOS)
@MainActor
enum ShareImageSnapshotService {
    static func renderToTemporaryPNGURL<Content: View>(
        fileName: String,
        colorScheme: ColorScheme,
        @ViewBuilder content: () -> Content
    ) -> URL? {
        let rendererContent = content().environment(\.colorScheme, colorScheme)
        let renderer = ImageRenderer(content: rendererContent)
        renderer.scale = 3

        guard let pngData = renderedPNGData(from: renderer) else {
            return nil
        }

        do {
            let shareURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try pngData.write(to: shareURL, options: .atomic)
            return shareURL
        } catch {
            return nil
        }
    }

    private static func renderedPNGData<Content: View>(from renderer: ImageRenderer<Content>) -> Data? {
        #if os(iOS) || os(tvOS) || os(visionOS)
        return renderer.uiImage?.pngData()
        #elseif os(macOS)
        guard let tiffData = renderer.nsImage?.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}
#endif
