//
//  LoggingContractTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 21/04/2026.
//

import Foundation
import XCTest
@testable import RetroRacingShared

final class LoggingContractTests: XCTestCase {
    func testGivenStructuredLogWhenFormattingThenCanonicalShapeIsProduced() {
        // Given
        let domains = AppLog.DomainSelection(primary: .leaderboard, secondary: .lifecycle)
        let fields: [AppLog.Field] = [
            .reason("player_not_authenticated"),
            .int("score", 140)
        ]

        // When
        let message = AppLog.formatMessageForTesting(
            domains: domains,
            event: "Score submit",
            outcome: .blocked,
            fields: fields
        )

        // Then
        XCTAssertEqual(
            message,
            "🏆📱 LEADERBOARD SCORE_SUBMIT: outcome=blocked reason=PLAYER_NOT_AUTHENTICATED score=140"
        )
    }

    func testGivenOutcomeAndFieldsWhenFormattingThenOutcomeComesFirst() {
        // Given
        let domains = AppLog.DomainSelection(primary: .game)
        let fields: [AppLog.Field] = [
            .string("speed", "rapid"),
            .int("score", 42)
        ]

        // When
        let message = AppLog.formatMessageForTesting(
            domains: domains,
            event: "score submit",
            outcome: .succeeded,
            fields: fields
        )

        // Then
        XCTAssertTrue(message.contains(": outcome=succeeded speed=rapid score=42"))
    }

    func testGivenSensitiveInputsWhenRedactingThenValuesAreSanitized() {
        // Given
        let url = URL(string: "https://example.com/private/path/to/resource")
        let path = "/Users/example/private/data/file.txt"

        // When
        let redactedURL = AppLog.redactedURL(url)
        let redactedPath = AppLog.redactedPath(path)
        let redactedPlayer = AppLog.redactedPlayer("Very Sensitive Player")

        // Then
        XCTAssertFalse(redactedURL.contains("https://"))
        XCTAssertFalse(redactedPath.contains("/Users/example"))
        XCTAssertEqual(redactedPlayer, "len_21")
    }

    func testGivenExpandedDomainSetWhenFormattingThenEmojiAndDomainTokenAreStable() {
        // Given
        let domains = AppLog.DomainSelection(primary: .input, secondary: .game)

        // When
        let message = AppLog.formatMessageForTesting(domains: domains, event: "move left")

        // Then
        XCTAssertEqual(message, "🎛️🎮 INPUT MOVE_LEFT:")
    }

    func testGivenRuntimeSourceWhenScanningThenLegacyLogAPIIsNotUsed() throws {
        // Given
        let files = try runtimeSwiftFiles()

        // When
        let offenders = try files.filter { fileURL in
            let content = try String(contentsOf: fileURL)
            return content.contains("AppLog.log(")
        }

        // Then
        XCTAssertTrue(offenders.isEmpty, "Found AppLog.log usage in: \(offenders)")
    }

    func testGivenRuntimeSourceWhenScanningThenInlineEmojiPrefixesAreNotUsedInLogCalls() throws {
        // Given
        let files = try runtimeSwiftFiles()
        let emojiPattern = #"[🖼️🔊🔤🌐🎨🎮🏆🏅💰🎛️♿📱🛒⭐🔐✅🚫⌛️⏸️🔄]"#

        // When
        var offenders = [String]()
        for fileURL in files {
            let content = try String(contentsOf: fileURL)
            let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() {
                guard line.contains("AppLog."), line.contains("\"") else { continue }
                if line.range(of: emojiPattern, options: .regularExpression) != nil {
                    offenders.append("\(fileURL.lastPathComponent):\(index + 1)")
                }
            }
        }

        // Then
        XCTAssertTrue(offenders.isEmpty, "Found inline emoji log strings: \(offenders)")
    }

