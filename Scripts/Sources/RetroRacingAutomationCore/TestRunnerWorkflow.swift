//
//  TestRunnerWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import ScriptSupport

public struct TestRunnerOptions: Equatable, Sendable {
    public let destination: String
    public let dryRun: Bool
    public let onlyTesting: [String]

    public init(destination: String, dryRun: Bool, onlyTesting: [String] = []) {
        self.destination = destination
        self.dryRun = dryRun
        self.onlyTesting = onlyTesting
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
                testCommand(
                    project: project,
                    destination: options.destination,
                    onlyTesting: options.onlyTesting
                ),
            ]
        }

        return [
            testCommand(
                project: project,
                destination: options.destination,
                onlyTesting: ["RetroRacingSharedTests"]
            ),
            testCommand(
                project: project,
                destination: options.destination,
                onlyTesting: ["RetroRacingUniversalTests"]
            ),
        ]
    }

    public static func run(repositoryRoot: URL, options: TestRunnerOptions) throws {
        for command in commands(repositoryRoot: repositoryRoot, options: options) {
            print(command.rendered)
            if !options.dryRun {
                try ProcessRunner.run(command)
            }
        }
        if options.dryRun {
            print("Dry run complete; tests were not started.")
        }
    }

    private static func testCommand(
        project: String,
        destination: String,
        onlyTesting: [String]
    ) -> ProcessCommand {
        var arguments = [
            "xcodebuild",
            "test",
            "-project",
            project,
            "-scheme",
            "RetroRacingUniversal",
            "-destination",
            destination,
        ]
        for filter in onlyTesting {
            arguments.append("-only-testing:\(filter)")
        }
        return ProcessCommand(
            executable: "/usr/bin/xcrun",
            arguments: arguments
        )
    }
}
