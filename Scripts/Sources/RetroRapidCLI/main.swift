//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import ScriptSupport

do {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let plan = try RetroRapidCLIParser.parse(arguments)
    let repositoryRoot = try RepositoryLocator.locate(containing: ["Scripts/Package.swift"])
    if case let .runSwiftExecutable(executable, forwardedArguments) = plan,
       executable == "capture-app-store-screenshots" {
        try ProcessRunner.replaceCurrentProcess(
            with: ScriptCommandRunner.makeSwiftRunCommand(
                repositoryRoot: repositoryRoot,
                executable: executable,
                arguments: forwardedArguments
            )
        )
    }
    try ScriptCommandRunner.execute(plan, repositoryRoot: repositoryRoot)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
