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
    /// When true, connects the child process to the terminal stdin (required for interactive `sudo`).
    public let usesTerminalInput: Bool

    public init(
        executable: String,
        arguments: [String],
        currentDirectory: URL? = nil,
        environment: [String: String] = [:],
        usesTerminalInput: Bool = false
    ) {
        self.executable = executable
        self.arguments = arguments
        self.currentDirectory = currentDirectory
        self.environment = environment
        self.usesTerminalInput = usesTerminalInput
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
    private final class State: @unchecked Sendable {
        static let shared = State()
        var runningProcess: Process?
        var interruptHandlerInstalled = false
        let lock = NSLock()
    }

    public static func installInterruptHandlerIfNeeded() {
        let state = State.shared
        state.lock.lock()
        defer { state.lock.unlock() }
        guard state.interruptHandlerInstalled == false else { return }
        state.interruptHandlerInstalled = true

        signal(SIGINT) { _ in
            ProcessRunner.terminateRunningProcess()
            exit(130)
        }
        signal(SIGTERM) { _ in
            ProcessRunner.terminateRunningProcess()
            exit(143)
        }
    }

    private static func terminateRunningProcess() {
        let state = State.shared
        state.lock.lock()
        let process = state.runningProcess
        state.lock.unlock()
        guard let process, process.isRunning else { return }
        process.terminate()
    }

    @discardableResult
    public static func run(
        _ command: ProcessCommand,
        captureOutput: Bool = false,
        timeout: TimeInterval? = nil
    ) throws -> String {
        installInterruptHandlerIfNeeded()
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

        if command.usesTerminalInput {
            process.standardInput = FileHandle.standardInput
        }

        try process.run()

        State.shared.lock.lock()
        State.shared.runningProcess = process
        State.shared.lock.unlock()
        defer {
            State.shared.lock.lock()
            State.shared.runningProcess = nil
            State.shared.lock.unlock()
        }

        if let timeout {
            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning {
                if Date() >= deadline {
                    process.terminate()
                    throw ScriptSupportError.commandTimedOut(command.rendered, timeout)
                }
                Thread.sleep(forTimeInterval: 0.25)
            }
        } else {
            process.waitUntilExit()
        }

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
