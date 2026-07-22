//
//  GroupSessionCoordinator.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Combine
import Foundation

/// Owns the lifecycle of a single `GroupSession<RetroRacingGroupActivity>`: joining it,
/// observing state/participant changes, and wiring a `GroupSessionMessengerTransport`.
/// `GroupActivitiesSharePlayMatchService` owns one instance and reconfigures it whenever a new
/// session arrives from `RetroRacingGroupActivity.sessions()`.
final class GroupSessionCoordinator {
    private(set) var transport: GroupSessionMessengerTransport?
    private var session: GroupSession<RetroRacingGroupActivity>?
    private var stateTask: Task<Void, Never>?
    private var participantsTask: Task<Void, Never>?
    private var isIntentionalTeardown = false
    private var hasObservedTwoParticipants = false

    /// Called once at least 2 participants are active in the session.
    var onParticipantsReady: (() -> Void)?
    /// Called when the session invalidates (disconnect, remote left, etc.).
    var onDisconnected: (() -> Void)?
    /// Called when the remote participant's display name is resolved or cleared.
    var onOpponentDisplayNameChanged: ((String?) -> Void)?

    /// Joins the given session and starts observing it. Tears down any previously configured
    /// session first (v1 supports exactly one active SharePlay session at a time).
    func configure(session: GroupSession<RetroRacingGroupActivity>, onCommand: @escaping (SharePlayMatchCommand) -> Void) {
        tearDown()
        self.session = session
        hasObservedTwoParticipants = false

        let transport = GroupSessionMessengerTransport(session: session)
        transport.startReceiving(onCommand: onCommand)
        self.transport = transport

        stateTask = Task { [weak self] in
            for await state in session.$state.values {
                guard let self, Task.isCancelled == false else { return }
                if case .invalidated = state {
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
                guard let self, Task.isCancelled == false else { return }
                // GroupActivities `Participant` exposes only an id in iOS 26 — no public
                // display-name API. UI falls back to the localized "Your friend" label.
                self.onOpponentDisplayNameChanged?(nil)
                if participants.count >= 2 {
                    self.hasObservedTwoParticipants = true
                    self.onParticipantsReady?()
                } else if self.hasObservedTwoParticipants, self.isIntentionalTeardown == false {
                    self.onDisconnected?()
                    self.tearDown()
                    return
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
        isIntentionalTeardown = true
        stateTask?.cancel()
        participantsTask?.cancel()
        stateTask = nil
        participantsTask = nil
        transport?.stop()
        transport = nil
        session = nil
        hasObservedTwoParticipants = false
        onOpponentDisplayNameChanged?(nil)
        isIntentionalTeardown = false
    }
}
#endif
