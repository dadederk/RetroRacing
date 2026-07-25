//
//  ScriptCommandRunner.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum ScriptCommandRunner {
    public static func scriptsPackagePath(in repositoryRoot: URL) -> URL {
        repositoryRoot.appending(path: "Scripts")
    }

    public static func makeSwiftRunCommand(
        repositoryRoot: URL,
        executable: String,
        arguments: [String] = [],
        swiftExecutable: String = SwiftExecutableLocator.resolve()
    ) -> ProcessCommand {
        ProcessCommand(
            executable: swiftExecutable,
            arguments: [
                "run",
                "--package-path",
                scriptsPackagePath(in: repositoryRoot).path,
                executable,
            ] + arguments,
            currentDirectory: repositoryRoot
        )
    }

    public static func makeSwiftTestPackageCommand(
        repositoryRoot: URL,
        arguments: [String] = [],
        swiftExecutable: String = SwiftExecutableLocator.resolve()
    ) -> ProcessCommand {
        ProcessCommand(
            executable: swiftExecutable,
            arguments: [
                "test",
                "--package-path",
                scriptsPackagePath(in: repositoryRoot).path,
            ] + arguments,
            currentDirectory: repositoryRoot
        )
    }

    public static func execute(
        _ plan: ScriptDispatchPlan,
        repositoryRoot: URL,
        run: (ProcessCommand) throws -> Void = { try ProcessRunner.run($0) }
    ) throws {
        switch plan {
        case .help:
            print(ScriptCommandCatalog.helpText())
        case .list:
            print(ScriptCommandCatalog.listText())
        case let .runSwiftExecutable(executable, arguments):
            try run(
                makeSwiftRunCommand(
                    repositoryRoot: repositoryRoot,
                    executable: executable,
                    arguments: arguments
                )
            )
        case let .runSwiftTestPackage(arguments):
            try run(
                makeSwiftTestPackageCommand(
                    repositoryRoot: repositoryRoot,
                    arguments: arguments
                )
            )
        case .runCheckRecipe:
            for step in ScriptCommandCatalog.checkRecipeSteps {
                try run(
                    makeSwiftRunCommand(
                        repositoryRoot: repositoryRoot,
                        executable: step.executable,
                        arguments: step.arguments
                    )
                )
            }
        }
    }
}
