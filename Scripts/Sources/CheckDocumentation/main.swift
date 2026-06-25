//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    try arguments.rejectUnknownFlags(allowing: [])
    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["AGENTS.md", "Requirements/INDEX.md"]
    )
    let report = try DocumentationValidator.validate(
        repositoryRoot: repositoryRoot
    )

    for warning in report.warnings {
        fputs("warning: \(warning)\n", stderr)
    }
    guard report.errors.isEmpty else {
        throw DocumentationCheckError.validationFailed(report.errors)
    }
    print(
        "check-documentation: OK "
            + "(\(report.checkedFileCount) markdown files)"
    )
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}

private enum DocumentationCheckError: LocalizedError {
    case validationFailed([String])

    var errorDescription: String? {
        switch self {
        case let .validationFailed(errors):
            errors.map { "error: \($0)" }.joined(separator: "\n")
                + "\ncheck-documentation: FAILED "
                + "(\(errors.count) issue(s))"
        }
    }
}
