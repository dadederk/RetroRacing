//
//  RetroRapidInteractiveMenu.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/07/2026.
//

import Foundation

public struct RetroRapidInteractiveMenuSelection: Sendable, Equatable {
    public let executable: String
    public let arguments: [String]

    public init(executable: String, arguments: [String]) {
        self.executable = executable
        self.arguments = arguments
    }
}

public enum RetroRapidInteractiveMenu {
    public static func shouldUseInteractiveMenu(
        isatty: ((Int32) -> Int32)? = Darwin.isatty
    ) -> Bool {
        if ProcessInfo.processInfo.environment["CI"] == "true" {
            return false
        }
        guard let isatty else { return false }
        return isatty(STDIN_FILENO) == 1
    }

    public static func run(
        repositoryRoot: URL,
        readLine: @escaping () -> String? = { Swift.readLine(strippingNewline: true) },
        write: (String) -> Void = { print($0) },
        execute: @escaping (ScriptDispatchPlan, URL) throws -> Void = { plan, root in
            try ScriptCommandRunner.execute(plan, repositoryRoot: root)
        }
    ) throws {
        var running = true
        while running {
            write("")
            write("RetroRapid Developer CLI")
            write("────────────────────────")
            write("1. Verify workspace")
            write("2. App Store metadata")
            write("3. App Store Connect")
            write("4. Screenshots")
            write("5. Assets and release")
            write("6. Run executable…")
            write("h. Help")
            write("q. Quit")
            write("")
            write("Choose an option: ")

            let rawChoice = readLine()
            guard let choice = rawChoice?.trimmingCharacters(in: .whitespacesAndNewlines), !choice.isEmpty else {
                if rawChoice == nil {
                    running = false
                }
                continue
            }

            switch choice.lowercased() {
            case "q", "quit", "exit":
                running = false
            case "h", "help", "?":
                try execute(.help, repositoryRoot)
            case "1":
                try runVerifyWorkspace(readLine: readLine, write: write, execute: execute, repositoryRoot: repositoryRoot)
            case "2":
                try runMetadataMenu(readLine: readLine, write: write, execute: execute, repositoryRoot: repositoryRoot)
            case "3":
                try runASCMenu(readLine: readLine, write: write, execute: execute, repositoryRoot: repositoryRoot)
            case "4":
                try runScreenshotsMenu(readLine: readLine, write: write, execute: execute, repositoryRoot: repositoryRoot)
            case "5":
                try runAssetsMenu(readLine: readLine, write: write, execute: execute, repositoryRoot: repositoryRoot)
            case "6":
                try runExecutablePicker(readLine: readLine, write: write, execute: execute, repositoryRoot: repositoryRoot)
            default:
                write("Unknown option '\(choice)'.")
            }
        }
    }

    public static func selection(
        forVerifyOption option: String,
        mutationMode: String
    ) -> RetroRapidInteractiveMenuSelection? {
        switch option {
        case "1":
            return RetroRapidInteractiveMenuSelection(executable: "check", arguments: mutationFlags(for: mutationMode))
        case "2":
            return RetroRapidInteractiveMenuSelection(
                executable: "retrorapid-test-package",
                arguments: mutationFlags(for: mutationMode)
            )
        case "3":
            return RetroRapidInteractiveMenuSelection(executable: "run-tests", arguments: mutationFlags(for: mutationMode))
        case "4":
            return RetroRapidInteractiveMenuSelection(executable: "check-documentation", arguments: mutationFlags(for: mutationMode))
        default:
            return nil
        }
    }

