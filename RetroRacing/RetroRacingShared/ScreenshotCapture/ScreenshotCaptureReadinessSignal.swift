//
//  ScreenshotCaptureReadinessSignal.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

public enum ScreenshotCaptureReadinessSignal {
    public static func captureRootAppeared(stagingDirectory: URL?, slideIndex: Int) {
        write(
            stagingDirectory: stagingDirectory,
            slideIndex: slideIndex,
            fileName: captureRootFileName(slideIndex: slideIndex),
            body: "appeared"
        )
    }

    public static func markReady(stagingDirectory: URL?, slideIndex: Int) {
        write(
            stagingDirectory: stagingDirectory,
            slideIndex: slideIndex,
            fileName: readinessFileName(slideIndex: slideIndex),
            body: ScreenshotCaptureIdentifiers.readinessIdentifier(slideIndex: slideIndex)
        )
    }

    public static func readinessFileName(slideIndex: Int) -> String {
        "capture-ready-\(slideIndex).signal"
    }

    public static func captureRootFileName(slideIndex: Int) -> String {
        "capture-root-\(slideIndex).signal"
    }

    public static func readinessFileURL(stagingDirectory: URL?, slideIndex: Int) -> URL {
        signalDirectory(stagingDirectory: stagingDirectory)
            .appending(path: readinessFileName(slideIndex: slideIndex))
    }

    public static func isReady(stagingDirectory: URL?, slideIndex: Int) -> Bool {
        FileManager.default.fileExists(atPath: readinessFileURL(stagingDirectory: stagingDirectory, slideIndex: slideIndex).path)
    }

    private static func signalDirectory(stagingDirectory: URL?) -> URL {
        FileManager.default.temporaryDirectory
    }

    private static func write(stagingDirectory: URL?, slideIndex: Int, fileName: String, body: String) {
        let directory = signalDirectory(stagingDirectory: stagingDirectory)
        do {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            let url = directory.appending(path: fileName)
            try body.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            // Best-effort coordination for UI tests; capture should still proceed via accessibility when available.
        }
    }
}
