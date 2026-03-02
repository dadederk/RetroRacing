//
//  NoOpGameControllerInputSource.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-03-02.
//

import Foundation

/// A `GameControllerInputSource` that does nothing.
///
/// Used as a default in contexts where game controller input is not needed
/// (e.g., the preview `GameView` inside `MenuView` when `onPlayRequest` is provided
/// and the view is never actually displayed).
public final class NoOpGameControllerInputSource: GameControllerInputSource {
    public init() {}

    public func start(handler: @escaping @MainActor @Sendable (GameControllerAction) -> Void) {}

    public func stop() {}
}
