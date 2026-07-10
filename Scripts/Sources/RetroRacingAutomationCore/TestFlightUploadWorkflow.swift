//
//  TestFlightUploadWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 10/07/2026.
//

import Foundation
import ScriptSupport

public enum TestFlightUploadCommand: String, CaseIterable, Sendable {
    case archive
    case uploadIOS = "upload-ios"
    case uploadMac = "upload-mac"
    case all
}

public struct TestFlightUploadOptions: Equatable, Sendable {
    public let command: TestFlightUploadCommand
    public let appID: String
    public let version: String
    public let buildNumber: String
    public let helmPath: String
    public let developerDirectory: String
    public let externalGroup: String
    public let pollAttempts: Int
    public let pollIntervalSeconds: TimeInterval
    public let dryRun: Bool

    public init(
        command: TestFlightUploadCommand,
        appID: String,
        version: String,
        buildNumber: String,
        helmPath: String,
        developerDirectory: String,
        externalGroup: String,
        pollAttempts: Int,
        pollIntervalSeconds: TimeInterval,
        dryRun: Bool
    ) {
        self.command = command
        self.appID = appID
        self.version = version
        self.buildNumber = buildNumber
        self.helmPath = helmPath
        self.developerDirectory = developerDirectory
        self.externalGroup = externalGroup
        self.pollAttempts = pollAttempts
        self.pollIntervalSeconds = pollIntervalSeconds
        self.dryRun = dryRun
    }
}

public enum TestFlightUploadWorkflow {
    public static func commands(
        repositoryRoot: URL,
        options: TestFlightUploadOptions
    ) -> [ProcessCommand] {
        let plan = BuildPlan(repositoryRoot: repositoryRoot, options: options)
        switch options.command {
        case .archive:
            return [archiveIOSCommand(plan: plan), archiveMacCommand(plan: plan)]
        case .uploadIOS:
            return [exportArchiveCommand(plan: plan, platform: .iOS)]
        case .uploadMac:
            return [exportArchiveCommand(plan: plan, platform: .macOS)]
        case .all:
            return [
                archiveIOSCommand(plan: plan),
                archiveMacCommand(plan: plan),
                exportArchiveCommand(plan: plan, platform: .iOS),
                exportArchiveCommand(plan: plan, platform: .macOS),
            ]
        }
    }

    public static func run(
        repositoryRoot: URL,
        options: TestFlightUploadOptions
    ) throws {
        let plan = BuildPlan(repositoryRoot: repositoryRoot, options: options)

        switch options.command {
        case .archive:
            try runArchive(plan: plan, platform: .iOS)
            try runArchive(plan: plan, platform: .macOS)
        case .uploadIOS:
            try runUpload(plan: plan, platform: .iOS)
        case .uploadMac:
            try runUpload(plan: plan, platform: .macOS)
        case .all:
            try runArchive(plan: plan, platform: .iOS)
            try runArchive(plan: plan, platform: .macOS)
            try runUpload(plan: plan, platform: .iOS)
            try runUpload(plan: plan, platform: .macOS)
        }

        if options.dryRun {
            print("Dry run complete; archives, uploads, and TestFlight metadata were not changed.")
        }
    }

    public static func buildID(from data: Data) throws -> String? {
        let object = try JSONSerialization.jsonObject(with: data)
        if let dictionary = object as? [String: Any] {
            return dictionary["id"] as? String
        }
        if let array = object as? [[String: Any]] {
            return array.first?["id"] as? String
        }
        return nil
    }

