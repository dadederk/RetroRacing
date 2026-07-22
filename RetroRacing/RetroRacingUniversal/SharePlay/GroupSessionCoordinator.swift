//
//  GroupSessionCoordinator.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Combine
import Foundation
import RetroRacingShared

/// Owns the lifecycle of a single `GroupSession<RetroRacingGroupActivity>`: joining it,
/// observing state/participant changes, and wiring a `GroupSessionMessengerTransport`.
/// `GroupActivitiesSharePlayMatchService` owns one instance and reconfigures it whenever a new
/// session arrives from `RetroRacingGroupActivity.sessions()`.
nonisolated final class GroupSessionCoordinator {
    private(set) var transport: GroupSessionMessengerTransport?
    private var session: GroupSession<RetroRacingGroupActivity>?
    private var stateTask: Task<Void, Never>?
    private var participantsTask: Task<Void, Never>?
    private var participantLossTask: Task<Void, Never>?
    private let participantLossGraceDuration: TimeInterval
    private var isIntentionalTeardown = false
    private var hasObservedTwoParticipants = false
    private var lastOpponentDisplayName: String?
    private var observationGeneration = 0

    /// Called once at least 2 participants are active in the session.
    var onParticipantsReady: (() -> Void)?
    /// Called when the session invalidates (disconnect, remote left, etc.).
    var onDisconnected: (() -> Void)?
    /// Called when the remote participant's display name is resolved or cleared.
    var onOpponentDisplayNameChanged: ((String?) -> Void)?

    init(participantLossGraceDuration: TimeInterval = 1.5) {
        self.participantLossGraceDuration = participantLossGraceDuration
    }

    /// Joins the given session and starts observing it. Tears down any previously configured
    /// session first (v1 supports exactly one active SharePlay session at a time).
    func configure(session: GroupSession<RetroRacingGroupActivity>, onCommand: @escaping (SharePlayMatchCommand) -> Void) {
        tearDown()
        observationGeneration += 1
        let generation = observationGeneration
        self.session = session
        hasObservedTwoParticipants = false
        lastOpponentDisplayName = nil

        let transport = GroupSessionMessengerTransport(session: session)
        transport.startReceiving(onCommand: onCommand)
        self.transport = transport

        stateTask = Task { [weak self] in
            for await state in session.$state.values {
                guard let self, Task.isCancelled == false, self.isCurrentObservation(generation) else { return }
                if case .invalidated = state {
                    self.cancelParticipantLossDisconnect()
                    if self.isIntentionalTeardown == false {
                        self.onDisconnected?()
                    }
                    self.tearDown()
                    return
                }
            }
        }

        participantsTask = Task { [weak self] in
            for await participants in session.$activeParticipants.values {
                guard let self, Task.isCancelled == false, self.isCurrentObservation(generation) else { return }
                // GroupActivities `Participant` exposes only an id in iOS 26 — no public
                // display-name API. UI falls back to the localized "Your friend" label.
                self.updateOpponentDisplayNameIfNeeded(nil)
                if participants.count >= 2 {
                    self.cancelParticipantLossDisconnect()
                    if self.hasObservedTwoParticipants == false {
                        self.hasObservedTwoParticipants = true
                        self.onParticipantsReady?()
                    }
                } else if self.hasObservedTwoParticipants, self.isIntentionalTeardown == false {
                    self.scheduleParticipantLossDisconnect(for: generation)
                }
            }
        }

        session.join()
    }

    /// Sends a command over the currently configured transport, if any.
    func send(_ command: SharePlayMatchCommand) async {
        await transport?.send(command)
    }

    /// Leaves the session gracefully (user-initiated exit, not a disconnect).
    func leave() {
        session?.leave()
        tearDown()
    }

    private func tearDown() {
        observationGeneration += 1
        isIntentionalTeardown = true
        stateTask?.cancel()
        participantsTask?.cancel()
        cancelParticipantLossDisconnect()
        stateTask = nil
        participantsTask = nil
        transport?.stop()
        transport = nil
        session = nil
        hasObservedTwoParticipants = false
        updateOpponentDisplayNameIfNeeded(nil)
        isIntentionalTeardown = false
    }

    private func isCurrentObservation(_ generation: Int) -> Bool {
        observationGeneration == generation
    }

    private func scheduleParticipantLossDisconnect(for generation: Int) {
        guard participantLossTask == nil else { return }
        let delay = UInt64(max(0, participantLossGraceDuration) * 1_000_000_000)
        participantLossTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard let self,
                  Task.isCancelled == false,
                  self.isCurrentObservation(generation),
                  self.hasObservedTwoParticipants,
                  self.isIntentionalTeardown == false else {
                return
            }
            self.participantLossTask = nil
            self.onDisconnected?()
            self.tearDown()
        }
    }

    private func cancelParticipantLossDisconnect() {
        participantLossTask?.cancel()
        participantLossTask = nil
    }

    private func updateOpponentDisplayNameIfNeeded(_ displayName: String?) {
        guard lastOpponentDisplayName != displayName else { return }
        lastOpponentDisplayName = displayName
        onOpponentDisplayNameChanged?(displayName)
    }
}
#endif
