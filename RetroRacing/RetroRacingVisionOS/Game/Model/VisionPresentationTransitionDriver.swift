//
//  VisionPresentationTransitionDriver.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation

/// Owns the cancellable routing and timeout work for one presentation handoff.
@MainActor
final class VisionPresentationTransitionDriver {
    private let delayScheduler: any VisionDelayScheduling
    private let windowRouter: any VisionWindowRouting
    private let transitionTimeout: Duration
    private var transitionTimeoutTask: Task<Void, Never>?
    private var routingTask: Task<Void, Never>?
    private var activeRequest: VisionPresentationRequest?
    private var activeWindowActions: VisionWindowActions?
    private var failureHandler: (@MainActor (VisionPresentationRequest, VisionTransitionFailure, Error?) -> Void)?

    init(
        delayScheduler: any VisionDelayScheduling,
        windowRouter: any VisionWindowRouting,
        transitionTimeout: Duration
    ) {
        self.delayScheduler = delayScheduler
        self.windowRouter = windowRouter
        self.transitionTimeout = transitionTimeout
    }

    var strategy: VisionWindowRoutingStrategy { windowRouter.strategy }

    func begin(
        _ request: VisionPresentationRequest,
        using actions: VisionWindowActions,
        onFailure: @escaping @MainActor (VisionPresentationRequest, VisionTransitionFailure, Error?) -> Void
    ) {
        reset()
        activeRequest = request
        activeWindowActions = actions
        failureHandler = onFailure
        route(request, using: actions)
        startTimeout(for: request)
    }

    func complete(_ request: VisionPresentationRequest, using actions: VisionWindowActions) {
        guard activeRequest == request else { return }
        reset()
        windowRouter.complete(request, using: actions)
    }

    func cancel(_ request: VisionPresentationRequest) {
        guard activeRequest == request else { return }
        let actions = activeWindowActions
        reset()
        if let actions {
            windowRouter.cancel(request, using: actions)
        }
    }

    func reset() {
        transitionTimeoutTask?.cancel()
        transitionTimeoutTask = nil
        routingTask?.cancel()
        routingTask = nil
        activeRequest = nil
        activeWindowActions = nil
        failureHandler = nil
    }

    private func route(_ request: VisionPresentationRequest, using actions: VisionWindowActions) {
        routingTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await windowRouter.present(request, using: actions)
            } catch is CancellationError {
                return
            } catch {
                reportFailure(.routingFailed, request: request, underlyingError: error)
            }
        }
    }

    private func startTimeout(for request: VisionPresentationRequest) {
        transitionTimeoutTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await delayScheduler.sleep(for: transitionTimeout)
            } catch {
                return
            }
            guard Task.isCancelled == false else { return }
            reportFailure(.timedOut, request: request)
        }
    }

    private func reportFailure(
        _ failure: VisionTransitionFailure,
        request: VisionPresentationRequest,
        underlyingError: Error? = nil
    ) {
        guard activeRequest == request else { return }
        failureHandler?(request, failure, underlyingError)
    }
}
