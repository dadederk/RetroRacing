//
//  AppIconSVGRenderer.swift
//  RetroRacing
//
//  Created by Dani Devesa on 14/08/2026.
//

import Foundation

struct AppIconRoadGeometry: Sendable {
    let vanishingPointX: Double
    let vanishingPointY: Double
    let roadTopLeftX: Double
    let roadTopRightX: Double
    let boundaryTopXs: [Double]

    static let pocket = AppIconRoadGeometry(
        vanishingPointX: 512,
        vanishingPointY: -180,
        roadTopLeftX: 414,
        roadTopRightX: 610,
        boundaryTopXs: [435, 512, 589]
    )

    static let lcd = AppIconRoadGeometry(
        vanishingPointX: 512,
        vanishingPointY: -430,
        roadTopLeftX: 300,
        roadTopRightX: 724,
        boundaryTopXs: [350, 458, 566, 674]
    )

    static let cartridge = AppIconRoadGeometry(
        vanishingPointX: 512,
        vanishingPointY: -430,
        roadTopLeftX: 244,
        roadTopRightX: 780,
        boundaryTopXs: [350, 458, 566, 674]
    )

    static let crt = AppIconRoadGeometry(
        vanishingPointX: 512,
        vanishingPointY: -300,
        roadTopLeftX: 306,
        roadTopRightX: 718,
        boundaryTopXs: [318, 425, 581, 706]
    )

    func projectedX(topX: Double, y: Double) -> Double {
        let scale = (y - vanishingPointY) / -vanishingPointY
        return vanishingPointX + ((topX - vanishingPointX) * scale)
    }
}

enum AppIconSVGRenderer {
    static func road(geometry: AppIconRoadGeometry) -> Data {
        let bottomLeft = geometry.projectedX(topX: geometry.roadTopLeftX, y: 1024)
        let bottomRight = geometry.projectedX(topX: geometry.roadTopRightX, y: 1024)
        return svg(body: """
        <polygon points="\(format(geometry.roadTopLeftX)),0 \(format(geometry.roadTopRightX)),0 \(format(bottomRight)),1024 \(format(bottomLeft)),1024" fill="#000000"/>
        """)
    }

    static func laneMarks(geometry: AppIconRoadGeometry) -> Data {
        let polygons = geometry.boundaryTopXs.flatMap { topX in
            perspectiveDashes(topX: topX, geometry: geometry)
        }
        return svg(body: polygons.joined(separator: "\n"))
    }

    static func crtOverlay(dark: Bool) -> Data {
        let scanlineOpacity = dark ? "0.14" : "0.18"
        let highlightOpacity = dark ? "0.012" : "0.022"
        let vignetteOpacity = dark ? "0.30" : "0.26"
        let vignetteStart = dark ? "58%" : "54%"
        return svg(body: """
        <defs>
          <pattern id="scanlines" width="12" height="12" patternUnits="userSpaceOnUse">
            <rect x="0" y="0" width="12" height="3" fill="#000000" fill-opacity="\(scanlineOpacity)"/>
            <rect x="0" y="3" width="12" height="1" fill="#B8FFC4" fill-opacity="\(highlightOpacity)"/>
          </pattern>
          <radialGradient id="vignette" cx="50%" cy="48%" r="72%">
            <stop offset="\(vignetteStart)" stop-color="#000000" stop-opacity="0"/>
            <stop offset="100%" stop-color="#000000" stop-opacity="\(vignetteOpacity)"/>
          </radialGradient>
        </defs>
        <rect x="0" y="0" width="1024" height="1024" fill="url(#scanlines)"/>
        <rect x="0" y="0" width="1024" height="1024" fill="url(#vignette)"/>
        """)
    }

    private static func perspectiveDashes(
        topX: Double,
        geometry: AppIconRoadGeometry
    ) -> [String] {
        dashRanges.map { startY, endY in
            let startWidth = dashWidth(at: startY)
            let endWidth = dashWidth(at: endY)
            let startX = geometry.projectedX(topX: topX, y: startY)
            let endX = geometry.projectedX(topX: topX, y: endY)
            return "<polygon points=\"\(format(startX - startWidth / 2)),\(format(startY)) \(format(startX + startWidth / 2)),\(format(startY)) \(format(endX + endWidth / 2)),\(format(endY)) \(format(endX - endWidth / 2)),\(format(endY))\" fill=\"#000000\"/>"
        }
    }

    private static func dashWidth(at y: Double) -> Double {
        14 + ((y / 1024) * 34)
    }

    private static func svg(body: String) -> Data {
        Data(
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
            \(body)
            </svg>
            """.utf8
        )
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    private static let dashRanges: [(Double, Double)] = [
        (0, 24),
        (43, 72),
        (94, 128),
        (153, 194),
        (226, 279),
        (321, 390),
        (440, 536),
        (600, 736),
        (812, 1024),
    ]
}
