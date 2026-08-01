//
//  SharePlayActivationHandoffCoordinator.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 31/07/2026.
//

import Foundation
import Observation
import RetroRacingShared

nonisolated struct SharePlayActivationHandoffTiming: Sendable, Equatable {
    let pollNanoseconds: UInt64
    let settleNanoseconds: UInt64
    let timeoutNanoseconds: UInt64

    static let standard = SharePlayActivationHandoffTiming(
        pollNanoseconds: 250_000_000,
        settleNanoseconds: 750_000_000,
        timeoutNanoseconds: 12_000_000_000
    )
}

private struct SharePlayActivationRequestState {
    var requestID: UUID?

    var isPending: Bool {
        requestID != nil
    }

    mutating func begin(_ id: UUID) {
        requestID = id
    }

    mutating func clear() {
        requestID = nil
    }
}

private struct SharePlayActivationHandoffSnapshot: Sendable {
    let isCurrent: Bool
    let isEligibleForGroupSession: Bool
}

/// Owns the UI-to-system handoff for starting a host SharePlay activity.
@MainActor
@Observable
final class SharePlayActivationHandoffCoordinator {
    private let sharePlayMatchService: any SharePlayMatchService
    private let isSharePlayAvailable: Bool
    private let isEligibleForGroupSession: @MainActor () -> Bool
    private let timing: SharePlayActivationHandoffTiming

    private var requestState = SharePlayActivationRequestState()
    var sharingPresentation: SharePlaySharingPresentation?

    @ObservationIgnored
    private var handoffTimeoutTask: Task<Void, Never>?

    var isActivationPending: Bool {
        requestState.isPending
    }

    init(
        sharePlayMatchService: any SharePlayMatchService,
        isSharePlayAvailable: Bool,
        isEligibleForGroupSession: @escaping @MainActor () -> Bool,
        timing: SharePlayActivationHandoffTiming = .standard
    ) {
        self.sharePlayMatchService = sharePlayMatchService
        self.isSharePlayAvailable = isSharePlayAvailable
        self.isEligibleForGroupSession = isEligibleForGroupSession
        self.timing = timing
    }

    deinit {
        handoffTimeoutTask?.cancel()
    }

    func handlePlayWithFriendsRequest(currentState: SharePlayMatchState) {
        guard let requestID = beginActivationRequest(currentState: currentState) else { return }
        guard isSharePlayAvailable else {
            clearActivationRequest(requestID: requestID, reason: .sharePlayUnavailable)
            return
        }

        let activationRoute = SharePlayHostActivationRoutingPolicy.route(
            isEligibleForGroupSession: isEligibleForGroupSession()
        )
        Task { @concurrent [weak self, sharePlayMatchService] in
            let didPrepareHostActivation = await sharePlayMatchService.prepareHostActivation()
            guard didPrepareHostActivation else {
                await self?.clearActivationRequest(
                    requestID: requestID,
                    reason: .hostActivationRejected
                )
                return
            }
            if activationRoute == .directActivation {
                let didActivate = await sharePlayMatchService.activatePendingHostSession(
                    reason: .eligibleMenuRequest
                )
                await self?.handleDirectSharePlayActivationResult(
                    didActivate,
                    requestID: requestID
                )
                return
            }
            let didPresentSharingController = await self?.presentSharingControllerIfCurrent(
                requestID: requestID
            ) ?? false
            if didPresentSharingController == false {
                await sharePlayMatchService.cancelHostActivation(reason: .staleActivationRequest)
            }
        }
    }

    func clearActivationRequest(reason: SharePlayHostActivationReason) {
        clearActivationRequest(requestID: nil, reason: reason)
    }

    func dismissSharingPresentation() {
        sharingPresentation = nil
    }

