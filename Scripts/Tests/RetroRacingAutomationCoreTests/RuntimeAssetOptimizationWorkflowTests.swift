//
//  RuntimeAssetOptimizationWorkflowTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation
import ScriptSupport
import Testing
@testable import RetroRacingAutomationCore

@Test
func testGivenOptimizerFlagsWhenParsingThenModesAreMutuallyExclusive() throws {
    #expect(try RuntimeAssetOptimizationOptions.parse(CLIArguments([])).mode == .apply)
    #expect(try RuntimeAssetOptimizationOptions.parse(CLIArguments(["--check"])).mode == .check)
    #expect(try RuntimeAssetOptimizationOptions.parse(CLIArguments(["--dry-run"])).mode == .dryRun)
    #expect(throws: (any Error).self) {
        try RuntimeAssetOptimizationOptions.parse(CLIArguments(["--check", "--dry-run"]))
    }
}

@Test
func testGivenImageMagickVersionWhenPreflightingThenOnlyPinnedReleaseIsAccepted() throws {
    // Given
    let supported = ImageMagickRuntimeAssetTransformer(
        processRunner: StubRuntimeAssetProcessRunner(
            output: "Version: ImageMagick 7.1.2-3 Q16-HDRI aarch64"
        )
    )
    let unsupported = ImageMagickRuntimeAssetTransformer(
        processRunner: StubRuntimeAssetProcessRunner(
            output: "Version: ImageMagick 7.2.0-0 Q16-HDRI aarch64"
        )
    )
    let misleadingPrefix = ImageMagickRuntimeAssetTransformer(
        processRunner: StubRuntimeAssetProcessRunner(
            output: "Version: ImageMagick 7.1.2-30 Q16-HDRI aarch64"
        )
    )

    // When / Then
    try supported.validateEnvironment()
    #expect(throws: RuntimeAssetOptimizationError.self) {
        try unsupported.validateEnvironment()
    }
    #expect(throws: RuntimeAssetOptimizationError.self) {
        try misleadingPrefix.validateEnvironment()
    }
}

@Test
func testGivenRepositoryOptimizationPlanWhenComparedWithManifestThenPoliciesMatch() throws {
    // Given
    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["Scripts/Resources/runtime_asset_manifest.json"]
    )
    let plan = RuntimeAssetOptimizationPlanBuilder.make(repositoryRoot: repositoryRoot)
    let manifest = try AssetAuditWorkflow.loadManifest(repositoryRoot: repositoryRoot)

    // When
    let issues = RuntimeAssetOptimizationPlanValidator.issues(in: plan, manifest: manifest)

    // Then
    #expect(issues.isEmpty, Comment(rawValue: issues.joined(separator: "\n")))
}

@Test
func testGivenOptimizationPlanWhenDryRunningThenFilesAndTransformerRemainUntouched() throws {
    // Given
    let fixture = try OptimizationFixture()
    defer { fixture.remove() }
    let transformer = CopyingRuntimeAssetTransformer()
    let plan = fixture.plan

    // When
    try RuntimeAssetOptimizationWorkflow.run(
        plan: plan,
        repositoryRoot: fixture.root,
        options: RuntimeAssetOptimizationOptions(mode: .dryRun),
        transformer: transformer
    )

    // Then
    #expect(transformer.renderCount == 0)
    #expect(FileManager.default.fileExists(atPath: fixture.outputImage.path) == false)
    #expect(FileManager.default.fileExists(atPath: fixture.obsolete.path))
}

@Test
func testGivenOptimizationPlanWhenApplyingThenJSONIsDeterministicAndSourcesStayImmutable() throws {
    // Given
    let fixture = try OptimizationFixture()
    defer { fixture.remove() }
    let transformer = CopyingRuntimeAssetTransformer()
    let sourceBefore = try Data(contentsOf: fixture.source)

    // When
    try RuntimeAssetOptimizationWorkflow.run(
        plan: fixture.plan,
        repositoryRoot: fixture.root,
        options: RuntimeAssetOptimizationOptions(mode: .apply),
        transformer: transformer
    )
    let firstJSON = try Data(contentsOf: fixture.contentsJSON)
    try RuntimeAssetOptimizationWorkflow.run(
        plan: fixture.plan,
        repositoryRoot: fixture.root,
        options: RuntimeAssetOptimizationOptions(mode: .apply),
        transformer: transformer
    )
    let secondJSON = try Data(contentsOf: fixture.contentsJSON)

    // Then
    #expect(firstJSON == secondJSON)
    #expect(try Data(contentsOf: fixture.source) == sourceBefore)
    #expect(FileManager.default.fileExists(atPath: fixture.obsolete.path) == false)
    #expect(FileManager.default.fileExists(atPath: fixture.outputImage.path))
}

