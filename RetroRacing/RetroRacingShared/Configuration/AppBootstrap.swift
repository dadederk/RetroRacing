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
        do {
            try activateAudioSession()
            audioSessionObserver.startObserving()
        } catch {
            // Non-fatal; sound may still work in simulator
        }
        #elseif os(watchOS)
        do {
            try activateWatchAudioSession()
            watchAudioSessionObserver.startObserving()
            let session = AVAudioSession.sharedInstance()
            let routeDescription = session.currentRoute.outputs
                .map { "\($0.portType.rawValue):\($0.portName)" }
                .joined(separator: ",")
            AppLog.info(
                AppLog.sound,
                "🔊 watchOS audio session activated (outputVolume=\(session.outputVolume), route=[\(routeDescription)]; watchOS often reports 0.0)"
            )
        } catch {
            AppLog.error(AppLog.sound, "🔊 watchOS audio session activation failed: \(error.localizedDescription)")
        }
        #endif
    }

    /// Registers the custom font from the shared framework so `.font(.custom("PressStart2P-Regular", size:))` works.
    /// - Returns: true if registration succeeded.
    @discardableResult
    public static func registerCustomFont() -> Bool {
        FontRegistrar.registerPressStart2P(additionalBundles: [Bundle.main])
    }

    #if canImport(UIKit) && !os(watchOS)
    fileprivate static func activateAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }
    #endif

    #if os(watchOS)
    fileprivate static func activateWatchAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        // Prefer exclusive playback on watchOS to avoid mixed/ducked output unexpectedly muting short SFX.
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
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
        do {
            try AppBootstrap.activateAudioSession()
            AppLog.info(AppLog.sound, "🔊 Re-activated audio session after \(reason)")
        } catch {
            AppLog.error(AppLog.sound, "🔊 Failed to reactivate audio session after \(reason): \(error.localizedDescription)")
        }
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
        do {
            try AppBootstrap.activateWatchAudioSession()
            let session = AVAudioSession.sharedInstance()
            let routeDescription = session.currentRoute.outputs
                .map { "\($0.portType.rawValue):\($0.portName)" }
                .joined(separator: ",")
            AppLog.info(
                AppLog.sound,
                "🔊 Re-activated watchOS audio session after \(reason) (outputVolume=\(session.outputVolume), route=[\(routeDescription)]; watchOS often reports 0.0)"
            )
        } catch {
            AppLog.error(
                AppLog.sound,
                "🔊 Failed to reactivate watchOS audio session after \(reason): \(error.localizedDescription)"
            )
        }
    }

    deinit {
        let center = NotificationCenter.default
        for token in observerTokens {
            center.removeObserver(token)
        }
    }
}
#endif
