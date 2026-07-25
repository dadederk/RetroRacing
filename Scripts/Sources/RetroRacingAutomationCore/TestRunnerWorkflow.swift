//
//  TestRunnerWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import ScriptSupport

public struct TestRunnerOptions: Equatable, Sendable {
    public enum BuildMode: Equatable, Sendable {
        case test
        case buildForTesting
        case testWithoutBuilding
    }

    public let destination: String
    public let dryRun: Bool
    public let onlyTesting: [String]
    public let environment: [String: String]
    public let timeout: TimeInterval?
    public let buildMode: BuildMode
    public let scheme: String

    public init(
        destination: String,
        dryRun: Bool,
        onlyTesting: [String] = [],
        environment: [String: String] = [:],
        timeout: TimeInterval? = nil,
        buildMode: BuildMode = .test,
        scheme: String = "RetroRacingUniversal"
    ) {
        self.destination = destination
        self.dryRun = dryRun
        self.onlyTesting = onlyTesting
        self.environment = environment
        self.timeout = timeout
        self.buildMode = buildMode
        self.scheme = scheme
    }

    public static func parse(_ arguments: CLIArguments) throws -> TestRunnerOptions {
        try arguments.rejectUnknownFlags(
            allowing: ["--dry-run"],
            valueFlags: ["--destination", "--only-testing"]
        )
        return TestRunnerOptions(
            destination: try arguments.value(after: "--destination")
                ?? "platform=iOS Simulator,name=iPhone 17 Pro",
            dryRun: arguments.contains("--dry-run"),
            onlyTesting: arguments.values(for: "--only-testing")
        )
    }
}

public enum TestRunnerWorkflow {
    public static func commands(
        repositoryRoot: URL,
        options: TestRunnerOptions
    ) -> [ProcessCommand] {
        let project = repositoryRoot.appending(
            path: "RetroRacing/RetroRacing.xcodeproj"
        ).path

        if !options.onlyTesting.isEmpty {
            return [
                xcodebuildCommand(
                    project: project,
                    destination: options.destination,
                    onlyTesting: options.onlyTesting,
                    environment: options.environment,
                    buildMode: options.buildMode,
                    scheme: options.scheme
                ),
            ]
        }

        return [
            xcodebuildCommand(
                project: project,
                destination: options.destination,
                onlyTesting: ["RetroRacingSharedTests"],
                environment: options.environment,
                buildMode: options.buildMode,
                scheme: options.scheme
            ),
            xcodebuildCommand(
                project: project,
                destination: options.destination,
                onlyTesting: ["RetroRacingUniversalTests"],
                environment: options.environment,
                buildMode: options.buildMode,
                scheme: options.scheme
            ),
        ]
    }

    public static func runBuildForTesting(
        repositoryRoot: URL,
        destination: String,
        scheme: String = "RetroRacingUniversal",
        onlyTesting: [String] = [
            "RetroRacingUniversalUITests/AppStoreScreenshotTests/testCaptureConfiguredScreenshot",
        ],
        dryRun: Bool = false,
        timeout: TimeInterval? = nil
    ) throws {
        let options = TestRunnerOptions(
            destination: destination,
            dryRun: dryRun,
            onlyTesting: onlyTesting,
            timeout: timeout,
            buildMode: .buildForTesting,
            scheme: scheme
        )
        try run(repositoryRoot: repositoryRoot, options: options)
    }

    public static func run(repositoryRoot: URL, options: TestRunnerOptions) throws {
        for command in commands(repositoryRoot: repositoryRoot, options: options) {
            print(command.rendered)
            if !options.dryRun {
                try ProcessRunner.run(command, timeout: options.timeout)
            }
        }
        if options.dryRun {
            print("Dry run complete; tests were not started.")
        }
    }

    private static func xcodebuildCommand(
        project: String,
        destination: String,
        onlyTesting: [String],
        environment: [String: String] = [:],
        buildMode: TestRunnerOptions.BuildMode = .test,
        scheme: String = "RetroRacingUniversal"
    ) -> ProcessCommand {
        let action: String
        switch buildMode {
        case .test:
            action = "test"
        case .buildForTesting:
            action = "build-for-testing"
        case .testWithoutBuilding:
            action = "test-without-building"
        }

        var arguments = [
            "xcodebuild",
            action,
            "-project",
            project,
            "-scheme",
            scheme,
            "-destination",
            destination,
        ]
        for filter in onlyTesting {
            arguments.append("-only-testing:\(filter)")
        }
        if buildMode != .buildForTesting {
            arguments.append("-parallel-testing-enabled")
            arguments.append("NO")
        }
        return ProcessCommand(
            executable: "/usr/bin/xcrun",
            arguments: arguments,
            environment: environment
        )
    }

    private static func testCommand(
        project: String,
        destination: String,
        onlyTesting: [String],
        environment: [String: String] = [:],
        scheme: String = "RetroRacingUniversal"
    ) -> ProcessCommand {
        xcodebuildCommand(
            project: project,
            destination: destination,
            onlyTesting: onlyTesting,
            environment: environment,
            buildMode: .test,
            scheme: scheme
        )
    }
}
