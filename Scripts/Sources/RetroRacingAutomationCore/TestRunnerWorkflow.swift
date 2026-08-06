//
//  TestRunnerWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import ScriptSupport

public enum TestRunnerWorkflow {
    public static func commands(
        repositoryRoot: URL,
        options: TestRunnerOptions,
        automaticDestinations: [TestRunnerPlatform: String] = [:]
    ) -> [ProcessCommand] {
        let project = repositoryRoot.appending(
            path: "RetroRacing/RetroRacing.xcodeproj"
        ).path

        if !options.onlyTesting.isEmpty {
            return [
                xcodebuildCommand(
                    project: project,
                    destination: destination(
                        for: options.platform,
                        options: options,
                        automaticDestinations: automaticDestinations
                    ),
                    onlyTesting: options.onlyTesting,
                    environment: options.environment,
                    buildMode: options.buildMode,
                    scheme: scheme(for: options.platform, options: options),
                    derivedDataPath: options.derivedDataPath
                ),
            ]
        }

        var commands = [ProcessCommand]()
        if options.platform == .universal || options.platform == .all {
            let universalDestination = destination(
                for: .universal,
                options: options,
                automaticDestinations: automaticDestinations
            )
            commands.append(xcodebuildCommand(
                project: project,
                destination: universalDestination,
                onlyTesting: ["RetroRacingSharedTests"],
                environment: options.environment,
                buildMode: options.buildMode,
                scheme: options.scheme,
                derivedDataPath: options.derivedDataPath
            ))
            commands.append(xcodebuildCommand(
                project: project,
                destination: universalDestination,
                onlyTesting: ["RetroRacingUniversalTests"],
                environment: options.environment,
                buildMode: options.buildMode,
                scheme: options.scheme,
                derivedDataPath: options.derivedDataPath
            ))
        }
        if options.platform == .vision || options.platform == .all {
            commands.append(xcodebuildCommand(
                project: project,
                destination: destination(
                    for: .vision,
                    options: options,
                    automaticDestinations: automaticDestinations
                ),
                onlyTesting: ["RetroRacingVisionOSTests"],
                environment: options.environment,
                buildMode: options.buildMode,
                scheme: "RetroRacingVisionOS",
                derivedDataPath: options.derivedDataPath
            ))
        }
        return commands
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
        let automaticDestinations = try resolveAutomaticDestinations(for: options)
        for command in commands(
            repositoryRoot: repositoryRoot,
            options: options,
            automaticDestinations: automaticDestinations
        ) {
            print(command.rendered)
            if !options.dryRun {
                try ProcessRunner.run(command, timeout: options.timeout)
            }
        }
        if options.dryRun {
            print("Dry run complete; tests were not started.")
        }
    }

    private static func resolveAutomaticDestinations(
        for options: TestRunnerOptions
    ) throws -> [TestRunnerPlatform: String] {
        guard options.destination.isEmpty else { return [:] }
        let devicesJSON = try SimulatorDestinationResolver.loadAvailableDevicesJSON()
        let platforms: [TestRunnerPlatform] = options.platform == .all
            ? [.universal, .vision]
            : [options.platform]
        var result = [TestRunnerPlatform: String]()
        for platform in platforms {
            let family: SimulatorDestinationResolver.Candidate.PlatformFamily = platform == .vision
                ? .visionOS
                : .iOS
            guard let candidate = try SimulatorDestinationResolver.resolveTestingCandidate(
                platformFamily: family,
                minimumMajorVersion: 26,
                devicesJSON: devicesJSON
            ) else {
                throw TestRunnerError.simulatorNotFound(platform)
            }
            result[platform] = candidate.destination
        }
        return result
    }

    private static func destination(
        for platform: TestRunnerPlatform,
        options: TestRunnerOptions,
        automaticDestinations: [TestRunnerPlatform: String]
    ) -> String {
        if options.destination.isEmpty == false { return options.destination }
        return automaticDestinations[platform] ?? ""
    }

    private static func scheme(
        for platform: TestRunnerPlatform,
        options: TestRunnerOptions
    ) -> String {
        platform == .vision ? "RetroRacingVisionOS" : options.scheme
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
