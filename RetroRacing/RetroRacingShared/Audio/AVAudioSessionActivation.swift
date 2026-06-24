//
//  AVAudioSessionActivation.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 24/06/2026.
//

import AVFoundation

#if !os(macOS)
enum AVAudioSessionActivation {
    static func activate(_ session: AVAudioSession = .sharedInstance()) async throws {
        if #available(iOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 5.0, *) {
            try await activateAsynchronously(session)
        } else {
            try await Task.detached(priority: .userInitiated) {
                try session.setActive(true)
            }.value
        }
    }

    static func activateBlocking(_ session: AVAudioSession = .sharedInstance()) throws {
        if #available(iOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 5.0, *) {
            try activateSynchronously(session)
        } else if Thread.isMainThread {
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

    @available(iOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 5.0, *)
    private static func activateAsynchronously(_ session: AVAudioSession) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            session.activate(options: []) { activated, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if activated {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: AudioSessionActivationError())
                }
            }
        }
    }

    @available(iOS 27.0, tvOS 27.0, visionOS 27.0, watchOS 5.0, *)
    private static func activateSynchronously(_ session: AVAudioSession) throws {
        var activationError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        session.activate(options: []) { activated, error in
            if let error {
                activationError = error
            } else if activated == false {
                activationError = AudioSessionActivationError()
            }
            semaphore.signal()
        }
        semaphore.wait()
        if let activationError {
            throw activationError
        }
    }
}

struct AudioSessionActivationError: LocalizedError {
    var errorDescription: String? {
        "The audio session activation completed without becoming active."
    }
}
#endif
