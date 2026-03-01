//
//  ContrastColorResolver.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import SpriteKit

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum ContrastColorResolver {
    static func minimumDarkerColor(
        against roadColor: SKColor,
        minimumContrast: Double
    ) -> SKColor {
        guard let base = rgbComponents(from: roadColor) else {
            return .black
        }

        for step in stride(from: 1_000, through: 0, by: -1) {
            let factor = Double(step) / 1_000.0
            let candidate = (
                red: base.red * factor,
                green: base.green * factor,
                blue: base.blue * factor
            )
            if contrastRatio(between: base, and: candidate) >= minimumContrast {
                return SKColor(
                    red: candidate.red,
                    green: candidate.green,
                    blue: candidate.blue,
                    alpha: 1
                )
            }
        }

        return .black
    }

    static func contrastRatio(
        between first: SKColor,
        and second: SKColor
    ) -> Double {
        guard let firstRGB = rgbComponents(from: first),
              let secondRGB = rgbComponents(from: second) else {
            return 1
        }
        return contrastRatio(between: firstRGB, and: secondRGB)
    }

    private static func contrastRatio(
        between first: (red: Double, green: Double, blue: Double),
        and second: (red: Double, green: Double, blue: Double)
    ) -> Double {
        let luminanceA = relativeLuminance(first)
        let luminanceB = relativeLuminance(second)
        let lighter = max(luminanceA, luminanceB)
        let darker = min(luminanceA, luminanceB)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private static func relativeLuminance(_ rgb: (red: Double, green: Double, blue: Double)) -> Double {
        let linearRed = linearizedComponent(rgb.red)
        let linearGreen = linearizedComponent(rgb.green)
        let linearBlue = linearizedComponent(rgb.blue)
        return (0.2126 * linearRed) + (0.7152 * linearGreen) + (0.0722 * linearBlue)
    }

    private static func linearizedComponent(_ component: Double) -> Double {
        if component <= 0.04045 {
            return component / 12.92
        }
        return pow((component + 0.055) / 1.055, 2.4)
    }

    private static func rgbComponents(from color: SKColor) -> (red: Double, green: Double, blue: Double)? {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (Double(red), Double(green), Double(blue))
        }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let convertedColor = UIColor(cgColor: color.cgColor).cgColor.converted(
            to: colorSpace,
            intent: .defaultIntent,
            options: nil
        ),
        let components = convertedColor.components,
        components.count >= 3 else {
            return nil
        }
        return (Double(components[0]), Double(components[1]), Double(components[2]))
        #elseif canImport(AppKit)
        guard let sRGBColor = color.usingColorSpace(.sRGB) else {
            return nil
        }
        return (
            Double(sRGBColor.redComponent),
            Double(sRGBColor.greenComponent),
            Double(sRGBColor.blueComponent)
        )
        #else
        return nil
        #endif
    }
}
