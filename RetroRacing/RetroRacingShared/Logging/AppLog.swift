//
//  AppLog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import OSLog

/// Canonical structured runtime logging helper for RetroRacing.
///
/// Message shape:
/// `<emoji> <DOMAIN> <EVENT_NAME>: outcome=<state> key=value ...`
public enum AppLog {
    public enum Domain: String, Sendable {
        case assets = "ASSETS"
        case sound = "SOUND"
        case font = "FONT"
        case localization = "LOCALIZATION"
        case theme = "THEME"
        case game = "GAME"
        case leaderboard = "LEADERBOARD"
        case achievement = "ACHIEVEMENT"
        case monetization = "MONETIZATION"
        case input = "INPUT"
        case accessibility = "ACCESSIBILITY"
        case lifecycle = "LIFECYCLE"
        case store = "STORE"
        case rating = "RATING"

        var emoji: String {
            switch self {
            case .assets: "🖼️"
            case .sound: "🔊"
            case .font: "🔤"
            case .localization: "🌐"
            case .theme: "🎨"
            case .game: "🎮"
            case .leaderboard: "🏆"
            case .achievement: "🏅"
            case .monetization: "💰"
            case .input: "🎛️"
            case .accessibility: "♿"
            case .lifecycle: "📱"
            case .store: "🛒"
            case .rating: "⭐"
            }
        }
    }

    public struct DomainSelection: Sendable {
        public let primary: Domain
        public let secondary: Domain?

        public init(primary: Domain, secondary: Domain? = nil) {
            self.primary = primary
            self.secondary = secondary
        }

        fileprivate var emoji: String {
            if let secondary {
                return primary.emoji + secondary.emoji
            }
            return primary.emoji
        }

        fileprivate var token: String {
            primary.rawValue
        }
    }

    public enum Outcome: String, Sendable {
        case requested
        case started
        case succeeded
        case completed
        case failed
        case blocked
        case ignored
        case skipped
        case deferred
        case cancelled
    }

    public struct Field: Sendable {
        fileprivate let key: String
        fileprivate let value: String

        public init(_ key: String, _ value: String) {
            self.key = Self.normalizedKey(key)
            self.value = Self.normalizedValue(value)
        }

        public static func string(_ key: String, _ value: String?) -> Field {
            Field(key, value ?? "nil")
        }

        public static func bool(_ key: String, _ value: Bool) -> Field {
            Field(key, value ? "true" : "false")
        }

        public static func int(_ key: String, _ value: Int) -> Field {
            Field(key, String(value))
        }

        public static func int64(_ key: String, _ value: Int64) -> Field {
            Field(key, String(value))
        }

        public static func double<T: BinaryFloatingPoint>(_ key: String, _ value: T, precision: Int = 3) -> Field {
            let formatted = String(format: "%0.*f", precision, Double(value))
            return Field(key, formatted)
        }

        public static func reason(_ value: String) -> Field {
            Field("reason", Self.normalizedToken(value))
        }

        public static func error(_ error: Error) -> [Field] {
            let nsError = error as NSError
            return [
                .string("errorDomain", nsError.domain),
                .int("errorCode", nsError.code),
                .string("errorDescription", nsError.localizedDescription)
            ]
        }

        private static func normalizedKey(_ input: String) -> String {
            let rawParts = input
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
            guard rawParts.isEmpty == false else { return "field" }

            let first = rawParts[0].lowercased()
            let rest = rawParts.dropFirst().map { part in
                guard let firstCharacter = part.first else { return part }
                return String(firstCharacter).uppercased() + part.dropFirst().lowercased()
            }
            let candidate = ([first] + rest).joined()
            if let firstCharacter = candidate.first, firstCharacter.isNumber {
                return "v\(candidate)"
            }
            return candidate
        }

        private static func normalizedValue(_ input: String) -> String {
            var value = input
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if value.isEmpty {
                return "empty"
            }

            value = value.replacingOccurrences(of: "=", with: "-")
            value = value.replacingOccurrences(of: ":", with: "-")

            let collapsedWhitespace = value.replacingOccurrences(
                of: #"\s+"#,
                with: "_",
                options: .regularExpression
            )

            let sanitizedScalars = collapsedWhitespace.unicodeScalars.map { scalar -> Character in
                if CharacterSet.alphanumerics.contains(scalar) {
                    return Character(scalar)
                }
                switch scalar {
                case "_", "-", ".":
                    return Character(scalar)
                default:
                    return "_"
                }
            }
            let sanitized = String(sanitizedScalars)
                .replacingOccurrences(of: #"_+"#, with: "_", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

            if sanitized.isEmpty {
                return "redacted"
            }
            if sanitized.count > 160 {
                return String(sanitized.prefix(160))
            }
            return sanitized
        }

        private static func normalizedToken(_ input: String) -> String {
            let upper = input.uppercased()
            let sanitized = upper.replacingOccurrences(
                of: #"[^A-Z0-9]+"#,
                with: "_",
                options: .regularExpression
            )
            let collapsed = sanitized
                .replacingOccurrences(of: #"_+"#, with: "_", options: .regularExpression)
                .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
            return collapsed.isEmpty ? "UNSPECIFIED" : collapsed
        }
    }

    public static let assets: Domain = .assets
    public static let sound: Domain = .sound
    public static let font: Domain = .font
    public static let localization: Domain = .localization
    public static let theme: Domain = .theme
    public static let game: Domain = .game
    public static let leaderboard: Domain = .leaderboard
    public static let achievement: Domain = .achievement
    public static let monetization: Domain = .monetization
    public static let input: Domain = .input
    public static let accessibility: Domain = .accessibility
    public static let lifecycle: Domain = .lifecycle
    public static let store: Domain = .store
    public static let rating: Domain = .rating

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.retroracing",
        category: "RetroRacing"
    )

