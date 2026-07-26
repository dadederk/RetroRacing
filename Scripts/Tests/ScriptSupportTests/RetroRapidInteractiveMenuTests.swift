//
//  RetroRapidInteractiveMenuTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/07/2026.
//

import Foundation
import Testing

@testable import ScriptSupport

@Test
func givenCIEnvironmentWhenShouldUseInteractiveMenuThenReturnsFalse() {
    setenv("CI", "true", 1)
    defer { unsetenv("CI") }
    #expect(RetroRapidInteractiveMenu.shouldUseInteractiveMenu(isatty: { _ in 1 }) == false)
}

@Test
func givenInteractiveTTYWhenShouldUseInteractiveMenuThenReturnsTrue() {
    unsetenv("CI")
    #expect(RetroRapidInteractiveMenu.shouldUseInteractiveMenu(isatty: { _ in 1 }) == true)
}

@Test
func givenVerifySelectionWhenChoosingCheckThenUsesCheckRecipe() throws {
    let repositoryRoot = URL(fileURLWithPath: "/tmp/RetroRacing", isDirectory: true)
    var executed: ScriptDispatchPlan?
    var output: [String] = []
    var reads = ["1", "1", "check", "y"]
    try RetroRapidInteractiveMenu.run(
        repositoryRoot: repositoryRoot,
        readLine: {
            guard !reads.isEmpty else { return nil }
            return reads.removeFirst()
        },
        write: { output.append($0) },
        execute: { plan, _ in executed = plan }
    )
    #expect(executed == .runCheckRecipe)
    #expect(output.contains(where: { $0.contains("Will run:") }))
}

@Test
func givenQuitSelectionWhenRunningMenuThenExitsWithoutExecuting() throws {
    let repositoryRoot = URL(fileURLWithPath: "/tmp/RetroRacing", isDirectory: true)
    var executed = false
    try RetroRapidInteractiveMenu.run(
        repositoryRoot: repositoryRoot,
        readLine: { "q" },
        write: { _ in },
        execute: { _, _ in executed = true }
    )
    #expect(executed == false)
}
