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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Non-fatal; sound may still work in simulator
        }
        #endif
    }

    /// Registers the custom font from the shared framework so `.font(.custom("PressStart2P-Regular", size:))` works.
    /// - Returns: true if registration succeeded.
    @discardableResult
    public static func registerCustomFont() -> Bool {
        FontRegistrar.registerPressStart2P(additionalBundles: [Bundle.main])
    }
}
