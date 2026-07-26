//
//  ScriptCommandCatalogTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import Testing

@testable import ScriptSupport

@Test
func givenCatalogWhenComparedToPackageProductsThenEveryExecutableIsRegistered() throws {
    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["Scripts/Package.swift"]
    )
    let packageManifestURL = repositoryRoot.appending(path: "Scripts/Package.swift")
    let packageNames = Set(
        try PackageManifestReader.executableProductNames(packageManifestURL: packageManifestURL)
    )
    let catalogNames = Set(ScriptCommandCatalog.executables.map(\.name))

    #expect(catalogNames == packageNames)
}

@Test
func givenCheckRecipeWhenResolvedThenStepsMatchReadmeOrder() {
    #expect(ScriptCommandCatalog.checkRecipeSteps.count == 6)
    #expect(ScriptCommandCatalog.checkRecipeSteps[0].executable == "generate-road-dash-masks")
    #expect(ScriptCommandCatalog.checkRecipeSteps[0].arguments == ["--check"])
    #expect(ScriptCommandCatalog.checkRecipeSteps[1].executable == "sync-screenshot-studio-localizations")
    #expect(ScriptCommandCatalog.checkRecipeSteps[2].executable == "generate-metadata-docs")
    #expect(ScriptCommandCatalog.checkRecipeSteps[3].executable == "check-documentation")
    #expect(ScriptCommandCatalog.checkRecipeSteps[4].executable == "apply-iap-localizations")
    #expect(ScriptCommandCatalog.checkRecipeSteps[5].executable == "apply-game-center-eu-localizations")
}

@Test
func givenTypoWhenSuggestingExecutableThenNearestMatchIsReturned() {
    #expect(ScriptCommandCatalog.suggestExecutable(near: "run-test") == "run-tests")
    #expect(ScriptCommandCatalog.suggestExecutable(near: "apply-game-center") == "apply-game-center-eu-localizations")
}

@Test
func givenTypoWhenSuggestingTopLevelCommandThenNearestMatchIsReturned() {
    #expect(ScriptCommandCatalog.suggestTopLevelCommand(near: "chek") == "check")
    #expect(ScriptCommandCatalog.suggestTopLevelCommand(near: "scrrenshots") == "screenshots")
}

@Test
func givenMetadataApplyRouteWhenParsingThenDispatchPlanTargetsApplyMetadata() throws {
    let plan = try RetroRapidCLIParser.parse(["metadata", "apply", "--dry-run"])

    #expect(
        plan == .runSwiftExecutable(
            executable: "apply-retrorapid-metadata",
            arguments: ["--dry-run"]
        )
    )
}

@Test
func givenTestPackageRouteWhenParsingThenDispatchPlanRunsSwiftTestPackage() throws {
    let plan = try RetroRapidCLIParser.parse(["test", "package", "--filter", "ScriptSupportTests"])

    #expect(
        plan == .runSwiftTestPackage(arguments: ["--filter", "ScriptSupportTests"])
    )
}

@Test
func givenASCGameCenterPrintRouteWhenParsingThenDispatchPlanTargetsPrintTool() throws {
    let plan = try RetroRapidCLIParser.parse(["asc", "game-center", "print"])

    #expect(
        plan == .runSwiftExecutable(
            executable: "print-game-center-eu-localizations",
            arguments: []
        )
    )
}

@Test
func givenUnknownRunExecutableWhenParsingThenSuggestionIsIncluded() {
    #expect(throws: ScriptSupportError.self) {
        _ = try RetroRapidCLIParser.parse(["run", "run-test"])
    }

    do {
        _ = try RetroRapidCLIParser.parse(["run", "run-test"])
        Issue.record("Expected unknown executable error")
    } catch let error as ScriptSupportError {
        #expect(error.errorDescription?.contains("run-tests") == true)
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}

@Test
func givenRepositoryRootWhenBuildingSwiftRunCommandThenPackagePathIsResolved() {
    let repositoryRoot = URL(fileURLWithPath: "/tmp/RetroRacing", isDirectory: true)
    let command = ScriptCommandRunner.makeSwiftRunCommand(
        repositoryRoot: repositoryRoot,
        executable: "run-tests",
        arguments: ["--dry-run"]
    )

    #expect(command.arguments.prefix(4) == ["run", "--package-path", "/tmp/RetroRacing/Scripts", "run-tests"])
    #expect(command.arguments.suffix(1) == ["--dry-run"])
    #expect(command.currentDirectory == repositoryRoot)
}

@Test
func givenCheckPlanWhenBuildingCommandsThenEachStepUsesSwiftRun() {
    let repositoryRoot = URL(fileURLWithPath: "/tmp/RetroRacing", isDirectory: true)

    let commands = ScriptCommandCatalog.checkRecipeSteps.map { step in
        ScriptCommandRunner.makeSwiftRunCommand(
            repositoryRoot: repositoryRoot,
            executable: step.executable,
            arguments: step.arguments
        )
    }

    #expect(commands.count == 6)
    #expect(commands.allSatisfy { $0.arguments.first == "run" })
}

