//
//  TestRunnerOptions.swift
//  RetroRacing
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import ScriptSupport

public enum TestRunnerPlatform: String, CaseIterable, Sendable {
    case universal
    case vision
    case all
}

public enum TestRunnerError: LocalizedError, Equatable {
    case invalidPlatform(String)
    case destinationWithAll
    case filterWithAll
    case simulatorNotFound(TestRunnerPlatform)

    public var errorDescription: String? {
        switch self {
        case .invalidPlatform(let value):
            return "Unsupported test platform '\(value)'. Use universal, vision, or all."
        case .destinationWithAll:
            return "--destination applies to one platform and cannot be combined with --platform all."
        case .filterWithAll:
            return "--only-testing cannot be combined with --platform all; run each platform separately."
        case .simulatorNotFound(let platform):
            let runtime = platform == .vision ? "visionOS" : "iOS"
            return "No compatible \(runtime) 26+ simulator is installed. Install a \(runtime) runtime in Xcode Settings > Platforms, or pass --destination for a single platform."
        }
    }
}

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
    public let platform: TestRunnerPlatform

    public init(
        destination: String,
        dryRun: Bool,
        onlyTesting: [String] = [],
        environment: [String: String] = [:],
        timeout: TimeInterval? = nil,
        buildMode: BuildMode = .test,
        scheme: String = "RetroRacingUniversal",
        derivedDataPath: String? = nil,
        platform: TestRunnerPlatform = .universal
    ) {
        self.destination = destination
        self.dryRun = dryRun
        self.onlyTesting = onlyTesting
        self.environment = environment
        self.timeout = timeout
        self.buildMode = buildMode
        self.scheme = scheme
        self.derivedDataPath = derivedDataPath
        self.platform = platform
    }

    public static func parse(_ arguments: CLIArguments) throws -> TestRunnerOptions {
        try arguments.rejectUnknownFlags(
            allowing: ["--dry-run"],
            valueFlags: ["--destination", "--only-testing", "--platform"]
        )
        let platformValue = try arguments.value(after: "--platform") ?? "universal"
        guard let platform = TestRunnerPlatform(rawValue: platformValue) else {
            throw TestRunnerError.invalidPlatform(platformValue)
        }
        let destination = try arguments.value(after: "--destination")
        let onlyTesting = arguments.values(for: "--only-testing")
        if platform == .all, destination != nil { throw TestRunnerError.destinationWithAll }
        if platform == .all, onlyTesting.isEmpty == false { throw TestRunnerError.filterWithAll }

        return TestRunnerOptions(
            destination: destination ?? "",
            dryRun: arguments.contains("--dry-run"),
            onlyTesting: onlyTesting,
            platform: platform
        )
    }
}
