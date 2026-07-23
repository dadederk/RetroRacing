//
//  HelmCLI.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import ScriptSupport

public enum HelmCLI {
    public static let defaultPath = "/Applications/Helm.app/Contents/Helpers/helm-asc"

    public struct PathsResponse: Decodable, Sendable {
        public let uploadsInbox: String
    }

    public struct AgentResponse: Decodable, Sendable {
        public let status: String?
    }

    public static func resolvePath(from arguments: CLIArguments) throws -> String {
        try arguments.value(after: "--helm") ?? defaultPath
    }

    public static func verifyExists(at path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MetadataToolError.helmNotFound(path)
        }
    }

    public static func paths(helmPath: String) throws -> PathsResponse {
        let output = try run(helmPath: helmPath, arguments: ["paths", "--agent"])
        guard let data = output.data(using: .utf8) else {
            throw MetadataToolError.helmFailed("Helm paths output was not UTF-8.")
        }
        return try JSONDecoder().decode(PathsResponse.self, from: data)
    }

    @discardableResult
    public static func run(helmPath: String, arguments: [String]) throws -> String {
        let command = [helmPath] + arguments
        let payload = try JSONSerialization.data(withJSONObject: command)
        let script = """
        import json, subprocess, sys
        command = json.loads(sys.stdin.read())
        result = subprocess.run(command, capture_output=True, text=True)
        sys.stdout.write(result.stdout)
        sys.stderr.write(result.stderr)
        sys.exit(result.returncode)
        """
        let process = Process()
        let standardOutput = Pipe()
        let standardError = Pipe()
        let standardInput = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", script]
        process.standardOutput = standardOutput
        process.standardError = standardError
        process.standardInput = standardInput

        try process.run()
        standardInput.fileHandleForWriting.write(payload)
        try standardInput.fileHandleForWriting.close()
        process.waitUntilExit()

        let output = readText(from: standardOutput)
        let errorOutput = readText(from: standardError)
        guard process.terminationStatus == 0 else {
            throw ScriptSupportError.commandFailed(
                command.joined(separator: " "),
                process.terminationStatus,
                errorOutput.isEmpty ? output : errorOutput
            )
        }
        return output
    }

    public static func isNoopAgentResponse(_ output: String) -> Bool {
        guard let data = output.data(using: .utf8),
              let response = try? JSONDecoder().decode(AgentResponse.self, from: data) else {
            return output.contains("\"status\" : \"noop\"")
        }
        return response.status == "noop"
    }

    private static func readText(from pipe: Pipe) -> String {
        String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
