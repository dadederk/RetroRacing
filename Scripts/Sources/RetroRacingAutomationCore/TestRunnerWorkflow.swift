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
    public let derivedDataPath: String?

    public init(
        destination: String,
        dryRun: Bool,
        onlyTesting: [String] = [],
        environment: [String: String] = [:],
        timeout: TimeInterval? = nil,
        buildMode: BuildMode = .test,
        scheme: String = "RetroRacingUniversal",
        derivedDataPath: String? = nil
    ) {
        self.destination = destination
        self.dryRun = dryRun
        self.onlyTesting = onlyTesting
        self.environment = environment
        self.timeout = timeout
        self.buildMode = buildMode
        self.scheme = scheme
        self.derivedDataPath = derivedDataPath
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
                    scheme: options.scheme,
                    derivedDataPath: options.derivedDataPath
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
                scheme: options.scheme,
                derivedDataPath: options.derivedDataPath
            ),
            xcodebuildCommand(
                project: project,
                destination: options.destination,
                onlyTesting: ["RetroRacingUniversalTests"],
                environment: options.environment,
                buildMode: options.buildMode,
                scheme: options.scheme,
                derivedDataPath: options.derivedDataPath
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
        timeout: TimeInterval? = nil,
        derivedDataPath: String? = nil
    ) throws {
        let options = TestRunnerOptions(
            destination: destination,
            dryRun: dryRun,
            onlyTesting: onlyTesting,
            timeout: timeout,
            buildMode: .buildForTesting,
            scheme: scheme,
            derivedDataPath: derivedDataPath
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
        scheme: String = "RetroRacingUniversal",
        derivedDataPath: String? = nil
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
        if let derivedDataPath {
            arguments.append("-derivedDataPath")
            arguments.append(derivedDataPath)
        }
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
            environment: testRunnerEnvironment(environment)
        )
    }

    /// `xcodebuild` only forwards variables prefixed with `TEST_RUNNER_` to XCTest.
    /// XCTest strips that prefix before exposing the values through `ProcessInfo`.
    private static func testRunnerEnvironment(
        _ environment: [String: String]
    ) -> [String: String] {
        var forwarded: [String: String] = [:]
        for (key, value) in environment {
            let forwardedKey = key.hasPrefix("TEST_RUNNER_")
                ? key
                : "TEST_RUNNER_\(key)"
            forwarded[forwardedKey] = value
        }
        return forwarded
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
