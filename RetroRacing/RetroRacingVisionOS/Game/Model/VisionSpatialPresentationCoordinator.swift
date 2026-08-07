//
//  VisionSpatialPresentationCoordinator.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import Foundation

/// Owns cancellable model preflight and pushed-volume routing.
@MainActor
final class VisionSpatialPresentationCoordinator {
    private let volumeRouter: any VisionVolumeRouting
    private let modelRepository: any TabletopModelRepositoryProtocol
    private var activeTransitionID: VisionSpatialTransitionID?
    private var presentationTask: Task<Void, Never>?

    init(
        volumeRouter: any VisionVolumeRouting,
        modelRepository: any TabletopModelRepositoryProtocol
    ) {
        self.volumeRouter = volumeRouter
        self.modelRepository = modelRepository
    }

    func begin(
        transitionID: VisionSpatialTransitionID,
        using actions: VisionSpatialActions,
        onOpening: @escaping @MainActor (VisionSpatialTransitionID) -> Void,
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
                guard isActive(transitionID) else { return }
                volumeRouter.push(using: actions)
            } catch is CancellationError {
                return
            } catch {
                guard isActive(transitionID) else { return }
                onFailure(transitionID, .modelUnavailable, error)
            }
        }
    }

    func dismissVolume(using actions: VisionSpatialActions) {
        let taskBeingCancelled = presentationTask
        taskBeingCancelled?.cancel()
        presentationTask = Task { [volumeRouter] in
            await taskBeingCancelled?.value
            await volumeRouter.dismiss(using: actions)
        }
        activeTransitionID = nil
    }

    func hideClassic(using actions: VisionSpatialActions) {
        volumeRouter.hideClassic(using: actions)
    }

    func restoreClassic(using actions: VisionSpatialActions) {
        volumeRouter.restoreClassic(using: actions)
    }

    func restoreClassicAndDismissVolume(using actions: VisionSpatialActions) {
        let taskBeingCancelled = presentationTask
        taskBeingCancelled?.cancel()
        presentationTask = Task { [volumeRouter] in
            await taskBeingCancelled?.value
            volumeRouter.restoreClassic(using: actions)
            await volumeRouter.dismiss(using: actions)
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
        activeTransitionID = nil
    }
}
