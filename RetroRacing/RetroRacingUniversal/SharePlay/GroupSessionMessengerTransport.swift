//
//  GroupSessionMessengerTransport.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Foundation
import RetroRacingShared

/// Thin wrapper around `GroupSessionMessenger` that speaks only `SharePlayMatchCommand`,
/// keeping the GroupActivities messenger APIs out of the state machine and service layer.
nonisolated final class GroupSessionMessengerTransport {
    private let messenger: GroupSessionMessenger
    private var receiveTask: Task<Void, Never>?

    init(session: GroupSession<RetroRacingGroupActivity>) {
        self.messenger = GroupSessionMessenger(session: session)
    }

    /// Starts listening for incoming commands. Replaces any previous listener.
    func startReceiving(onCommand: @escaping (SharePlayMatchCommand) -> Void) {
        receiveTask?.cancel()
        let messenger = self.messenger
        receiveTask = Task {
            for await (command, _) in messenger.messages(of: SharePlayMatchCommand.self) {
                if Task.isCancelled { return }
                onCommand(command)
            }
        }
    }

    /// Sends a command to the other participant(s). Failures are logged but non-fatal —
    /// the match continues locally and the state machine's next round/retry cycle will
    /// naturally re-synchronize via subsequent messages.
    func send(_ command: SharePlayMatchCommand) async {
        do {
            try await messenger.send(command)
        } catch {
            AppLog.error(
                .game,
                "SHAREPLAY_MESSENGER_SEND",
                outcome: .failed,
                fields: AppLog.Field.error(error)
            )
        }
    }

    func stop() {
        receiveTask?.cancel()
        receiveTask = nil
    }
}
#endif
