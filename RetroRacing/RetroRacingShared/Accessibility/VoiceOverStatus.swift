//
//  VoiceOverStatus.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 19/02/2026.
//

import Foundation
#if os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#else
import UIKit
#endif

/// Shared VoiceOver status helper so feature code can stay platform-agnostic.
public enum VoiceOverStatus {
    public static var isVoiceOverRunning: Bool {
        #if os(watchOS)
        WKAccessibilityIsVoiceOverRunning()
        #elseif os(macOS)
        NSWorkspace.shared.isVoiceOverEnabled
        #else
        UIAccessibility.isVoiceOverRunning
        #endif
    }
}
