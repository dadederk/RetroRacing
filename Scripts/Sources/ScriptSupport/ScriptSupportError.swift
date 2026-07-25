//
//  ScriptSupportError.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public enum ScriptSupportError: LocalizedError {
    case repositoryRootNotFound([String])
    case missingValue(String)
    case unexpectedArgument(String)
    case unknownFlag(String)
    case commandFailed(String, Int32, String)
    case commandTimedOut(String, TimeInterval)
    case unknownCLICommand(String, suggestion: String?)

    public var errorDescription: String? {
        switch self {
        case let .repositoryRootNotFound(markers):
            "Could not find a repository containing: \(markers.joined(separator: ", "))."
        case let .missingValue(flag):
            "Missing value after \(flag)."
        case let .unexpectedArgument(argument):
            "Unexpected argument: \(argument)."
        case let .unknownFlag(flag):
            "Unknown option: \(flag)."
        case let .commandFailed(command, status, output):
            """
            Command failed with status \(status): \(command)
            \(output)
            """
        case let .commandTimedOut(command, timeout):
            "Command timed out after \(Int(timeout)) seconds: \(command)"
        case let .unknownCLICommand(command, suggestion):
            if let suggestion {
                "Unknown command: \(command). \(suggestion)"
            } else {
                "Unknown command: \(command)."
            }
        }
    }
}
