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

    public init(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil
    ) {
        self.executable = executable
        self.arguments = arguments
        self.currentDirectory = currentDirectory
    }

    public var rendered: String {
        ([executable] + arguments).map(Self.shellQuoted).joined(separator: " ")
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
