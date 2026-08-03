//
//  TestColorAssertions.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 03/08/2026.
//

import SpriteKit
import XCTest
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

func assertColor(
    _ color: SKColor,
    equals expected: SKColor,
    accuracy: CGFloat = 0.001,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    guard let actualRGB = rgbComponents(from: color),
          let expectedRGB = rgbComponents(from: expected) else {
        XCTFail("Expected RGB-compatible colors", file: file, line: line)
        return
    }

    XCTAssertEqual(actualRGB.red, expectedRGB.red, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actualRGB.green, expectedRGB.green, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actualRGB.blue, expectedRGB.blue, accuracy: accuracy, file: file, line: line)
}

func rgbComponents(from color: SKColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
    #if canImport(UIKit)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
        return (red, green, blue)
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
    return (components[0], components[1], components[2])
    #elseif canImport(AppKit)
    guard let sRGBColor = color.usingColorSpace(.sRGB) else { return nil }
    return (sRGBColor.redComponent, sRGBColor.greenComponent, sRGBColor.blueComponent)
    #else
    return nil
    #endif
}