@Test
func givenEmptyArgumentsWhenParsingThenInteractiveMenuPlanIsReturned() throws {
    #expect(try RetroRapidCLIParser.parse([]) == .interactiveMenu)
}

@Test
func givenHelpFlagOnlyWhenParsingThenHelpPlanIsReturned() throws {
    #expect(try RetroRapidCLIParser.parse(["--help"]) == .help)
    #expect(try RetroRapidCLIParser.parse(["-h"]) == .help)
}

@Test
func givenMenuRouteWhenParsingThenInteractiveMenuPlanIsReturned() throws {
    #expect(try RetroRapidCLIParser.parse(["menu"]) == .interactiveMenu)
}

@Test
func givenTestFlightHelpWhenParsingThenHelpIsForwardedToExecutable() throws {
    let plan = try RetroRapidCLIParser.parse(["testflight", "--help"])
    #expect(
        plan == .runSwiftExecutable(
            executable: "submit-testflight-build",
            arguments: ["--help"]
        )
    )
}

@Test
func givenListRouteWhenParsingThenListPlanIsReturned() throws {
    #expect(try RetroRapidCLIParser.parse(["list"]) == .list)
}

@Test
func givenCheckRouteWhenParsingThenCheckRecipePlanIsReturned() throws {
    #expect(try RetroRapidCLIParser.parse(["check"]) == .runCheckRecipe)
}

@Test
func givenDocsRouteWhenParsingThenDispatchPlanTargetsCheckDocumentation() throws {
    let plan = try RetroRapidCLIParser.parse(["docs"])
    #expect(plan == .runSwiftExecutable(executable: "check-documentation", arguments: []))
}

@Test
func givenMetadataGenerateRouteWhenParsingThenDispatchPlanTargetsGenerateMetadata() throws {
    let plan = try RetroRapidCLIParser.parse(["metadata", "generate", "--check"])
    #expect(
        plan == .runSwiftExecutable(
            executable: "generate-metadata-docs",
            arguments: ["--check"]
        )
    )
}

@Test
func givenASCIAPRouteWhenParsingThenDispatchPlanTargetsApplyIAP() throws {
    let plan = try RetroRapidCLIParser.parse(["asc", "iap", "--check"])
    #expect(
        plan == .runSwiftExecutable(
            executable: "apply-iap-localizations",
            arguments: ["--check"]
        )
    )
}

@Test
func givenASCGameCenterRouteWhenParsingThenDispatchPlanTargetsApplyGameCenter() throws {
    let plan = try RetroRapidCLIParser.parse(["asc", "game-center", "--leaderboards-only"])
    #expect(
        plan == .runSwiftExecutable(
            executable: "apply-game-center-eu-localizations",
            arguments: ["--leaderboards-only"]
        )
    )
}

@Test
func givenScreenshotsCaptureRouteWhenParsingThenDispatchPlanTargetsCaptureTool() throws {
    let plan = try RetroRapidCLIParser.parse(["screenshots", "capture", "--dry-run"])
    #expect(
        plan == .runSwiftExecutable(
            executable: "capture-app-store-screenshots",
            arguments: ["--dry-run"]
        )
    )
}

@Test
func givenScreenshotsSyncRouteWhenParsingThenDispatchPlanTargetsSyncTool() throws {
    let plan = try RetroRapidCLIParser.parse(["screenshots", "sync", "--check"])
    #expect(
        plan == .runSwiftExecutable(
            executable: "sync-screenshot-studio-localizations",
            arguments: ["--check"]
        )
    )
}

@Test
func givenAssetsMasksRouteWhenParsingThenDispatchPlanTargetsMaskGenerator() throws {
    let plan = try RetroRapidCLIParser.parse(["assets", "masks", "--check"])
    #expect(
        plan == .runSwiftExecutable(
            executable: "generate-road-dash-masks",
            arguments: ["--check"]
        )
    )
}

@Test
func givenASCScreenshotsSwapRouteWhenParsingThenDispatchPlanTargetsSwapTool() throws {
    let plan = try RetroRapidCLIParser.parse([
        "asc", "screenshots", "swap", "--first", "3", "--second", "4", "--dry-run",
    ])
    #expect(
        plan == .runSwiftExecutable(
            executable: "swap-app-store-screenshots",
            arguments: ["--first", "3", "--second", "4", "--dry-run"]
        )
    )
}

@Test
func givenTestFlightRouteWhenParsingThenDispatchPlanTargetsSubmitTestFlight() throws {
    let plan = try RetroRapidCLIParser.parse(["testflight", "all", "--dry-run"])
    #expect(
        plan == .runSwiftExecutable(
            executable: "submit-testflight-build",
            arguments: ["all", "--dry-run"]
        )
    )
}

@Test
func givenListRouteWithExtraArgumentsWhenParsingThenErrorIsThrown() {
    #expect(throws: ScriptSupportError.self) {
        _ = try RetroRapidCLIParser.parse(["list", "--verbose"])
    }
}
