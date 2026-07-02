//
//  AVAudioSessionActivation.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 24/06/2026.
//

import AVFoundation

#if !os(macOS)
/// Routes AVAudioSession activation through one helper.
///
/// On Xcode 26 builds we use legacy `setActive(true)` because `activate(options:completionHandler:)`
/// is iOS/tvOS/visionOS 27+ only and cannot compile against the SDK 26 toolchain.
/// Restore the SDK 27 path when archiving with Xcode 27+ — see `Docs/xcode-27-sdk-restore.md`.
enum AVAudioSessionActivation {
    static func activate(_ session: AVAudioSession = .sharedInstance()) async throws {
        try await Task.detached(priority: .userInitiated) {
            try session.setActive(true)
        }.value
    }

    static func activateBlocking(_ session: AVAudioSession = .sharedInstance()) throws {
        if Thread.isMainThread {
            try runOffMainThread {
                try session.setActive(true)
            }
        } else {
            try session.setActive(true)
        }
    }

    private static func runOffMainThread(_ work: @escaping () throws -> Void) throws {
        var workError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached(priority: .userInitiated) {
            do {
                try work()
            } catch {
                workError = error
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let workError {
            throw workError
        }
    }
}

struct AudioSessionActivationError: LocalizedError {
    var errorDescription: String? {
        "The audio session activation completed without becoming active."
    }
}
#endif
