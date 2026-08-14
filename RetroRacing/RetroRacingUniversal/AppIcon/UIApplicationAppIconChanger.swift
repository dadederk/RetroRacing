//
//  UIApplicationAppIconChanger.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 13/08/2026.
//

#if os(iOS)
import RetroRacingShared
import UIKit

@MainActor
protocol UIApplicationAppIconChanging: AnyObject {
    var supportsAlternateIcons: Bool { get }
    var alternateIconName: String? { get }
    var applicationState: UIApplication.State { get }

    func setAlternateIconName(
        _ alternateIconName: String?,
        completionHandler: (@MainActor @Sendable (Error?) -> Void)?
    )
}

enum UIApplicationAppIconChangerError: Error, Equatable {
    case applicationUnavailable
    case systemStateTimedOut
}

/// Resolves UIKit's application singleton lazily because it is not yet available
/// while SwiftUI constructs the `App` value.
@MainActor
final class SharedUIApplicationAppIconProxy: UIApplicationAppIconChanging {
    private var application: UIApplication? {
        UIApplication.shared
    }

    var supportsAlternateIcons: Bool {
        application?.supportsAlternateIcons ?? false
    }

    var alternateIconName: String? {
        application?.alternateIconName
    }

    var applicationState: UIApplication.State {
        application?.applicationState ?? .inactive
    }

    func setAlternateIconName(
        _ alternateIconName: String?,
        completionHandler: (@MainActor @Sendable (Error?) -> Void)?
    ) {
        guard let application else {
            completionHandler?(UIApplicationAppIconChangerError.applicationUnavailable)
            return
        }
        application.setAlternateIconName(alternateIconName) { error in
            Task { @MainActor in
                completionHandler?(error)
            }
        }
    }
}

/// UIKit implementation of RetroRapid's persistent alternate-icon boundary.
@MainActor
final class UIApplicationAppIconChanger: AppIconChanging {
    private enum RequestResolution: String {
        case systemState = "system_state_confirmed"
        case systemCompletion = "system_completion_succeeded"
    }

    @MainActor
    private final class RequestCompletion {
        enum State {
            case pending
            case succeeded
            case failed(Error)
        }

        private(set) var state: State = .pending

        func resolve(with error: Error?) {
            if let error {
                state = .failed(error)
            } else {
                state = .succeeded
            }
        }
    }

    private let application: any UIApplicationAppIconChanging
    private let systemStatePollInterval: Duration
    private let maximumActiveSystemStatePollCount: Int
    private let maximumCompletionStatePollCount: Int
    private let wait: @MainActor @Sendable (Duration) async throws -> Void

    var supportsAlternateIcons: Bool {
        application.supportsAlternateIcons
    }

    var alternateIconName: String? {
        application.alternateIconName
    }

    init(
        application: any UIApplicationAppIconChanging,
        systemStatePollInterval: Duration = .milliseconds(200),
        maximumActiveSystemStatePollCount: Int = 50,
        maximumCompletionStatePollCount: Int = 5,
        wait: @escaping @MainActor @Sendable (Duration) async throws -> Void = {
            try await Task.sleep(for: $0)
        }
    ) {
        self.application = application
        self.systemStatePollInterval = systemStatePollInterval
        self.maximumActiveSystemStatePollCount = maximumActiveSystemStatePollCount
        self.maximumCompletionStatePollCount = maximumCompletionStatePollCount
        self.wait = wait
    }

    func setAlternateIconName(_ alternateIconName: String?) async throws {
        let requestedIcon = alternateIconName ?? AppIconID.classic.rawValue
        AppLog.info(
            AppLog.assets + AppLog.lifecycle,
            "APP_ICON_SYSTEM_REQUEST",
            outcome: .requested,
            fields: systemFields(requestedIcon: requestedIcon)
        )

        do {
            let resolution = try await requestAlternateIconName(alternateIconName)
            AppLog.info(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_SYSTEM_REQUEST",
                outcome: .succeeded,
                fields: [.reason(resolution.rawValue)]
                    + systemFields(requestedIcon: requestedIcon)
            )
        } catch {
            AppLog.error(
                AppLog.assets + AppLog.lifecycle,
                "APP_ICON_SYSTEM_REQUEST",
                outcome: .failed,
                fields: [.reason("uikit_request_failed")]
                    + systemFields(requestedIcon: requestedIcon)
                    + AppLog.Field.error(error)
            )
            throw error
        }
    }

    private func requestAlternateIconName(
        _ alternateIconName: String?
    ) async throws -> RequestResolution {
        let completion = RequestCompletion()
        application.setAlternateIconName(alternateIconName) { error in
            completion.resolve(with: error)
        }

        var activePollCount = 0
        var completionPollCount = 0
        while true {
            // UIKit's completion can be withheld while the icon has already changed.
            // The documented system state is authoritative, including for Classic (`nil`).
            if application.alternateIconName == alternateIconName {
                return .systemState
            }

            // Apple's confirmation can keep the app inactive for an arbitrary amount of time.
            // Only active time consumes the bounded recovery budget.
            if application.applicationState == .active {
                switch completion.state {
                case .pending:
                    activePollCount += 1
                    if activePollCount >= maximumActiveSystemStatePollCount {
                        throw UIApplicationAppIconChangerError.systemStateTimedOut
                    }
                case .succeeded:
                    completionPollCount += 1
                    if completionPollCount >= maximumCompletionStatePollCount {
                        return .systemCompletion
                    }
                case .failed(let error):
                    completionPollCount += 1
                    if completionPollCount >= maximumCompletionStatePollCount {
                        throw error
                    }
                }
            }

            try await wait(systemStatePollInterval)
        }
    }

    private func systemFields(requestedIcon: String) -> [AppLog.Field] {
        [
            .string("requestedSystemIcon", requestedIcon),
            .string("reportedSystemIcon", application.alternateIconName ?? AppIconID.classic.rawValue),
            .bool("systemSupported", application.supportsAlternateIcons),
            .int("applicationState", application.applicationState.rawValue),
        ]
    }
}
#endif
