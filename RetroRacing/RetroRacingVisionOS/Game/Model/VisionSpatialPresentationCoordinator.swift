//
//  VisionSpatialPresentationCoordinator.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import Foundation

/// Owns cancellable model preflight, immersive routing, and surface-search guidance work.
@MainActor
final class VisionSpatialPresentationCoordinator {
    private let delayScheduler: any VisionDelayScheduling
    private let immersiveSpaceRouter: any VisionImmersiveSpaceRouting
    private let modelRepository: any TabletopModelRepositoryProtocol
    private let troubleshootingDelay: Duration
    private var activeTransitionID: VisionSpatialTransitionID?
    private var presentationTask: Task<Void, Never>?
    private var guidanceTask: Task<Void, Never>?

    init(
        delayScheduler: any VisionDelayScheduling,
        immersiveSpaceRouter: any VisionImmersiveSpaceRouting,
        modelRepository: any TabletopModelRepositoryProtocol,
        troubleshootingDelay: Duration
    ) {
        self.delayScheduler = delayScheduler
        self.immersiveSpaceRouter = immersiveSpaceRouter
        self.modelRepository = modelRepository
        self.troubleshootingDelay = troubleshootingDelay
    }

    func begin(
        transitionID: VisionSpatialTransitionID,
        using actions: VisionSpatialActions,
        onOpening: @escaping @MainActor (VisionSpatialTransitionID) -> Void,
        onOpened: @escaping @MainActor (VisionSpatialTransitionID) -> Void,
        onFailure: @escaping @MainActor (
            VisionSpatialTransitionID,
            VisionSpatialFailure,
            Error?
        ) -> Void
    ) {
        reset()
        activeTransitionID = transitionID
        presentationTask = Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await modelRepository.canonicalCars()
                try Task.checkCancellation()
                guard isActive(transitionID) else { return }
                onOpening(transitionID)

                try await immersiveSpaceRouter.open(using: actions)
                try Task.checkCancellation()
                guard isActive(transitionID) else { return }
                onOpened(transitionID)
            } catch is CancellationError {
                return
            } catch let error as VisionImmersiveSpaceRoutingError {
                guard isActive(transitionID) else { return }
                let failure: VisionSpatialFailure = error == .userCancelled
                    ? .immersiveOpenCancelled
                    : .immersiveOpenFailed
                onFailure(transitionID, failure, error)
            } catch {
                guard isActive(transitionID) else { return }
                onFailure(transitionID, .modelUnavailable, error)
            }
        }
    }

    func beginSurfaceSearchGuidance(
        transitionID: VisionSpatialTransitionID,
        onTroubleshooting: @escaping @MainActor (VisionSpatialTransitionID) -> Void
    ) {
        guard isActive(transitionID) else { return }
        guidanceTask?.cancel()
        guidanceTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await delayScheduler.sleep(for: troubleshootingDelay)
            } catch {
                return
            }
            guard Task.isCancelled == false, isActive(transitionID) else { return }
            onTroubleshooting(transitionID)
        }
    }

    func surfaceWasFound(transitionID: VisionSpatialTransitionID) {
        guard isActive(transitionID) else { return }
        guidanceTask?.cancel()
        guidanceTask = nil
    }

    func dismissImmersiveSpace(using actions: VisionSpatialActions) {
        let taskBeingCancelled = presentationTask
        taskBeingCancelled?.cancel()
        guidanceTask?.cancel()
        guidanceTask = nil
        presentationTask = Task { [immersiveSpaceRouter] in
            await taskBeingCancelled?.value
            await immersiveSpaceRouter.dismiss(using: actions)
        }
        activeTransitionID = nil
    }

    func cancel() {
        reset()
    }

    private func isActive(_ transitionID: VisionSpatialTransitionID) -> Bool {
        activeTransitionID == transitionID
    }

    private func reset() {
        presentationTask?.cancel()
        presentationTask = nil
        guidanceTask?.cancel()
        guidanceTask = nil
        activeTransitionID = nil
    }
}
