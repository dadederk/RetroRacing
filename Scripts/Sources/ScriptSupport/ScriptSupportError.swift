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
        }
    }
}
