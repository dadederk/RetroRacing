//
//  SharePlayPreReadyInvalidationGrace.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

/// Defers SharePlay disconnect callbacks for transient pre-ready GroupActivities session invalidation.
/// A replacement session can cancel the pending disconnect before the grace window elapses.
public final class SharePlayPreReadyInvalidationGrace: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Never>?
    private var generation = 0

    public init() {}

    public var hasPendingTask: Bool {
        lock.withLock { task != nil }
    }

    public func schedule(
        graceDuration: TimeInterval,
        shouldDisconnect: @escaping @Sendable () -> Bool,
        onDisconnect: @escaping @Sendable () -> Void
    ) {
        lock.withLock {
            guard task == nil else { return }

            generation += 1
            let scheduledGeneration = generation
            let delay = UInt64(max(0, graceDuration) * 1_000_000_000)
            task = Task { [weak self] in
                try? await Task.sleep(nanoseconds: delay)
                guard let self, Task.isCancelled == false else { return }
                self.completeScheduledGrace(
                    scheduledGeneration: scheduledGeneration,
                    shouldDisconnect: shouldDisconnect,
                    onDisconnect: onDisconnect
                )
            }
        }
    }

    public func cancel() {
        lock.withLock {
            guard task != nil else { return }
            generation += 1
            task?.cancel()
            task = nil
        }
    }

    private func completeScheduledGrace(
        scheduledGeneration: Int,
        shouldDisconnect: @Sendable () -> Bool,
        onDisconnect: @Sendable () -> Void
    ) {
        let shouldFire = lock.withLock { () -> Bool in
            guard scheduledGeneration == generation else { return false }
            defer {
                if scheduledGeneration == generation {
                    task = nil
                }
            }
            return shouldDisconnect()
        }
        guard shouldFire else { return }
        onDisconnect()
    }
}
