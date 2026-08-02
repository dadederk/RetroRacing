//
//  RetroRapidCLIParser.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum RetroRapidCLIParser {
    public static func parse(_ arguments: [String]) throws -> ScriptDispatchPlan {
        if arguments.isEmpty {
            return .interactiveMenu
        }
        if arguments == ["--help"] || arguments == ["-h"] {
            return .help
        }

        guard let command = arguments.first else {
            return .interactiveMenu
        }

        let remainder = Array(arguments.dropFirst())

        switch command {
        case "menu":
            try rejectUnexpectedRouteTail(remainder, command: command)
            return .interactiveMenu
        case "list":
            try rejectUnexpectedRouteTail(remainder, command: command)
            return .list
        case "check":
            try rejectUnexpectedRouteTail(remainder, command: command)
            return .runCheckRecipe
        case "test":
            if remainder.first == "package" {
                return .runSwiftTestPackage(arguments: Array(remainder.dropFirst()))
            }
            if remainder.first == "parallel-canary" {
                return .runSwiftExecutable(
                    executable: "run-xcodebuild-parallel-canary",
                    arguments: Array(remainder.dropFirst())
                )
            }
            return .runSwiftExecutable(executable: "run-tests", arguments: remainder)
        case "docs":
            return .runSwiftExecutable(
                executable: "check-documentation",
                arguments: remainder
            )
        case "metadata":
            return try parseMetadataRoute(remainder)
        case "asc":
            return try parseASCRoute(remainder)
        case "screenshots":
            return try parseScreenshotsRoute(remainder)
        case "assets":
            return try parseAssetsRoute(remainder)
        case "testflight":
            return .runSwiftExecutable(
                executable: "submit-testflight-build",
                arguments: remainder
            )
        case "run":
            return try parseRunRoute(remainder)
        default:
            throw unknownCommandError(command)
        }
    }

    private static func parseMetadataRoute(_ remainder: [String]) throws -> ScriptDispatchPlan {
        guard let subcommand = remainder.first else {
            throw ScriptSupportError.unexpectedArgument("metadata requires generate or apply")
        }
        let forwarded = Array(remainder.dropFirst())
        switch subcommand {
        case "generate":
            return .runSwiftExecutable(
                executable: "generate-metadata-docs",
                arguments: forwarded
            )
        case "apply":
            return .runSwiftExecutable(
                executable: "apply-retrorapid-metadata",
                arguments: forwarded
            )
        default:
            throw unknownSubcommandError("metadata", subcommand)
        }
    }

    private static func parseASCRoute(_ remainder: [String]) throws -> ScriptDispatchPlan {
        guard let subcommand = remainder.first else {
            throw ScriptSupportError.unexpectedArgument("asc requires iap, game-center, or screenshots")
        }
        switch subcommand {
        case "iap":
            return .runSwiftExecutable(
                executable: "apply-iap-localizations",
                arguments: Array(remainder.dropFirst())
            )
        case "game-center":
            if remainder.dropFirst().first == "print" {
                return .runSwiftExecutable(
                    executable: "print-game-center-eu-localizations",
                    arguments: Array(remainder.dropFirst(2))
                )
            }
            return .runSwiftExecutable(
                executable: "apply-game-center-eu-localizations",
                arguments: Array(remainder.dropFirst())
            )
        case "screenshots":
            return try parseASCScreenshotsRoute(Array(remainder.dropFirst()))
        default:
            throw unknownSubcommandError("asc", subcommand)
        }
    }

    private static func parseASCScreenshotsRoute(_ remainder: [String]) throws -> ScriptDispatchPlan {
        guard let action = remainder.first else {
            throw ScriptSupportError.unexpectedArgument("asc screenshots requires swap")
        }
        switch action {
        case "swap":
            return .runSwiftExecutable(
                executable: "swap-app-store-screenshots",
                arguments: Array(remainder.dropFirst())
            )
        default:
            throw unknownSubcommandError("asc screenshots", action)
        }
    }

    private static func parseScreenshotsRoute(_ remainder: [String]) throws -> ScriptDispatchPlan {
        guard let subcommand = remainder.first else {
            throw ScriptSupportError.unexpectedArgument("screenshots requires capture or sync")
        }
        let forwarded = Array(remainder.dropFirst())
        switch subcommand {
        case "capture":
            return .runSwiftExecutable(
                executable: "capture-app-store-screenshots",
                arguments: forwarded
            )
        case "sync":
            return .runSwiftExecutable(
                executable: "sync-screenshot-studio-localizations",
                arguments: forwarded
            )
        default:
            throw unknownSubcommandError("screenshots", subcommand)
        }
    }

    private static func parseAssetsRoute(_ remainder: [String]) throws -> ScriptDispatchPlan {
        guard let subcommand = remainder.first else {
            throw ScriptSupportError.unexpectedArgument("assets requires masks")
        }
        let forwarded = Array(remainder.dropFirst())
        switch subcommand {
        case "masks":
            return .runSwiftExecutable(
                executable: "generate-road-dash-masks",
                arguments: forwarded
            )
        default:
            throw unknownSubcommandError("assets", subcommand)
        }
    }

    private static func parseRunRoute(_ remainder: [String]) throws -> ScriptDispatchPlan {
        guard let executable = remainder.first else {
            throw ScriptSupportError.unexpectedArgument("run requires an executable name")
        }
        guard ScriptCommandCatalog.isKnownExecutable(executable) else {
            if let suggestion = ScriptCommandCatalog.suggestExecutable(near: executable) {
                throw ScriptSupportError.unknownCLICommand(
                    executable,
                    suggestion: "Did you mean '\(suggestion)'?"
                )
            }
            throw ScriptSupportError.unknownCLICommand(executable, suggestion: nil)
        }
        return .runSwiftExecutable(
            executable: executable,
            arguments: Array(remainder.dropFirst())
        )
    }

    private static func rejectUnexpectedRouteTail(
        _ remainder: [String],
        command: String
    ) throws {
        guard remainder.isEmpty else {
            throw ScriptSupportError.unexpectedArgument(
                "\(command) does not accept additional arguments: \(remainder.joined(separator: " "))"
            )
        }
    }

    private static func unknownCommandError(_ command: String) -> ScriptSupportError {
        if let suggestion = ScriptCommandCatalog.suggestTopLevelCommand(near: command) {
            return .unknownCLICommand(command, suggestion: "Did you mean '\(suggestion)'?")
        }
        return .unknownCLICommand(command, suggestion: nil)
    }

    private static func unknownSubcommandError(
        _ command: String,
        _ subcommand: String
    ) -> ScriptSupportError {
        .unknownCLICommand(
            "\(command) \(subcommand)",
            suggestion: "Run ./retrorapid --help for available subcommands."
        )
    }
}
