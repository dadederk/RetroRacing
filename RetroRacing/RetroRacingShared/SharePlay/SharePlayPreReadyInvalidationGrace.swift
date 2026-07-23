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
        lock.lock()
        defer { lock.unlock() }
        return task != nil
    }

    public func schedule(
        graceDuration: TimeInterval,
        shouldDisconnect: @escaping @Sendable () -> Bool,
        onDisconnect: @escaping @Sendable () -> Void
    ) {
        lock.lock()
        guard task == nil else {
            lock.unlock()
            return
        }

        generation += 1
        let scheduledGeneration = generation
        let delay = UInt64(max(0, graceDuration) * 1_000_000_000)
        task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard let self else { return }
            guard Task.isCancelled == false else { return }

            var shouldFire = false
            self.lock.lock()
            defer { self.lock.unlock() }

            guard scheduledGeneration == self.generation else { return }
            defer {
                if scheduledGeneration == self.generation {
                    self.task = nil
                }
            }

            shouldFire = shouldDisconnect()
            guard shouldFire else { return }

            onDisconnect()
        }
        lock.unlock()
    }

    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        guard task != nil else { return }
        generation += 1
        task?.cancel()
        task = nil
    }
}
