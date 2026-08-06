//
//  VisionDelayScheduling.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation

/// Injected suspension boundary for presentation-transition timeouts.
@MainActor
protocol VisionDelayScheduling: AnyObject {
    func sleep(for duration: Duration) async throws
}

@MainActor
final class TaskVisionDelayScheduler: VisionDelayScheduling {
    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