    public static func buildID(from text: String) throws -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try buildID(from: data)
    }

    private static func runArchive(
        plan: BuildPlan,
        platform: ArchivePlatform
    ) throws {
        try FileManager.default.createDirectory(
            at: plan.buildDirectory,
            withIntermediateDirectories: true
        )
        try run(command: archiveCommand(plan: plan, platform: platform), dryRun: plan.options.dryRun)
    }

    private static func runUpload(
        plan: BuildPlan,
        platform: ArchivePlatform
    ) throws {
        try run(command: exportArchiveCommand(plan: plan, platform: platform), dryRun: plan.options.dryRun)
        let buildID = try waitForBuildID(plan: plan, platform: platform)
        try configureTestFlightBuild(buildID: buildID, plan: plan, platform: platform)
    }

    private static func waitForBuildID(
        plan: BuildPlan,
        platform: ArchivePlatform
    ) throws -> String {
        let command = buildLookupCommand(plan: plan, platform: platform)
        if plan.options.dryRun {
            print(command.rendered)
            return "<\(platform.helmName)-build-id>"
        }

        try verifyExecutable(at: plan.options.helmPath, label: "Helm CLI")
        for attempt in 1...plan.options.pollAttempts {
            fputs(
                "Polling App Store Connect for \(platform.helmName) build "
                    + "\(plan.options.version) (\(plan.options.buildNumber))... "
                    + "(\(attempt)/\(plan.options.pollAttempts))\n",
                stderr
            )
            let output = try ProcessRunner.run(command, captureOutput: true)
            if let buildID = try buildID(from: output), !buildID.isEmpty {
                return buildID
            }
            if attempt < plan.options.pollAttempts {
                Thread.sleep(forTimeInterval: plan.options.pollIntervalSeconds)
            }
        }

        throw TestFlightUploadError.buildNotFound(
            platform: platform.helmName,
            version: plan.options.version,
            buildNumber: plan.options.buildNumber
        )
    }

    private static func configureTestFlightBuild(
        buildID: String,
        plan: BuildPlan,
        platform: ArchivePlatform
    ) throws {
        let whatsNew = try String(contentsOf: plan.whatsNewFile, encoding: .utf8)
        let update = buildUpdateCommand(buildID: buildID, whatsNew: whatsNew, plan: plan)
        let attach = buildAttachCommand(buildID: buildID, plan: plan)
        let finalState = buildLookupCommand(plan: plan, platform: platform)

        try run(command: update, dryRun: plan.options.dryRun)
        try run(command: attach, dryRun: plan.options.dryRun)
        try run(command: finalState, dryRun: plan.options.dryRun)
    }

    private static func run(command: ProcessCommand, dryRun: Bool) throws {
        print(command.rendered)
        if !dryRun {
            try ProcessRunner.run(command)
        }
    }

    private static func archiveIOSCommand(plan: BuildPlan) -> ProcessCommand {
        archiveCommand(plan: plan, platform: .iOS)
    }

    private static func archiveMacCommand(plan: BuildPlan) -> ProcessCommand {
        archiveCommand(plan: plan, platform: .macOS)
    }

    private static func archiveCommand(
        plan: BuildPlan,
        platform: ArchivePlatform
    ) -> ProcessCommand {
        ProcessCommand(
            executable: "/usr/bin/xcrun",
            arguments: [
                "xcodebuild",
                "archive",
                "-project",
                plan.project.path,
                "-scheme",
                "RetroRacingUniversal",
                "-destination",
                platform.destination,
                "-archivePath",
                plan.archivePath(for: platform).path,
                "CODE_SIGN_STYLE=Automatic",
                "DEVELOPMENT_TEAM=PV9S9FTZF2",
                "-allowProvisioningUpdates",
            ],
            environment: ["DEVELOPER_DIR": plan.options.developerDirectory]
        )
    }

    private static func exportArchiveCommand(
        plan: BuildPlan,
        platform: ArchivePlatform
    ) -> ProcessCommand {
        ProcessCommand(
            executable: "/usr/bin/xcrun",
            arguments: [
                "xcodebuild",
                "-exportArchive",
                "-archivePath",
                plan.archivePath(for: platform).path,
                "-exportOptionsPlist",
                plan.uploadOptionsPlist.path,
                "-allowProvisioningUpdates",
            ],
            environment: ["DEVELOPER_DIR": plan.options.developerDirectory]
        )
    }

    private static func buildLookupCommand(
        plan: BuildPlan,
        platform: ArchivePlatform
    ) -> ProcessCommand {
        ProcessCommand(
            executable: plan.options.helmPath,
            arguments: [
                "apps",
                plan.options.appID,
                "builds",
                "--platform",
                platform.helmName,
                "--version",
                plan.options.version,
                "--number",
                plan.options.buildNumber,
                "--agent",
            ]
        )
    }

    private static func buildUpdateCommand(
        buildID: String,
        whatsNew: String,
        plan: BuildPlan
    ) -> ProcessCommand {
        ProcessCommand(
            executable: plan.options.helmPath,
            arguments: [
                "build",
                buildID,
                "update",
                "--uses-non-exempt-encryption",
                "false",
                "--locale",
                "en-US",
                "--whats-new",
                whatsNew,
                "--agent",
            ]
        )
    }

    private static func buildAttachCommand(
        buildID: String,
        plan: BuildPlan
    ) -> ProcessCommand {
        ProcessCommand(
            executable: plan.options.helmPath,
            arguments: [
                "build",
                buildID,
                "attach",
                "--groups",
                plan.options.externalGroup,
                "--agent",
            ]
        )
    }

    private static func verifyExecutable(at path: String, label: String) throws {
        guard FileManager.default.isExecutableFile(atPath: path) else {
            throw TestFlightUploadError.missingExecutable(label: label, path: path)
        }
    }
}

private struct BuildPlan {
    let repositoryRoot: URL
    let options: TestFlightUploadOptions

    var project: URL {
        repositoryRoot.appending(path: "RetroRacing/RetroRacing.xcodeproj")
    }

    var buildDirectory: URL {
        repositoryRoot.appending(path: "build/testflight-\(options.version)")
    }

    var uploadOptionsPlist: URL {
        repositoryRoot.appending(path: "AppStore/testflight/ExportOptions-upload.plist")
    }

    var whatsNewFile: URL {
        repositoryRoot.appending(path: "AppStore/testflight/beta-notes/en-US/whats-new.txt")
    }

    func archivePath(for platform: ArchivePlatform) -> URL {
        buildDirectory.appending(path: platform.archiveName)
    }
}

private enum ArchivePlatform {
    case iOS
    case macOS

    var destination: String {
        switch self {
        case .iOS:
            return "generic/platform=iOS"
        case .macOS:
            return "generic/platform=macOS"
        }
    }

    var helmName: String {
        switch self {
        case .iOS:
            return "iOS"
        case .macOS:
            return "macOS"
        }
    }

    var archiveName: String {
        switch self {
        case .iOS:
            return "RetroRacingUniversal-iOS.xcarchive"
        case .macOS:
            return "RetroRacingUniversal-macOS.xcarchive"
        }
    }
}

public enum TestFlightUploadError: LocalizedError, Equatable {
    case invalidArguments(String)
    case missingExecutable(label: String, path: String)
    case buildNotFound(platform: String, version: String, buildNumber: String)

    public var errorDescription: String? {
        switch self {
        case let .invalidArguments(message):
            return message
        case let .missingExecutable(label, path):
            return "\(label) not found or not executable at: \(path)"
        case let .buildNotFound(platform, version, buildNumber):
            return "Timed out waiting for \(platform) build \(version) (\(buildNumber)) in App Store Connect."
        }
    }
}
