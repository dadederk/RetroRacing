//
//  ScriptSupportTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import Testing
@testable import ScriptSupport

@Test
func givenValueFlagWhenParsingThenValueIsReturned() throws {
    let arguments = CLIArguments(["--destination", "platform=macOS"])

    let value = try arguments.value(after: "--destination")

    #expect(value == "platform=macOS")
}

@Test
func givenUnknownFlagWhenValidatingThenAnErrorIsThrown() {
    let arguments = CLIArguments(["--surprise"])

    #expect(throws: ScriptSupportError.self) {
        try arguments.rejectUnknownFlags(allowing: ["--check"])
    }
}

@Test
func givenNestedDirectoryWhenLocatingThenRepositoryRootIsFound() throws {
    let temporaryRoot = FileManager.default.temporaryDirectory.appending(
        path: UUID().uuidString
    )
    let nestedDirectory = temporaryRoot.appending(path: "one/two")
    let marker = temporaryRoot.appending(path: "marker.txt")
    try FileManager.default.createDirectory(
        at: nestedDirectory,
        withIntermediateDirectories: true
    )
    try Data().write(to: marker)
    defer { try? FileManager.default.removeItem(at: temporaryRoot) }

    let locatedRoot = try RepositoryLocator.locate(
        containing: ["marker.txt"],
        startingAt: nestedDirectory
    )

    #expect(locatedRoot.standardizedFileURL.path == temporaryRoot.standardizedFileURL.path)
}

@Test
func givenCommandWithWhitespaceWhenRenderingThenArgumentsAreQuoted() {
    let command = ProcessCommand(
        executable: "/usr/bin/tool",
        arguments: ["plain", "two words"]
    )

    #expect(command.rendered == "/usr/bin/tool plain 'two words'")
}

@Test
func givenRepeatedValueFlagWhenParsingThenAllValuesAreReturned() {
    let arguments = CLIArguments([
        "--only-testing", "A", "--only-testing", "B",
    ])

    #expect(arguments.values(for: "--only-testing") == ["A", "B"])
}
