//
//  GameLoopScheduling.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation

/// Injected scheduling boundary used by renderer-neutral gameplay coordinators.
@MainActor
public protocol GameLoopScheduling: AnyObject {
    func start(onTick: @escaping @MainActor (TimeInterval) -> Void)
    func stop()
}

/// Continuous-clock scheduler used by the visionOS composition root.
@MainActor
public final class TaskGameLoopScheduler: GameLoopScheduling {
    private let frameDuration: Duration
    private var loopTask: Task<Void, Never>?

    public init(frameDuration: Duration) {
        self.frameDuration = frameDuration
    }

    deinit {
        loopTask?.cancel()
    }

    public func start(onTick: @escaping @MainActor (TimeInterval) -> Void) {
        stop()
        loopTask = Task { [frameDuration] in
            let clock = ContinuousClock()
            var previousInstant = clock.now
            while Task.isCancelled == false {
                do {
                    try await Task.sleep(for: frameDuration)
                } catch {
                    return
                }
                guard Task.isCancelled == false else { return }
                let currentInstant = clock.now
                let duration = previousInstant.duration(to: currentInstant)
                previousInstant = currentInstant
                let components = duration.components
                let elapsedTime = Double(components.seconds)
                    + (Double(components.attoseconds) / 1_000_000_000_000_000_000)
                onTick(elapsedTime)
            }
        }
    }

    public func stop() {
        loopTask?.cancel()
        loopTask = nil
    }
}
