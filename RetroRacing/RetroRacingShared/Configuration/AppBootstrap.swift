//
//  AppBootstrap.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import Foundation
import AVFoundation
import GameKit

/// Shared bootstrapping helpers for app targets.
public enum AppBootstrap {
    #if canImport(UIKit) && !os(watchOS)
    private static let audioSessionObserver = AudioSessionObserver()
    #endif
    #if os(watchOS)
    private static let watchAudioSessionObserver = WatchAudioSessionObserver()
    #endif
    #if canImport(UIKit) || os(watchOS)
    private static var audioSessionActivationTask: Task<Void, Never>?
    #endif

    /// Configures access point location but keeps it hidden; the app presents Game Center explicitly.
    public static func configureGameCenterAccessPoint() {
        #if canImport(UIKit) && !os(watchOS)
        GKAccessPoint.shared.location = .topTrailing
        GKAccessPoint.shared.isActive = false
        #endif
    }

    /// Configures audio session so game sounds play on device.
    public static func configureAudioSession() {
        #if canImport(UIKit) && !os(watchOS)
        audioSessionObserver.startObserving()
        requestAudioSessionActivation()
        #elseif os(watchOS)
        watchAudioSessionObserver.startObserving()
        requestAudioSessionActivation()
        #endif
    }

    /// Configures the audio session and waits for the current activation attempt to finish.
    public static func configureAudioSessionAndWait() async {
        configureAudioSession()
        #if canImport(UIKit) || os(watchOS)
        await audioSessionActivationTask?.value
        #endif
    }

    /// Registers the custom font from the shared framework so `.font(.custom("PressStart2P-Regular", size:))` works.
    /// - Returns: true if registration succeeded.
    @discardableResult
    public static func registerCustomFont() -> Bool {
        FontRegistrar.registerPressStart2P(additionalBundles: [Bundle.main])
    }

    #if canImport(UIKit) && !os(watchOS)
    fileprivate static func activateAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try await AVAudioSessionActivation.activate(session)
    }
    #endif

    #if os(watchOS)
    fileprivate static func activateWatchAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        // Prefer exclusive playback on watchOS to avoid mixed/ducked output unexpectedly muting short SFX.
        try session.setCategory(.playback, mode: .default, options: [])
        try await AVAudioSessionActivation.activate(session)
    }
    #endif

    #if canImport(UIKit) || os(watchOS)
    fileprivate static func requestAudioSessionActivation(trigger: String? = nil) {
        guard audioSessionActivationTask == nil else { return }

        audioSessionActivationTask = Task {
            defer { audioSessionActivationTask = nil }

            do {
                #if os(watchOS)
                try await activateWatchAudioSession()
                #else
                try await activateAudioSession()
                #endif
                logAudioSessionActivation(outcome: .succeeded, trigger: trigger)
            } catch {
                logAudioSessionActivation(outcome: .failed, trigger: trigger, error: error)
            }
        }
    }

    private static func logAudioSessionActivation(
        outcome: AppLog.Outcome,
        trigger: String?,
        error: Error? = nil
    ) {
        var fields: [AppLog.Field] = [
            .string("platform", audioSessionPlatformName)
        ]
        if let trigger {
            fields.append(.string("trigger", trigger))
        }

        #if os(watchOS)
        if outcome == .succeeded {
            let session = AVAudioSession.sharedInstance()
            let routeDescription = session.currentRoute.outputs
                .map { "\($0.portType.rawValue):\($0.portName)" }
                .joined(separator: ",")
            fields.append(.double("outputVolume", Double(session.outputVolume)))
            fields.append(.string("route", routeDescription))
        }
        #endif

        if let error {
            fields.append(.reason("activation_failed"))
            fields.append(contentsOf: AppLog.Field.error(error))
            if trigger == nil {
                AppLog.error(
                    AppLog.sound,
                    "AUDIO_SESSION_ACTIVATION",
                    outcome: outcome,
                    fields: fields
                )
            } else {
                AppLog.error(
                    AppLog.sound,
                    "AUDIO_SESSION_REACTIVATION",
                    outcome: outcome,
                    fields: fields
                )
            }
        } else {
            if trigger == nil {
                AppLog.info(
                    AppLog.sound,
                    "AUDIO_SESSION_ACTIVATION",
                    outcome: outcome,
                    fields: fields
                )
            } else {
                AppLog.info(
                    AppLog.sound,
                    "AUDIO_SESSION_REACTIVATION",
                    outcome: outcome,
                    fields: fields
                )
            }
        }
    }

    private static var audioSessionPlatformName: String {
        #if os(watchOS)
        "watchos"
        #elseif os(tvOS)
        "tvos"
        #elseif os(visionOS)
        "visionos"
        #else
        "ios"
        #endif
    }
    #endif
}

#if canImport(UIKit) && !os(watchOS)
private final class AudioSessionObserver: NSObject {
    private var isObserving = false

    func startObserving() {
        guard isObserving == false else { return }
        isObserving = true
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleMediaServicesReset(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
        guard type == .ended else { return }
        reactivateAudioSession(reason: "interruption ended")
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        reactivateAudioSession(reason: "route change")
    }

    @objc private func handleMediaServicesReset(_ notification: Notification) {
        reactivateAudioSession(reason: "media services reset")
    }

    private func reactivateAudioSession(reason: String) {
        AppBootstrap.requestAudioSessionActivation(trigger: reason)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
#endif

#if os(watchOS)
private final class WatchAudioSessionObserver {
    private var isObserving = false
    private var observerTokens: [NSObjectProtocol] = []

    func startObserving() {
        guard isObserving == false else { return }
        isObserving = true

        let center = NotificationCenter.default
        observerTokens.append(
            center.addObserver(
                forName: AVAudioSession.interruptionNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleInterruption(notification)
            }
        )
        observerTokens.append(
            center.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reactivateAudioSession(reason: "route change")
            }
        )
        observerTokens.append(
            center.addObserver(
                forName: AVAudioSession.mediaServicesWereResetNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.reactivateAudioSession(reason: "media services reset")
            }
        )
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let rawType = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawType) else { return }
        guard type == .ended else { return }
        reactivateAudioSession(reason: "interruption ended")
    }

    private func reactivateAudioSession(reason: String) {
        AppBootstrap.requestAudioSessionActivation(trigger: reason)
    }

    deinit {
        let center = NotificationCenter.default
        for token in observerTokens {
            center.removeObserver(token)
        }
    }
}
#endif
