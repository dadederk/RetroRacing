//
//  ParallelTestCanaryWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 01/08/2026.
//

import Foundation
import ScriptSupport

public struct ParallelTestCanaryConfiguration: Equatable, Sendable {
    public var scheme = "RetroRacingUniversal"
    public var destination = "platform=iOS Simulator,name=iPhone 17 Pro"
    public var workerCounts = [2, 4]
    public var dryRun = false

    public init() {}

    public static func parse(_ arguments: [String]) throws -> ParallelTestCanaryConfiguration {
        var configuration = ParallelTestCanaryConfiguration()
        var index = arguments.startIndex

        while index < arguments.endIndex {
            switch arguments[index] {
            case "--scheme":
                configuration.scheme = try requiredValue(after: "--scheme", arguments: arguments, index: &index)
            case "--destination":
                configuration.destination = try requiredValue(after: "--destination", arguments: arguments, index: &index)
            case "--workers":
                let rawWorkerCounts = try requiredValue(after: "--workers", arguments: arguments, index: &index)
                configuration.workerCounts = try parseWorkerCounts(rawWorkerCounts)
            case "--dry-run":
                configuration.dryRun = true
            case "--help":
                throw ParallelTestCanaryError.helpRequested
            default:
                throw ParallelTestCanaryError.unknownArgument(arguments[index])
            }
            index += 1
        }

        guard configuration.workerCounts.isEmpty == false else {
            throw ParallelTestCanaryError.noWorkerCounts
        }

        return configuration
    }

    private static func requiredValue(
        after flag: String,
        arguments: [String],
        index: inout Int
    ) throws -> String {
        guard arguments.indices.contains(index + 1) else {
            throw ParallelTestCanaryError.missingArgumentValue(flag)
        }
        let value = arguments[index + 1]
        guard !value.isEmpty, !value.hasPrefix("-") else {
            throw ParallelTestCanaryError.missingArgumentValue(flag)
        }
        index += 1
        return value
    }

    private static func parseWorkerCounts(_ raw: String) throws -> [Int] {
        try raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { value in
                guard let workerCount = Int(value), workerCount > 0 else {
                    throw ParallelTestCanaryError.invalidWorkerCount(value)
                }
                return workerCount
            }
    }
}

public struct ParallelTestCanaryStep: Equatable, Sendable {
    public let workerCount: Int
    public let command: ProcessCommand
}

public enum ParallelTestCanaryWorkflow {
    public static let unitTestFilters = [
        "RetroRacingSharedTests",
        "RetroRacingUniversalTests",
    ]

    public static func makeSteps(
        repositoryRoot: URL,
        configuration: ParallelTestCanaryConfiguration
    ) -> [ParallelTestCanaryStep] {
        let projectPath = repositoryRoot
            .appending(path: "RetroRacing/RetroRacing.xcodeproj")
            .path

        return configuration.workerCounts.map { workerCount in
            ParallelTestCanaryStep(
                workerCount: workerCount,
                command: ProcessCommand(
                    executable: "/usr/bin/xcrun",
                    arguments: xcodebuildArguments(
                        projectPath: projectPath,
                        configuration: configuration,
                        workerCount: workerCount
                    ),
                    currentDirectory: repositoryRoot.appending(path: "RetroRacing")
                )
            )
        }
    }

    public static func run(
        repositoryRoot: URL,
        configuration: ParallelTestCanaryConfiguration
    ) throws {
        let steps = makeSteps(repositoryRoot: repositoryRoot, configuration: configuration)
        print("Parallel canary scheme: \(configuration.scheme)")
        print("Parallel canary destination: \(configuration.destination)")

        for step in steps {
            print("🧪 RetroRapid parallel canary, workers=\(step.workerCount)")
            print(step.command.rendered)
            if !configuration.dryRun {
                try ProcessRunner.run(step.command)
            }
        }

        if configuration.dryRun {
            print("Dry run complete; no tests were started.")
        } else {
            print("✅ Parallel canary completed.")
        }
    }

    private static func xcodebuildArguments(
        projectPath: String,
        configuration: ParallelTestCanaryConfiguration,
        workerCount: Int
    ) -> [String] {
        var arguments = [
            "xcodebuild",
            "test",
            "-project", projectPath,
            "-scheme", configuration.scheme,
            "-destination", configuration.destination,
        ]

        for filter in unitTestFilters {
            arguments.append("-only-testing:\(filter)")
        }

        arguments.append(contentsOf: [
            "-parallel-testing-enabled", "YES",
            "-parallel-testing-worker-count", "\(workerCount)",
            "-enableCodeCoverage", "NO",
            "-quiet",
            "-collect-test-diagnostics", "never",
            "-test-timeouts-enabled", "YES",
            "-default-test-execution-time-allowance", "120",
            "-maximum-test-execution-time-allowance", "240",
        ])

        return arguments
    }
}

public enum ParallelTestCanaryError: Error, LocalizedError {
    case helpRequested
    case missingArgumentValue(String)
    case unknownArgument(String)
    case invalidWorkerCount(String)
    case noWorkerCounts

    public var errorDescription: String? {
        switch self {
        case .helpRequested:
            return "Help requested"
        case .missingArgumentValue(let flag):
            return "Missing value after \(flag)"
        case .unknownArgument(let argument):
            return "Unknown argument: \(argument)"
        case .invalidWorkerCount(let value):
            return "Invalid worker count: \(value)"
        case .noWorkerCounts:
            return "At least one worker count is required"
        }
    }
}
