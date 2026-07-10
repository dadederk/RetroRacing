//
//  ProcessRunner.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public struct ProcessCommand: Equatable, Sendable {
    public let executable: String
    public let arguments: [String]
    public let currentDirectory: URL?
    public let environment: [String: String]

    public init(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String] = [:]
    ) {
        self.executable = executable
        self.arguments = arguments
        self.currentDirectory = currentDirectory
        self.environment = environment
    }

    public var rendered: String {
        let environmentPrefix = environment.keys.sorted().map { key in
            "\(key)=\(Self.shellQuoted(environment[key] ?? ""))"
        }
        return (environmentPrefix + [executable] + arguments)
            .map(Self.shellQuotedIfNeeded)
            .joined(separator: " ")
    }

    private static func shellQuotedIfNeeded(_ value: String) -> String {
        if value.contains("="),
           let separatorIndex = value.firstIndex(of: "="),
           !value[..<separatorIndex].contains(where: { $0.isWhitespace }) {
            return value
        }
        return shellQuoted(value)
    }

    private static func shellQuoted(_ value: String) -> String {
        guard value.contains(where: { $0.isWhitespace || "'\"$`".contains($0) }) else {
            return value
        }
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

public enum ProcessRunner {
    @discardableResult
    public static func run(
        _ command: ProcessCommand,
        captureOutput: Bool = false
    ) throws -> String {
        let process = Process()
        let standardOutput = Pipe()
        let standardError = Pipe()

        process.executableURL = URL(fileURLWithPath: command.executable)
        process.arguments = command.arguments
        process.currentDirectoryURL = command.currentDirectory
        if !command.environment.isEmpty {
            process.environment = ProcessInfo.processInfo.environment
                .merging(command.environment) { _, new in new }
        }

        if captureOutput {
            process.standardOutput = standardOutput
            process.standardError = standardError
        } else {
            process.standardOutput = FileHandle.standardOutput
            process.standardError = FileHandle.standardError
        }

        try process.run()
        process.waitUntilExit()

        let output = captureOutput ? readText(from: standardOutput) : ""
        let errorOutput = captureOutput ? readText(from: standardError) : ""
        guard process.terminationStatus == 0 else {
            throw ScriptSupportError.commandFailed(
                command.rendered,
                process.terminationStatus,
                errorOutput.isEmpty ? output : errorOutput
            )
        }
        return output
    }

    private static func readText(from pipe: Pipe) -> String {
        String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
