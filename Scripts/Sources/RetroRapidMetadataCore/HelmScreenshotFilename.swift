//
//  HelmScreenshotFilename.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

public enum HelmScreenshotFilename {
    /// Returns the 1-based screenshot position encoded in a Helm download filename.
    public static func position(in filename: String) -> Int? {
        if let prefixed = leadingIndexPosition(in: filename) {
            return prefixed
        }
        return embeddedPosition(in: filename)
    }

    public static func matches(position screenshotPosition: Int, filename: String) -> Bool {
        position(in: filename) == screenshotPosition
    }

    private static func leadingIndexPosition(in filename: String) -> Int? {
        guard filename.count >= 3 else { return nil }
        let prefix = filename.prefix(3)
        guard prefix.dropFirst(2).first == "_",
              let tens = prefix.first?.wholeNumberValue,
              let ones = prefix.dropFirst().first?.wholeNumberValue else {
            return nil
        }
        let value = (tens * 10) + ones
        return value > 0 ? value : nil
    }

    private static func embeddedPosition(in filename: String) -> Int? {
        let pattern = #"_(\d{2})\.[^./\\]+$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(filename.startIndex..<filename.endIndex, in: filename)
        guard let match = regex.firstMatch(in: filename, range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: filename) else {
            return nil
        }
        return Int(filename[captureRange])
    }
}

public enum HelmScreenshotFileLocator {
    public static func file(
        in directory: URL,
        position: Int,
        fileManager: FileManager = .default
    ) throws -> URL {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            throw MetadataToolError.helmFailed(
                "Could not read screenshot directory: \(directory.path)"
            )
        }

        let matches = contents.filter {
            $0.hasDirectoryPath == false
                && HelmScreenshotFilename.matches(
                    position: position,
                    filename: $0.lastPathComponent
                )
        }

        switch matches.count {
        case 1:
            return matches[0]
        case 0:
            throw MetadataToolError.helmFailed(
                "Missing screenshot at position \(position) in \(directory.path)"
            )
        default:
            throw MetadataToolError.helmFailed(
                "Multiple screenshots match position \(position) in \(directory.path): "
                    + matches.map(\.lastPathComponent).joined(separator: ", ")
            )
        }
    }

    public static func swapFiles(
        at firstURL: URL,
        and secondURL: URL,
        fileManager: FileManager = .default
    ) throws {
        let temporary = firstURL.deletingLastPathComponent()
            .appendingPathComponent("\(UUID().uuidString).swap_tmp")
        try fileManager.moveItem(at: firstURL, to: temporary)
        try fileManager.moveItem(at: secondURL, to: firstURL)
        try fileManager.moveItem(at: temporary, to: secondURL)
    }
}
