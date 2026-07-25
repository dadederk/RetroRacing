//
//  HelmScreenshotSwapWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

public enum HelmScreenshotSwapWorkflow {
    public static func run(options: HelmScreenshotSwapOptions) throws -> HelmScreenshotSwapSummary {
        try HelmCLI.verifyExists(at: options.helmPath)

        let versionID: String
        if let explicitVersionID = options.versionID {
            versionID = explicitVersionID
        } else {
            versionID = try HelmScreenshotVersionResolver.resolveVersionID(
                helmPath: options.helmPath,
                appID: options.appID,
                versionString: options.versionString,
                ascPlatformCode: options.ascPlatformCode
            )
        }

        print(
            "Helm screenshot swap: version \(options.versionString) (\(versionID)), "
                + "platform \(options.platform.rawValue), "
                + "positions \(options.firstPosition) ↔ \(options.secondPosition)"
        )

        let downloadArguments = downloadArguments(
            versionID: versionID,
            locales: options.locales
        )
        let downloadOutput = try HelmCLI.run(
            helmPath: options.helmPath,
            arguments: downloadArguments
        )
        let downloadResponse = try decodeDownloadResponse(downloadOutput)
        let rootURL = URL(fileURLWithPath: downloadResponse.rootPath, isDirectory: true)

        try verifyHelmDirectoryAccess(at: rootURL)

        let swapResult = try swapSelectedDeviceTypes(
            rootURL: rootURL,
            options: options
        )

        if options.checkOnly {
            print(
                "Check passed: \(swapResult.deviceSwaps) device set(s) across "
                    + "\(swapResult.localesTouched) locale(s) can swap positions "
                    + "\(options.firstPosition) and \(options.secondPosition)."
            )
            return HelmScreenshotSwapSummary(
                rootPath: downloadResponse.rootPath,
                localesTouched: swapResult.localesTouched,
                deviceSwaps: swapResult.deviceSwaps,
                stagingPath: nil
            )
        }

        if swapResult.deviceSwaps == 0 {
            throw MetadataToolError.helmFailed(
                "No matching \(options.platform.rawValue) screenshot sets were found to swap."
            )
        }

        let stagingURL = try stageDeviceTypes(
            from: rootURL,
            deviceTypes: options.platform.deviceTypes,
            locales: localeDirectories(in: rootURL, filter: options.locales),
            helmPath: options.helmPath,
            versionID: versionID
        )

        let uploadArguments = [
            "version", versionID, "screenshots", "upload",
            "--path", stagingURL.path,
            "--replace",
        ] + (options.dryRun ? ["--dry-run"] : []) + ["--agent"]

        let uploadOutput = try HelmCLI.run(
            helmPath: options.helmPath,
            arguments: uploadArguments
        )
        print(uploadOutput)

        if options.dryRun {
            print("Dry run complete. Re-run without --dry-run to upload swapped screenshots.")
        } else {
            print(
                "Uploaded swapped screenshots for \(swapResult.localesTouched) locale(s) "
                    + "(\(swapResult.deviceSwaps) device set(s))."
            )
        }

        return HelmScreenshotSwapSummary(
            rootPath: downloadResponse.rootPath,
            localesTouched: swapResult.localesTouched,
            deviceSwaps: swapResult.deviceSwaps,
            stagingPath: stagingURL.path
        )
    }

    private struct DeviceSwapResult {
        let localesTouched: Int
        let deviceSwaps: Int
    }

    private static func downloadArguments(
        versionID: String,
        locales: [String]
    ) -> [String] {
        var arguments = ["version", versionID, "screenshots", "download", "--agent"]
        for locale in locales {
            arguments.append(contentsOf: ["--locale", locale])
        }
        return arguments
    }

    private static func decodeDownloadResponse(_ output: String) throws -> HelmScreenshotDownloadResponse {
        guard let data = output.data(using: .utf8) else {
            throw MetadataToolError.helmFailed("Helm screenshot download output was not UTF-8.")
        }
        let response = try JSONDecoder().decode(HelmScreenshotDownloadResponse.self, from: data)
        guard response.status == nil || response.status == "ok" else {
            throw MetadataToolError.helmFailed("Helm screenshot download failed.")
        }
        return response
    }

