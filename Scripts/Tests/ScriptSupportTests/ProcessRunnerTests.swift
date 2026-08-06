//
//  ProcessRunnerTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import Testing
@testable import ScriptSupport

@Suite("Process runner")
struct ProcessRunnerTests {
    @Test("Given output larger than a pipe buffer, when captured, then the command completes")
    func givenLargeOutputWhenCapturedThenCommandCompletes() throws {
        let lineCount = 100_000

        let output = try ProcessRunner.run(
            ProcessCommand(
                executable: "/usr/bin/jot",
                arguments: ["-b", "x", String(lineCount)]
            ),
            captureOutput: true,
            timeout: 5
        )

        #expect(output.split(separator: "\n").count == lineCount)
    }
}
