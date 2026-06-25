//
//  CLIArguments.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public struct CLIArguments: Sendable {
    public let values: [String]

    public init(_ values: [String] = Array(CommandLine.arguments.dropFirst())) {
        self.values = values
    }

    public func contains(_ flag: String) -> Bool {
        values.contains(flag)
    }

    public func value(after flag: String) throws -> String? {
        guard let index = values.firstIndex(of: flag) else {
            return nil
        }
        guard values.indices.contains(index + 1) else {
            throw ScriptSupportError.missingValue(flag)
        }
        return values[index + 1]
    }

    public func values(for flag: String) -> [String] {
        var collected: [String] = []
        var index = values.startIndex
        while index < values.endIndex {
            if values[index] == flag,
               values.indices.contains(index + 1) {
                collected.append(values[index + 1])
                index += 2
            } else {
                index += 1
            }
        }
        return collected
    }

    public func rejectUnknownFlags(
        allowing flags: Set<String>,
        valueFlags: Set<String> = []
    ) throws {
        var index = values.startIndex

        while index < values.endIndex {
            let argument = values[index]
            guard argument.hasPrefix("-") else {
                throw ScriptSupportError.unexpectedArgument(argument)
            }
            guard flags.contains(argument) || valueFlags.contains(argument) else {
                throw ScriptSupportError.unknownFlag(argument)
            }
            index += valueFlags.contains(argument) ? 2 : 1
        }
    }
}
