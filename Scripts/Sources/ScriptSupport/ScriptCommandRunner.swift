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
        case .interactiveMenu:
            if RetroRapidInteractiveMenu.shouldUseInteractiveMenu() {
                try RetroRapidInteractiveMenu.run(repositoryRoot: repositoryRoot)
            } else {
                print(ScriptCommandCatalog.helpText())
            }
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
            var completedSteps: [String] = []
            var failedStep: String?
            do {
                for step in ScriptCommandCatalog.checkRecipeSteps {
                    let label = "check: \(step.executable)"
                    print("\(label)…")
                    try run(
                        makeSwiftRunCommand(
                            repositoryRoot: repositoryRoot,
                            executable: step.executable,
                            arguments: step.arguments
                        )
                    )
                    completedSteps.append(label)
                }
            } catch {
                failedStep = ScriptCommandCatalog.checkRecipeSteps[
                    safe: completedSteps.count
                ].map { "check: \($0.executable)" }
                fputs("Check recipe failed.\n", stderr)
                for step in completedSteps {
                    fputs("  ✓ \(step)\n", stderr)
                }
                if let failedStep {
                    fputs("  ✗ \(failedStep)\n", stderr)
                }
                throw error
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
