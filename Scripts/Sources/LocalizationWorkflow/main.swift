//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    guard let command = arguments.values.first else {
        throw ScriptSupportError.unexpectedArgument("localization-workflow requires audit or reviews")
    }
    let forwarded = CLIArguments(Array(arguments.values.dropFirst()))
    let repositoryRoot = try RepositoryLocator.locate(
        containing: [LocalizationReviewCollector.manifestRelativePath]
    )
    switch command {
    case "audit":
        try forwarded.rejectUnknownFlags(
            allowing: ["--require-approval"],
            valueFlags: ["--locale"]
        )
        let locale = try forwarded.value(after: "--locale")
        let snapshots = try LocalizationReviewWorkflow.audit(
            repositoryRoot: repositoryRoot,
            locale: locale,
            requireApproval: forwarded.contains("--require-approval")
        )
        print("Localization audit passed for \(snapshots.count) locale(s).")
    case "reviews":
        try forwarded.rejectUnknownFlags(
            allowing: ["--all", "--check"],
            valueFlags: ["--locale"]
        )
        let locale = try forwarded.value(after: "--locale")
        if locale != nil, forwarded.contains("--all") {
            throw ScriptSupportError.unexpectedArgument("Use either --locale or --all, not both.")
        }
        let snapshots = try LocalizationReviewWorkflow.renderReviews(
            repositoryRoot: repositoryRoot,
            locale: locale,
            check: forwarded.contains("--check")
        )
        print("Localization review sheets are current for \(snapshots.count) locale(s).")
    default:
        throw ScriptSupportError.unexpectedArgument(
            "Unknown localization workflow command: \(command)"
        )
    }
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