    private static func runVerifyWorkspace(
        readLine: @escaping () -> String?,
        write: (String) -> Void,
        execute: (ScriptDispatchPlan, URL) throws -> Void,
        repositoryRoot: URL
    ) throws {
        write("1. check  2. test package  3. test app  4. docs")
        guard let option = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        let mode = promptMutationMode(supportsCheck: true, supportsDryRun: option == "3", readLine: readLine, write: write)
        switch option {
        case "1":
            try confirmAndRun(plan: .runCheckRecipe, label: "./retrorapid check", readLine: readLine, write: write, execute: execute, repositoryRoot: repositoryRoot)
        case "2":
            try confirmAndRun(
                plan: .runSwiftTestPackage(arguments: mutationFlags(for: mode)),
                label: "./retrorapid test package",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        case "3":
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "run-tests", arguments: mutationFlags(for: mode)),
                label: "./retrorapid test",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        case "4":
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "check-documentation", arguments: []),
                label: "./retrorapid docs",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        default:
            write("Unknown verify option.")
        }
    }

    private static func runMetadataMenu(
        readLine: @escaping () -> String?,
        write: (String) -> Void,
        execute: (ScriptDispatchPlan, URL) throws -> Void,
        repositoryRoot: URL
    ) throws {
        write("1. generate  2. apply")
        guard let option = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        let mode = promptMutationMode(supportsCheck: option == "1", supportsDryRun: option == "2", readLine: readLine, write: write)
        let executable = option == "2" ? "apply-retrorapid-metadata" : "generate-metadata-docs"
        let label = option == "2" ? "./retrorapid metadata apply" : "./retrorapid metadata generate"
        try confirmAndRun(
            plan: .runSwiftExecutable(executable: executable, arguments: mutationFlags(for: mode)),
            label: label,
            readLine: readLine,
            write: write,
            execute: execute,
            repositoryRoot: repositoryRoot
        )
    }

    private static func runASCMenu(
        readLine: @escaping () -> String?,
        write: (String) -> Void,
        execute: (ScriptDispatchPlan, URL) throws -> Void,
        repositoryRoot: URL
    ) throws {
        write("1. IAP  2. Game Center  3. Game Center print  4. screenshots swap")
        guard let option = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        switch option {
        case "1":
            let mode = promptMutationMode(supportsCheck: true, supportsDryRun: true, readLine: readLine, write: write)
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "apply-iap-localizations", arguments: mutationFlags(for: mode)),
                label: "./retrorapid asc iap",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        case "2":
            let mode = promptMutationMode(supportsCheck: true, supportsDryRun: true, readLine: readLine, write: write)
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "apply-game-center-eu-localizations", arguments: mutationFlags(for: mode)),
                label: "./retrorapid asc game-center",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        case "3":
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "print-game-center-eu-localizations", arguments: []),
                label: "./retrorapid asc game-center print",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        case "4":
            let mode = promptMutationMode(supportsCheck: true, supportsDryRun: true, readLine: readLine, write: write)
            var args = mutationFlags(for: mode)
            write("First position [4]: ")
            if let first = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !first.isEmpty {
                args += ["--first", first]
            } else {
                args += ["--first", "4"]
            }
            write("Second position [5]: ")
            if let second = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !second.isEmpty {
                args += ["--second", second]
            } else {
                args += ["--second", "5"]
            }
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "swap-app-store-screenshots", arguments: args),
                label: "./retrorapid asc screenshots swap",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        default:
            write("Unknown ASC option.")
        }
    }

    private static func runScreenshotsMenu(
        readLine: @escaping () -> String?,
        write: (String) -> Void,
        execute: (ScriptDispatchPlan, URL) throws -> Void,
        repositoryRoot: URL
    ) throws {
        write("1. capture  2. sync")
        guard let option = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        if option == "2" {
            let mode = promptMutationMode(supportsCheck: true, supportsDryRun: false, readLine: readLine, write: write)
            try confirmAndRun(
                plan: .runSwiftExecutable(
                    executable: "sync-screenshot-studio-localizations",
                    arguments: mutationFlags(for: mode)
                ),
                label: "./retrorapid screenshots sync",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
            return
        }

        guard option == "1" else {
            write("Unknown screenshots option.")
            return
        }

        write("Platform [iphone] (iphone|ipad|mac|watch|all): ")
        let platformInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let mode = promptMutationMode(supportsCheck: false, supportsDryRun: true, readLine: readLine, write: write)
        var args = mutationFlags(for: mode)
        if platformInput.lowercased() == "all" {
            args.append("--all-platforms")
        } else if !platformInput.isEmpty {
            args += ["--platform", platformInput]
        }
        write("Appearance [light] (light|dark): ")
        if let appearance = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !appearance.isEmpty {
            args += ["--appearance", appearance]
        }
        try confirmAndRun(
            plan: .runSwiftExecutable(executable: "capture-app-store-screenshots", arguments: args),
            label: "./retrorapid screenshots capture",
            readLine: readLine,
            write: write,
            execute: execute,
            repositoryRoot: repositoryRoot
        )
    }

    private static func runAssetsMenu(
        readLine: @escaping () -> String?,
        write: (String) -> Void,
        execute: (ScriptDispatchPlan, URL) throws -> Void,
        repositoryRoot: URL
    ) throws {
        write("1. audit  2. optimize  3. masks  4. testflight")
        guard let option = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
        switch option {
        case "1":
            let mode = promptMutationMode(supportsCheck: true, supportsDryRun: false, readLine: readLine, write: write)
            var args = mutationFlags(for: mode)
            write("Full Release packaging audit? [n]: ")
            if readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "y" {
                args.append("--full")
            }
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "asset-audit", arguments: args),
                label: "./retrorapid assets audit",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        case "2":
            let mode = promptMutationMode(supportsCheck: true, supportsDryRun: true, readLine: readLine, write: write)
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "optimize-runtime-assets", arguments: mutationFlags(for: mode)),
                label: "./retrorapid assets optimize",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        case "3":
            let mode = promptMutationMode(supportsCheck: true, supportsDryRun: false, readLine: readLine, write: write)
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "generate-road-dash-masks", arguments: mutationFlags(for: mode)),
                label: "./retrorapid assets masks",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        case "4":
            write("TestFlight subcommand [all --dry-run]: ")
            let subcommand = readLine()?.split(separator: " ").map(String.init) ?? ["all", "--dry-run"]
            try confirmAndRun(
                plan: .runSwiftExecutable(executable: "submit-testflight-build", arguments: subcommand),
                label: "./retrorapid testflight \(subcommand.joined(separator: " "))",
                readLine: readLine,
                write: write,
                execute: execute,
                repositoryRoot: repositoryRoot
            )
        default:
            write("Unknown assets option.")
        }
    }

    private static func runExecutablePicker(
        readLine: @escaping () -> String?,
        write: (String) -> Void,
        execute: (ScriptDispatchPlan, URL) throws -> Void,
        repositoryRoot: URL
    ) throws {
        let executables = ScriptCommandCatalog.executables
        for (index, executable) in executables.enumerated() {
            write("\(index + 1). \(executable.name) — \(executable.purpose)")
        }
        write("Number or executable name: ")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty else { return }
        let executableName: String
        if let number = Int(input), executables.indices.contains(number - 1) {
            executableName = executables[number - 1].name
        } else {
            executableName = input
        }
        write("Extra flags (space-separated, optional): ")
        let flags = readLine()?.split(separator: " ").map(String.init) ?? []
        try confirmAndRun(
            plan: .runSwiftExecutable(executable: executableName, arguments: flags),
            label: "./retrorapid run \(executableName) \(flags.joined(separator: " "))",
            readLine: readLine,
            write: write,
            execute: execute,
            repositoryRoot: repositoryRoot
        )
    }

    private static func promptMutationMode(
        supportsCheck: Bool,
        supportsDryRun: Bool,
        readLine: @escaping () -> String?,
        write: (String) -> Void
    ) -> String {
        var options: [String] = []
        if supportsCheck { options.append("check") }
        if supportsDryRun { options.append("dry-run") }
        options.append("run")
        write("Mode (\(options.joined(separator: "/"))) [\(options.last ?? "run")]: ")
        let mode = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if mode.isEmpty { return options.last ?? "run" }
        if options.contains(mode) { return mode }
        return options.last ?? "run"
    }

    private static func mutationFlags(for mode: String) -> [String] {
        switch mode {
        case "check":
            return ["--check"]
        case "dry-run":
            return ["--dry-run"]
        default:
            return []
        }
    }

    private static func confirmAndRun(
        plan: ScriptDispatchPlan,
        label: String,
        readLine: @escaping () -> String?,
        write: (String) -> Void,
        execute: (ScriptDispatchPlan, URL) throws -> Void,
        repositoryRoot: URL
    ) throws {
        write("")
        write("Will run: \(label)")
        write("Proceed? [Y/n]: ")
        let answer = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "y"
        guard answer.isEmpty || answer == "y" || answer == "yes" else { return }
        try execute(plan, repositoryRoot)
    }
}