    func handleSharePlaySharingSucceeded(
        isSharePlayIdle: Bool,
        isMenuPresented: Bool,
        shouldStartGame: Bool
    ) {
        guard let requestID = requestState.requestID,
              requestState.isPending,
              isSharePlayIdle else { return }
        sharingPresentation = nil
        scheduleSharePlaySessionHandoff(
            for: requestID,
            recoversEligibleControllerHandoff: true
        )
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_INVITE_HANDOFF",
            outcome: .completed,
            fields: [
                .reason(SharePlayHostActivationReason.sharingControllerSucceeded.rawValue),
                .string("requestID", AppLog.shortID(requestID)),
                .bool("isMenuPresented", isMenuPresented),
                .bool("shouldStartGame", shouldStartGame)
            ]
        )
    }

    func handleSharePlaySharingUserDismissed(isSharePlayIdle: Bool) {
        sharingPresentation = nil
        clearActivationRequest(reason: .sharingControllerDismissed)
        guard isSharePlayIdle else { return }
        Task { @concurrent [sharePlayMatchService] in
            await sharePlayMatchService.cancelHostActivation(reason: .sharingControllerDismissed)
        }
    }

    private func beginActivationRequest(currentState: SharePlayMatchState) -> UUID? {
        let fields: [AppLog.Field] = [
            .bool("isPending", requestState.isPending),
            .bool("isActive", currentState.isActive),
            .string("state", currentState.diagnosticName),
            .string("requestID", requestState.requestID.map { AppLog.shortID($0) })
        ]
        guard requestState.isPending == false else {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_MENU_REQUEST",
                outcome: .ignored,
                fields: fields + [.reason("activation_pending")]
            )
            return nil
        }
        guard currentState.isActive == false else {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_MENU_REQUEST",
                outcome: .ignored,
                fields: fields + [.reason("shareplay_active")]
            )
            return nil
        }

        let requestID = UUID()
        requestState.begin(requestID)
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_MENU_REQUEST",
            outcome: .requested,
            fields: [
                .bool("isEligibleForGroupSession", isEligibleForGroupSession()),
                .string("requestID", AppLog.shortID(requestID))
            ]
        )
        return requestID
    }

    private func clearActivationRequest(
        requestID: UUID? = nil,
        reason: SharePlayHostActivationReason
    ) {
        guard requestState.isPending else { return }
        if let requestID, requestState.requestID != requestID {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_MENU_REQUEST",
                outcome: .ignored,
                fields: [
                    .reason(SharePlayHostActivationReason.staleActivationRequest.rawValue),
                    .string("requestID", AppLog.shortID(requestID)),
                    .string("currentRequestID", requestState.requestID.map { AppLog.shortID($0) })
                ]
            )
            return
        }
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_MENU_REQUEST",
            outcome: .completed,
            fields: [
                .reason(reason.rawValue),
                .string("requestID", requestState.requestID.map { AppLog.shortID($0) })
            ]
        )
        handoffTimeoutTask?.cancel()
        handoffTimeoutTask = nil
        requestState.clear()
    }

    private func presentSharingControllerIfCurrent(requestID: UUID) -> Bool {
        guard requestState.requestID == requestID else { return false }
        sharingPresentation = SharePlaySharingPresentation()
        return true
    }

    private func handleDirectSharePlayActivationResult(_ didActivate: Bool, requestID: UUID) {
        guard requestState.requestID == requestID,
              requestState.isPending else { return }
        guard didActivate else {
            clearActivationRequest(
                requestID: requestID,
                reason: .directActivationFailed
            )
            return
        }
        scheduleSharePlaySessionHandoff(
            for: requestID,
            recoversEligibleControllerHandoff: false
        )
    }

    private func scheduleSharePlaySessionHandoff(
        for requestID: UUID,
        recoversEligibleControllerHandoff: Bool
    ) {
        handoffTimeoutTask?.cancel()
        handoffTimeoutTask = Task { @concurrent [weak self, sharePlayMatchService, timing] in
            var elapsedNanoseconds: UInt64 = 0
            var didAttemptRecovery = false
            let pollNanoseconds = max(1, timing.pollNanoseconds)

            while elapsedNanoseconds < timing.timeoutNanoseconds {
                try? await Task.sleep(nanoseconds: pollNanoseconds)
                guard Task.isCancelled == false else { return }
                elapsedNanoseconds += pollNanoseconds

                guard let snapshot = await self?.handoffSnapshot(for: requestID) else { return }
                guard snapshot.isCurrent else { return }
                guard recoversEligibleControllerHandoff,
                      SharePlayHostActivationRoutingPolicy.shouldRecoverControllerHandoff(
                        isEligibleForGroupSession: snapshot.isEligibleForGroupSession,
                        isActivationRequestCurrent: snapshot.isCurrent,
                        hasAttemptedRecovery: didAttemptRecovery
                      ) else { continue }

                didAttemptRecovery = true
                AppLog.info(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_INVITE_HANDOFF_RECOVERY",
                    outcome: .deferred,
                    fields: [
                        .reason("eligible_conversation_settle"),
                        .string("requestID", AppLog.shortID(requestID))
                    ]
                )
                try? await Task.sleep(nanoseconds: timing.settleNanoseconds)
                guard Task.isCancelled == false else { return }
                let isStillCurrent = await self?.isCurrentActivationRequest(requestID) ?? false
                guard isStillCurrent else { return }

                let didActivate = await sharePlayMatchService.activatePendingHostSession(
                    reason: .sharingControllerHandoffRecovery
                )
                guard Task.isCancelled == false else { return }
                if didActivate == false {
                    await self?.clearActivationRequest(
                        requestID: requestID,
                        reason: .handoffRecoveryFailed
                    )
                    return
                }
            }

            let didTimeout = await self?.handleHandoffTimedOut(requestID: requestID) ?? false
            if didTimeout {
                await sharePlayMatchService.cancelHostActivation(reason: .sessionHandoffTimeout)
            }
        }
    }

    private func handoffSnapshot(for requestID: UUID) -> SharePlayActivationHandoffSnapshot {
        SharePlayActivationHandoffSnapshot(
            isCurrent: isCurrentActivationRequest(requestID),
            isEligibleForGroupSession: isEligibleForGroupSession()
        )
    }

    private func isCurrentActivationRequest(_ requestID: UUID) -> Bool {
        requestState.requestID == requestID && requestState.isPending
    }

    private func handleHandoffTimedOut(requestID: UUID) -> Bool {
        guard requestState.requestID == requestID,
              requestState.isPending else { return false }
        sharingPresentation = nil
        clearActivationRequest(
            requestID: requestID,
            reason: .sessionHandoffTimeout
        )
        return true
    }
}
