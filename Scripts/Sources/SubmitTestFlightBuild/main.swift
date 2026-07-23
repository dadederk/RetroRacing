//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 10/07/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

private let defaultAppID = "6758641625"
private let defaultVersion = "1.5"
private let defaultBuildNumber = "31"
private let defaultHelmPath = "/Applications/Helm.app/Contents/Helpers/helm-asc"
private let defaultDeveloperDirectory = "/Applications/Xcode.app/Contents/Developer"
private let defaultExternalGroup = "df40f833-12c7-4411-b28d-122690045c58"

do {
    let arguments = CLIArguments()
    if arguments.contains("-h") || arguments.contains("--help") {
        printUsage()
        exit(0)
    }

    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["RetroRacing/RetroRacing.xcodeproj", "Scripts/Package.swift"]
    )
    let options = try makeOptions(from: arguments)
    try TestFlightUploadWorkflow.run(repositoryRoot: repositoryRoot, options: options)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}

private func makeOptions(from arguments: CLIArguments) throws -> TestFlightUploadOptions {
    guard let commandValue = arguments.values.first,
          !commandValue.hasPrefix("-"),
          let command = TestFlightUploadCommand(rawValue: commandValue)
    else {
        throw TestFlightUploadError.invalidArguments(
            "Expected command: \(TestFlightUploadCommand.allCases.map(\.rawValue).joined(separator: ", "))"
        )
    }

    let flagArguments = CLIArguments(Array(arguments.values.dropFirst()))
    try flagArguments.rejectUnknownFlags(
        allowing: ["--dry-run"],
        valueFlags: [
            "--app-id",
            "--version",
            "--build-number",
            "--helm",
            "--developer-dir",
            "--external-group",
            "--poll-attempts",
            "--poll-interval",
        ]
    )

    return TestFlightUploadOptions(
        command: command,
        appID: try flagArguments.value(after: "--app-id") ?? defaultAppID,
        version: try flagArguments.value(after: "--version") ?? defaultVersion,
        buildNumber: try flagArguments.value(after: "--build-number") ?? defaultBuildNumber,
        helmPath: try flagArguments.value(after: "--helm")
            ?? ProcessInfo.processInfo.environment["HELM"]
            ?? defaultHelmPath,
        developerDirectory: try flagArguments.value(after: "--developer-dir")
            ?? ProcessInfo.processInfo.environment["DEVELOPER_DIR"]
            ?? defaultDeveloperDirectory,
        externalGroup: try flagArguments.value(after: "--external-group")
            ?? ProcessInfo.processInfo.environment["TESTFLIGHT_EXTERNAL_GROUP"]
            ?? defaultExternalGroup,
        pollAttempts: try parsePositiveInt(
            try flagArguments.value(after: "--poll-attempts"),
            label: "--poll-attempts",
            defaultValue: 40
        ),
        pollIntervalSeconds: TimeInterval(
            try parsePositiveInt(
                try flagArguments.value(after: "--poll-interval"),
                label: "--poll-interval",
                defaultValue: 15
            )
        ),
        dryRun: flagArguments.contains("--dry-run")
    )
}

private func parsePositiveInt(
    _ value: String?,
    label: String,
    defaultValue: Int
) throws -> Int {
    guard let value else { return defaultValue }
    guard let parsed = Int(value), parsed > 0 else {
        throw TestFlightUploadError.invalidArguments("\(label) must be a positive integer.")
    }
    return parsed
}

private func printUsage() {
    print(
        """
        Usage: swift run --package-path Scripts submit-testflight-build <command> [options]

        Commands:
          archive       Archive iOS and macOS with Xcode 26
          upload-ios    Upload iOS archive to App Store Connect, then configure via Helm
          upload-mac    Upload macOS archive to App Store Connect, then configure via Helm
          all           archive, upload-ios, then upload-mac

        Options:
          --dry-run                    Print commands without mutating archives or App Store Connect
          --app-id <id>                App Store Connect app ID
          --version <value>            Marketing version
          --build-number <value>       Build number
          --helm <path>                Path to helm-asc
          --developer-dir <path>       Xcode developer directory
          --external-group <id>        TestFlight group ID to attach
          --poll-attempts <count>      Build lookup attempts
          --poll-interval <seconds>    Seconds between build lookup attempts
        """
    )
}