@Test
func testGivenTransformFailureWhenApplyingThenExistingCatalogFilesRemainUntouched() throws {
    // Given
    let fixture = try OptimizationFixture()
    defer { fixture.remove() }
    try FileManager.default.createDirectory(
        at: fixture.outputDirectory,
        withIntermediateDirectories: true
    )
    let original = Data("approved-runtime-pixels".utf8)
    try original.write(to: fixture.outputImage)

    // When / Then
    #expect(throws: IntentionalTransformFailure.self) {
        try RuntimeAssetOptimizationWorkflow.run(
            plan: fixture.plan,
            repositoryRoot: fixture.root,
            options: RuntimeAssetOptimizationOptions(mode: .apply),
            transformer: FailingRuntimeAssetTransformer()
        )
    }
    #expect(try Data(contentsOf: fixture.outputImage) == original)
    #expect(FileManager.default.fileExists(atPath: fixture.obsolete.path))
}

@Test
func testGivenCommitFailureWhenApplyingThenEveryRepositoryMutationIsRolledBack() throws {
    // Given
    let fixture = try OptimizationFixture()
    defer { fixture.remove() }
    try FileManager.default.createDirectory(
        at: fixture.outputDirectory,
        withIntermediateDirectories: true
    )
    let original = Data("approved-runtime-pixels".utf8)
    try original.write(to: fixture.outputImage)
    let missingAtCommit = fixture.outputDirectory.appending(path: "second-iphone.png")
    let plan = RuntimeAssetOptimizationPlan(actions: [
        .clearPNGs(directory: "Catalog/Fixture.imageset"),
        .render(
            source: fixture.source,
            destination: "Catalog/Fixture.imageset/fixture-iphone.png",
            maximumLongEdge: 100
        ),
        .render(
            source: fixture.source,
            destination: "Catalog/Fixture.imageset/second-iphone.png",
            maximumLongEdge: 100
        ),
        .remove(path: "Catalog/Obsolete.imageset"),
    ])

    // When / Then
    #expect(throws: (any Error).self) {
        try RuntimeAssetOptimizationWorkflow.run(
            plan: plan,
            repositoryRoot: fixture.root,
            options: RuntimeAssetOptimizationOptions(mode: .apply),
            transformer: RemovingGeneratedFileTransformer(filenameToRemove: missingAtCommit.lastPathComponent)
        )
    }
    #expect(try Data(contentsOf: fixture.outputImage) == original)
    #expect(FileManager.default.fileExists(atPath: fixture.obsolete.path))
    #expect(FileManager.default.fileExists(atPath: missingAtCommit.path) == false)
}

@Test
func testGivenDuplicateGeneratedDestinationWhenValidatingThenReadableIssueIsReturned() {
    // Given
    let destination = "RetroRacing/RetroRacingShared/Assets.xcassets/Test.imageset/test.png"
    let plan = RuntimeAssetOptimizationPlan(actions: [
        .render(source: URL(fileURLWithPath: "/tmp/a.png"), destination: destination, maximumLongEdge: 10),
        .render(source: URL(fileURLWithPath: "/tmp/b.png"), destination: destination, maximumLongEdge: 10),
    ])
    let manifest = RuntimeAssetManifest(schemaVersion: 2, compiledCatalogBudgets: [], assets: [])

    // When
    let issues = RuntimeAssetOptimizationPlanValidator.issues(in: plan, manifest: manifest)

    // Then
    #expect(issues.contains("Optimizer generates destination more than once: \(destination)"))
}

@Test
func testGivenAppliedOptimizationPlanWhenCheckingThenDriftIsDetectedWithoutMutation() throws {
    // Given
    let fixture = try OptimizationFixture()
    defer { fixture.remove() }
    let transformer = CopyingRuntimeAssetTransformer()
    try RuntimeAssetOptimizationWorkflow.run(
        plan: fixture.plan,
        repositoryRoot: fixture.root,
        options: RuntimeAssetOptimizationOptions(mode: .apply),
        transformer: transformer
    )
    let sourceBefore = try Data(contentsOf: fixture.source)

    // When / Then
    try RuntimeAssetOptimizationWorkflow.run(
        plan: fixture.plan,
        repositoryRoot: fixture.root,
        options: RuntimeAssetOptimizationOptions(mode: .check),
        transformer: transformer
    )
    #expect(try Data(contentsOf: fixture.source) == sourceBefore)

    try Data("drift".utf8).write(to: fixture.outputImage)
    #expect(throws: RuntimeAssetOptimizationError.self) {
        try RuntimeAssetOptimizationWorkflow.run(
            plan: fixture.plan,
            repositoryRoot: fixture.root,
            options: RuntimeAssetOptimizationOptions(mode: .check),
            transformer: transformer
        )
    }
}

