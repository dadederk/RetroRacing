//
//  VisionWindowRouting.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation

enum VisionWindowRoutingStrategy: String, Equatable, Sendable {
    case push
    case explicit
}

struct VisionPresentationTransitionID: Hashable, Sendable {
    let rawValue: UInt64
}

struct VisionPresentationRequest: Equatable, Sendable {
    let id: VisionPresentationTransitionID
    let source: VisionGamePresentation
    let destination: VisionGamePresentation
}

@MainActor
struct VisionWindowActions {
    let push: (String) -> Void
    let open: (String) async throws -> Void
    let dismiss: (String) -> Void
}

@MainActor
protocol VisionWindowRouting: AnyObject {
    var strategy: VisionWindowRoutingStrategy { get }

    func present(
        _ request: VisionPresentationRequest,
        using actions: VisionWindowActions
    ) async throws
    func complete(_ request: VisionPresentationRequest, using actions: VisionWindowActions)
    func cancel(_ request: VisionPresentationRequest, using actions: VisionWindowActions)
}

@MainActor
final class VisionWindowRouter: VisionWindowRouting {
    let strategy: VisionWindowRoutingStrategy

    init(strategy: VisionWindowRoutingStrategy) {
        self.strategy = strategy
    }

    func present(
        _ request: VisionPresentationRequest,
        using actions: VisionWindowActions
    ) async throws {
        switch strategy {
        case .push:
            if request.destination == .tabletop {
                actions.push(sceneID(for: .tabletop))
            } else {
                actions.dismiss(sceneID(for: .tabletop))
            }
        case .explicit:
            try await actions.open(sceneID(for: request.destination))
        }
    }

    func complete(_ request: VisionPresentationRequest, using actions: VisionWindowActions) {
        guard strategy == .explicit else { return }
        actions.dismiss(sceneID(for: request.source))
    }

    func cancel(_ request: VisionPresentationRequest, using actions: VisionWindowActions) {
        switch strategy {
        case .explicit:
            actions.dismiss(sceneID(for: request.destination))
        case .push:
            if request.destination == .tabletop {
                actions.dismiss(sceneID(for: .tabletop))
            } else {
                actions.push(sceneID(for: .tabletop))
            }
        }
    }

    private func sceneID(for presentation: VisionGamePresentation) -> String {
        switch presentation {
        case .classic: VisionSceneID.classic
        case .tabletop: VisionSceneID.tabletop
        }
    }
}