    public static func debug(
        _ domains: DomainSelection,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        emit(level: .debug, domains: domains, event: event, outcome: outcome, fields: fields)
    }

    public static func info(
        _ domains: DomainSelection,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        emit(level: .info, domains: domains, event: event, outcome: outcome, fields: fields)
    }

    public static func warning(
        _ domains: DomainSelection,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        emit(level: .warning, domains: domains, event: event, outcome: outcome, fields: fields)
    }

    public static func error(
        _ domains: DomainSelection,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        emit(level: .error, domains: domains, event: event, outcome: outcome, fields: fields)
    }

    public static func critical(
        _ domains: DomainSelection,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        emit(level: .critical, domains: domains, event: event, outcome: outcome, fields: fields)
    }

    public static func debug(
        _ domain: Domain,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        debug(DomainSelection(primary: domain), event, outcome: outcome, fields: fields)
    }

    public static func info(
        _ domain: Domain,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        info(DomainSelection(primary: domain), event, outcome: outcome, fields: fields)
    }

    public static func warning(
        _ domain: Domain,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        warning(DomainSelection(primary: domain), event, outcome: outcome, fields: fields)
    }

    public static func error(
        _ domain: Domain,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        error(DomainSelection(primary: domain), event, outcome: outcome, fields: fields)
    }

    public static func critical(
        _ domain: Domain,
        _ event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) {
        critical(DomainSelection(primary: domain), event, outcome: outcome, fields: fields)
    }

    public static func shortID(_ id: UUID?) -> String {
        guard let id else { return "nil" }
        return String(id.uuidString.prefix(8)).lowercased()
    }

    public static func redactedURL(_ url: URL?) -> String {
        guard let url else { return "nil" }
        let scheme = url.scheme ?? "unknown"
        let host = url.host ?? "unknownHost"
        let pathComponents = max(0, url.pathComponents.count - 1)
        return Field("url", "scheme_\(scheme)_host_\(host)_pathComponents_\(pathComponents)").value
    }

    public static func redactedPath(_ path: String?) -> String {
        guard let path, path.isEmpty == false else { return "nil" }
        let url = URL(fileURLWithPath: path)
        let components = url.pathComponents.filter { $0.isEmpty == false && $0 != "/" }
        let last = components.last ?? "unknown"
        return Field("path", "components_\(components.count)_last_\(last)").value
    }

    public static func redactedPlayer(_ playerName: String?) -> String {
        guard let playerName, playerName.isEmpty == false else { return "nil" }
        return "len_\(playerName.count)"
    }

    @available(*, unavailable, message: "Use structured AppLog.debug(_:_:outcome:fields:)")
    public static func log(_ emoji: String, _ message: String, file: String = #file, line: Int = #line) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, message: "Use structured AppLog.info(_:_:outcome:fields:)")
    public static func info(_ emoji: String, _ message: String, file: String = #file, line: Int = #line) {
        fatalError("Unavailable")
    }

    @available(*, unavailable, message: "Use structured AppLog.error(_:_:outcome:fields:)")
    public static func error(_ emoji: String, _ message: String, file: String = #file, line: Int = #line) {
        fatalError("Unavailable")
    }

    // MARK: - Internal test utilities

    internal static func formatMessageForTesting(
        domains: DomainSelection,
        event: String,
        outcome: Outcome? = nil,
        fields: [Field] = []
    ) -> String {
        formatMessage(domains: domains, event: event, outcome: outcome, fields: fields)
    }

    // MARK: - Private

    private enum LogLevel {
        case debug
        case info
        case warning
        case error
        case critical
    }

    private static func emit(
        level: LogLevel,
        domains: DomainSelection,
        event: String,
        outcome: Outcome?,
        fields: [Field]
    ) {
        let message = formatMessage(domains: domains, event: event, outcome: outcome, fields: fields)

        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
    }

    private static func formatMessage(
        domains: DomainSelection,
        event: String,
        outcome: Outcome?,
        fields: [Field]
    ) -> String {
        let eventToken = normalizeEventToken(event)
        var parts = [String]()

        if let outcome {
            parts.append("outcome=\(outcome.rawValue)")
        }
        for field in fields {
            parts.append("\(field.key)=\(field.value)")
        }

        let body = parts.joined(separator: " ")
        if body.isEmpty {
            return "\(domains.emoji) \(domains.token) \(eventToken):"
        }
        return "\(domains.emoji) \(domains.token) \(eventToken): \(body)"
    }

    private static func normalizeEventToken(_ input: String) -> String {
        let upper = input.uppercased()
        let sanitized = upper.replacingOccurrences(
            of: #"[^A-Z0-9]+"#,
            with: "_",
            options: .regularExpression
        )
        let collapsed = sanitized
            .replacingOccurrences(of: #"_+"#, with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

        if collapsed.isEmpty {
            return "UNSPECIFIED_EVENT"
        }
        return collapsed
    }
}

public func + (lhs: AppLog.Domain, rhs: AppLog.Domain) -> AppLog.DomainSelection {
    AppLog.DomainSelection(primary: lhs, secondary: rhs)
}