private final class CopyingRuntimeAssetTransformer: RuntimeAssetImageTransforming {
    private(set) var renderCount = 0

    func render(source: URL, destination: URL, maximumLongEdge: Int) throws {
        renderCount += 1
        try copy(source: source, destination: destination)
    }

    func convertTo8Bit(source: URL, destination: URL) throws {
        try copy(source: source, destination: destination)
    }

    func imagesArePixelEquivalent(_ lhs: URL, _ rhs: URL) throws -> Bool {
        try Data(contentsOf: lhs) == Data(contentsOf: rhs)
    }

    func imageIs8BitRGBA(_ image: URL) throws -> Bool { true }

    private func copy(source: URL, destination: URL) throws {
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
    }
}

private struct StubRuntimeAssetProcessRunner: RuntimeAssetProcessRunning {
    let output: String

    func run(executable: String, arguments: [String]) throws -> String { output }
}

private enum IntentionalTransformFailure: Error {
    case failed
}

private struct FailingRuntimeAssetTransformer: RuntimeAssetImageTransforming {
    func render(source: URL, destination: URL, maximumLongEdge: Int) throws {
        throw IntentionalTransformFailure.failed
    }

    func convertTo8Bit(source: URL, destination: URL) throws {
        throw IntentionalTransformFailure.failed
    }

    func imagesArePixelEquivalent(_ lhs: URL, _ rhs: URL) throws -> Bool { false }
    func imageIs8BitRGBA(_ image: URL) throws -> Bool { false }
}

private final class RemovingGeneratedFileTransformer: RuntimeAssetImageTransforming {
    private let filenameToRemove: String

    init(filenameToRemove: String) {
        self.filenameToRemove = filenameToRemove
    }

    func render(source: URL, destination: URL, maximumLongEdge: Int) throws {
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(at: source, to: destination)
        if destination.lastPathComponent == filenameToRemove {
            try FileManager.default.removeItem(at: destination)
        }
    }

    func convertTo8Bit(source: URL, destination: URL) throws {}
    func imagesArePixelEquivalent(_ lhs: URL, _ rhs: URL) throws -> Bool { false }
    func imageIs8BitRGBA(_ image: URL) throws -> Bool { true }
}

private struct OptimizationFixture {
    let root: URL
    let source: URL
    let outputDirectory: URL
    let outputImage: URL
    let contentsJSON: URL
    let obsolete: URL
    let plan: RuntimeAssetOptimizationPlan

    init() throws {
        root = FileManager.default.temporaryDirectory.appending(
            path: "RuntimeAssetOptimizationFixture-\(UUID().uuidString)"
        )
        source = root.appending(path: "AssetSources/Snapshot/source.png")
        outputDirectory = root.appending(path: "Catalog/Fixture.imageset")
        outputImage = outputDirectory.appending(path: "fixture-iphone.png")
        contentsJSON = outputDirectory.appending(path: "Contents.json")
        obsolete = root.appending(path: "Catalog/Obsolete.imageset")
        try FileManager.default.createDirectory(
            at: source.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(at: obsolete, withIntermediateDirectories: true)
        try Data("source-pixels".utf8).write(to: source)
        try Data("old".utf8).write(to: obsolete.appending(path: "old.png"))

        let relativeDirectory = "Catalog/Fixture.imageset"
        plan = RuntimeAssetOptimizationPlan(actions: [
            .clearPNGs(directory: relativeDirectory),
            .render(
                source: source,
                destination: "\(relativeDirectory)/fixture-iphone.png",
                maximumLongEdge: 100
            ),
            .writeContents(
                destination: "\(relativeDirectory)/Contents.json",
                contents: AssetCatalogContents(
                    images: [
                        AssetCatalogImage(
                            filename: "fixture-iphone.png",
                            idiom: "iphone"
                        )
                    ],
                    info: AssetCatalogInfo(author: "xcode", version: 1)
                )
            ),
            .remove(path: "Catalog/Obsolete.imageset"),
        ])
    }

    func remove() {
        try? FileManager.default.removeItem(at: root)
    }
}