    func testGivenRuntimeSourceWhenScanningThenRawSensitiveFieldsAreNotLogged() throws {
        // Given
        let files = try runtimeSwiftFiles()

        // When
        var offenders = [String]()
        for fileURL in files {
            let content = try String(contentsOf: fileURL)
            let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() {
                guard line.contains("AppLog.") else { continue }

                let lineText = String(line)
                if lineText.contains("absoluteString") && lineText.contains("redactedURL") == false {
                    offenders.append("\(fileURL.lastPathComponent):\(index + 1) absoluteString")
                }
                if lineText.contains("displayName") && lineText.contains("redactedPlayer") == false {
                    offenders.append("\(fileURL.lastPathComponent):\(index + 1) displayName")
                }
                if lineText.contains("userInfo") {
                    offenders.append("\(fileURL.lastPathComponent):\(index + 1) userInfo")
                }
            }
        }

        // Then
        XCTAssertTrue(offenders.isEmpty, "Found non-redacted sensitive log payloads: \(offenders)")
    }

    func testGivenRuntimeSourceWhenScanningThenLogEventArgumentsUseStringLiterals() throws {
        // Given
        let files = try runtimeSwiftFiles()
        let invocationPattern = #"AppLog\.(debug|info|warning|error|critical)\s*\(\s*[^,]+,\s*(?!")\S"#
        let invocationRegex = try NSRegularExpression(
            pattern: invocationPattern,
            options: [.dotMatchesLineSeparators]
        )

        // When
        var offenders = [String]()
        for fileURL in files {
            let content = try String(contentsOf: fileURL)
            let nsContent = content as NSString
            let fullRange = NSRange(location: 0, length: nsContent.length)
            let matches = invocationRegex.matches(in: content, options: [], range: fullRange)

            for match in matches {
                offenders.append("\(fileURL.lastPathComponent):\(lineNumber(in: content, utf16Location: match.range.location))")
            }
        }

        // Then
        XCTAssertTrue(offenders.isEmpty, "Found non-literal log event arguments: \(offenders)")
    }

    func testGivenRuntimeSourceWhenScanningThenLogEventNamesUseUpperSnakeCase() throws {
        // Given
        let files = try runtimeSwiftFiles()
        let eventPattern = #"AppLog\.(debug|info|warning|error|critical)\s*\(\s*[^,]+,\s*"([^"]+)""#
        let eventRegex = try NSRegularExpression(
            pattern: eventPattern,
            options: [.dotMatchesLineSeparators]
        )

        // When
        var offenders = [String]()
        for fileURL in files {
            let content = try String(contentsOf: fileURL)
            let nsContent = content as NSString
            let fullRange = NSRange(location: 0, length: nsContent.length)
            let matches = eventRegex.matches(in: content, options: [], range: fullRange)

            for match in matches {
                guard match.numberOfRanges > 2 else { continue }
                let eventValue = nsContent.substring(with: match.range(at: 2))
                if eventValue.range(of: #"^[A-Z0-9_]+$"#, options: .regularExpression) == nil {
                    offenders.append(
                        "\(fileURL.lastPathComponent):\(lineNumber(in: content, utf16Location: match.range(at: 2).location))=\(eventValue)"
                    )
                }
            }
        }

        // Then
        XCTAssertTrue(offenders.isEmpty, "Found non-canonical event names: \(offenders)")
    }

    private func runtimeSwiftFiles() throws -> [URL] {
        let root = repositoryRoot()
        let excludedSuffixes = [
            "/RetroRacingSharedTests/",
            "/RetroRacingUniversalTests/",
            "/RetroRacingWatchOSTests/",
            "/RetroRacingUITests/"
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else {
            throw NSError(domain: "LoggingContractTests", code: 1)
        }

        var files = [URL]()
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "swift" else { continue }
            let path = fileURL.path
            if excludedSuffixes.contains(where: { path.contains($0) }) { continue }
            if path.hasSuffix("/AppLog.swift") { continue }
            files.append(fileURL)
        }
        return files
    }

    private func repositoryRoot() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func lineNumber(in content: String, utf16Location: Int) -> Int {
        let nsContent = content as NSString
        let boundedLocation = max(0, min(utf16Location, nsContent.length))
        let prefix = nsContent.substring(to: boundedLocation)
        return prefix.reduce(1) { partialResult, character in
            character == "\n" ? partialResult + 1 : partialResult
        }
    }
}