    private static func verifyHelmDirectoryAccess(at rootURL: URL) throws {
        do {
            _ = try FileManager.default.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: nil
            )
        } catch {
            throw MetadataToolError.helmFailed(
                """
                Cannot access Helm screenshot artifacts at \(rootURL.path).
                Run this command from Terminal.app (not Cursor's sandboxed agent shell), \
                or grant Helm CLI folder access in the Helm app.
                Underlying error: \(error.localizedDescription)
                """
            )
        }
    }

    private static func localeDirectories(
        in rootURL: URL,
        filter locales: [String]
    ) throws -> [URL] {
        let directories = try FileManager.default.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        ).filter { url in
            var isDirectory = ObjCBool(false)
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                && isDirectory.boolValue
        }

        guard locales.isEmpty == false else {
            return directories.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }

        let requested = Set(locales)
        let matches = directories.filter { requested.contains($0.lastPathComponent) }
        let missing = requested.subtracting(matches.map(\.lastPathComponent)).sorted()
        guard missing.isEmpty else {
            throw MetadataToolError.helmFailed(
                "Download did not include requested locale(s): \(missing.joined(separator: ", "))."
            )
        }
        return matches.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func swapSelectedDeviceTypes(
        rootURL: URL,
        options: HelmScreenshotSwapOptions
    ) throws -> DeviceSwapResult {
        let fileManager = FileManager.default
        let localeDirs = try localeDirectories(in: rootURL, filter: options.locales)
        var localesTouched = Set<String>()
        var deviceSwaps = 0

        for localeDir in localeDirs {
            for deviceType in options.platform.deviceTypes.sorted() {
                let deviceDir = localeDir.appendingPathComponent(deviceType, isDirectory: true)
                var isDirectory = ObjCBool(false)
                guard fileManager.fileExists(atPath: deviceDir.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

                let firstFile = try HelmScreenshotFileLocator.file(
                    in: deviceDir,
                    position: options.firstPosition
                )
                let secondFile = try HelmScreenshotFileLocator.file(
                    in: deviceDir,
                    position: options.secondPosition
                )

                if options.checkOnly {
                    print(
                        "OK \(localeDir.lastPathComponent)/\(deviceType): "
                            + "\(firstFile.lastPathComponent) ↔ \(secondFile.lastPathComponent)"
                    )
                } else {
                    try HelmScreenshotFileLocator.swapFiles(
                        at: firstFile,
                        and: secondFile,
                        fileManager: fileManager
                    )
                    print(
                        "Swapped \(localeDir.lastPathComponent)/\(deviceType): "
                            + "positions \(options.firstPosition) ↔ \(options.secondPosition)"
                    )
                }

                localesTouched.insert(localeDir.lastPathComponent)
                deviceSwaps += 1
            }
        }

        return DeviceSwapResult(
            localesTouched: localesTouched.count,
            deviceSwaps: deviceSwaps
        )
    }

    private static func stageDeviceTypes(
        from rootURL: URL,
        deviceTypes: Set<String>,
        locales: [URL],
        helmPath: String,
        versionID: String
    ) throws -> URL {
        let paths = try HelmCLI.paths(helmPath: helmPath)
        let stagingRoot = URL(fileURLWithPath: paths.uploadsInbox, isDirectory: true)
            .appendingPathComponent("screenshot-swap-\(versionID.prefix(8))", isDirectory: true)

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: stagingRoot.path) {
            try fileManager.removeItem(at: stagingRoot)
        }
        try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)

        for localeDir in locales {
            for deviceType in deviceTypes.sorted() {
                let source = localeDir.appendingPathComponent(deviceType, isDirectory: true)
                var isDirectory = ObjCBool(false)
                guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }
                let destination = stagingRoot
                    .appendingPathComponent(localeDir.lastPathComponent, isDirectory: true)
                    .appendingPathComponent(deviceType, isDirectory: true)
                try fileManager.createDirectory(
                    at: destination.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try fileManager.copyItem(at: source, to: destination)
            }
        }

        return stagingRoot
    }
}
