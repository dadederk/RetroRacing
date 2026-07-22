//
//  SharePlayMatchService+Environment.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import SwiftUI

// MARK: - Environment Key

private struct SharePlayMatchServiceKey: EnvironmentKey {
    static let defaultValue: (any SharePlayMatchService)? = nil
}

extension EnvironmentValues {
    /// Access the current `SharePlayMatchService` from the environment.
    /// Returns `nil` on platforms/builds without a SharePlay integration (e.g. previews, tests,
    /// or platforms outside the v1 iOS/iPad scope); callers should treat SharePlay as unavailable.
    public var sharePlayMatchService: (any SharePlayMatchService)? {
        get { self[SharePlayMatchServiceKey.self] }
        set { self[SharePlayMatchServiceKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Injects a `SharePlayMatchService` into the environment for descendant views.
    public func sharePlayMatchService(_ service: (any SharePlayMatchService)?) -> some View {
        environment(\.sharePlayMatchService, service)
    }
}
