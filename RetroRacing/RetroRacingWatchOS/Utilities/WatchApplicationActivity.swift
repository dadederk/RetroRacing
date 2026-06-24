//
//  WatchApplicationActivity.swift
//  RetroRacingWatchOS
//
//  Created by Dani Devesa on 24/06/2026.
//

import SwiftUI

/// Tracks whether the watch app is in the foreground without using deprecated WatchKit lifecycle APIs.
enum WatchApplicationActivity {
    private static let lock = NSLock()
    private static var isActiveStorage = true

    static var isActive: Bool {
        lock.withLock { isActiveStorage }
    }

    static func update(scenePhase: ScenePhase) {
        lock.withLock {
            isActiveStorage = scenePhase == .active
        }
    }
}
