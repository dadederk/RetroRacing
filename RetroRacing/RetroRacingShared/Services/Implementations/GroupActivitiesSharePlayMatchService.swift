//
//  GroupActivitiesSharePlayMatchService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Foundation

/// Production `SharePlayMatchService` backed by the GroupActivities framework (iOS/iPad only,
/// per v1 scope). Composes `GroupSessionCoordinator` (transport lifecycle) with the pure
/// `SharePlayMatchStateMachine` (transition logic), and reports state changes back to callers.
/// An actor because it owns mutable session/timer state shared between the incoming-sessions
/// task, the messenger receive loop, and calls made directly from `GameViewModel`.
public actor GroupActivitiesSharePlayMatchService: SharePlayMatchService {
    private let difficultyProvider: @Sendable () -> GameDifficulty
    private let coordinator = GroupSessionCoordinator()

    private var stateMachine: SharePlayMatchStateMachine?
    private var stateChangeHandler: (@Sendable (SharePlayMatchState) -> Void)?
    private var pendingHostActivation = false
    private var hasTwoParticipants = false
    private var opponentDisplayName: String?
    private var sessionGeneration = 0
    private var sessionsTask: Task<Void, Never>?
    private var countdownTask: Task<Void, Never>?
    private var retryTimeoutTask: Task<Void, Never>?

    public init(difficultyProvider: @escaping @Sendable () -> GameDifficulty) {
        self.difficultyProvider = difficultyProvider
    }

    public func setStateChangeHandler(_ handler: @escaping @Sendable (SharePlayMatchState) -> Void) async {
        stateChangeHandler = handler
    }

    public func currentRole() async -> SharePlayPlayerRole? {
        stateMachine?.localRole
    }

    public func currentOpponentDisplayName() async -> String? {
        opponentDisplayName
    }

    public func startHostSession() async {
        pendingHostActivation = true
        let activity = RetroRacingGroupActivity()
        do {
            let activated = try await activity.activate()
            if activated == false {
                pendingHostActivation = false
                AppLog.info(AppLog.game, "SHAREPLAY_ACTIVATE", outcome: .cancelled)
            }
        } catch {
            pendingHostActivation = false
            AppLog.error(AppLog.game, "SHAREPLAY_ACTIVATE", outcome: .failed, fields: AppLog.Field.error(error))
        }
    }

    public func prepareHostActivation() async {
        pendingHostActivation = true
    }

    public func cancelHostActivation() async {
        pendingHostActivation = false
        AppLog.info(AppLog.game, "SHAREPLAY_ACTIVATE", outcome: .cancelled)
    }

    /// Awaits both host-activated and system-activated (incoming) sessions for this activity.
    /// Intended to run for the lifetime of the app in a single long-lived `.task`.
    public func observeIncomingSessions() async {
        guard sessionsTask == nil else { return }
        let task = Task {
            for await session in RetroRacingGroupActivity.sessions() {
                if Task.isCancelled { return }
                await self.handle(session: session)
            }
        }
        sessionsTask = task
        await task.value
    }

    public func hostStartRoundIfReady(difficulty: GameDifficulty) async {
        guard var machine = stateMachine, machine.localRole == .host, case .waitingForFriend = machine.state else { return }
        let commands = machine.hostStartRound(difficulty: difficulty)
        stateMachine = machine
        await sendAll(commands)
        scheduleCountdownCompletion()
        notifyStateChanged()
    }

    public func updateLocalScore(_ score: Int, lives: Int) async {
        guard var machine = stateMachine else { return }
        let commands = machine.updateLocalScore(score, lives: lives)
        stateMachine = machine
        await sendAll(commands)
        notifyStateChanged()
    }

    public func reportLocalElimination(finalScore: Int) async {
        guard var machine = stateMachine else { return }
        let commands = machine.localPlayerEliminated(finalScore: finalScore)
        stateMachine = machine
        await sendAll(commands)
        notifyStateChanged()
    }

    public func retry() async {
        guard var machine = stateMachine else { return }
        let commands = machine.retryTapped()
        stateMachine = machine
        await sendAll(commands)
        scheduleRetryTimeoutIfNeeded()
        notifyStateChanged()
        await autoStartHostRoundIfReady()
    }

    public func leaveSession() async {
        cancelTimers()
        guard var machine = stateMachine else {
            coordinator.leave()
            return
        }
        let commands = machine.leaveSession()
        stateMachine = machine
        await sendAll(commands)
        coordinator.leave()
        notifyStateChanged()
    }

    // MARK: - Session lifecycle

    private func handle(session: GroupSession<RetroRacingGroupActivity>) async {
        cancelTimers()
        sessionGeneration += 1
        let generation = sessionGeneration

        let role: SharePlayPlayerRole = pendingHostActivation ? .host : .guest
        pendingHostActivation = false
        hasTwoParticipants = false
        opponentDisplayName = nil

        var machine = SharePlayMatchStateMachine(localRole: role)
        let commands = machine.startWaitingForFriend()
        stateMachine = machine

        coordinator.onParticipantsReady = { [weak self] in
            Task { await self?.participantsBecameReady() }
        }
        coordinator.onDisconnected = { [weak self] in
            Task { await self?.handleDisconnected(generation: generation) }
        }
        coordinator.onOpponentDisplayNameChanged = { [weak self] name in
            Task { await self?.updateOpponentDisplayName(name) }
        }
        coordinator.configure(session: session) { [weak self] command in
            Task { await self?.handleIncoming(command) }
        }

        await sendAll(commands)
        notifyStateChanged()
    }

    private func updateOpponentDisplayName(_ name: String?) {
        opponentDisplayName = name
        notifyStateChanged()
    }

    private func participantsBecameReady() async {
        hasTwoParticipants = true
        await autoStartHostRoundIfReady()
    }

    private func autoStartHostRoundIfReady() async {
        guard hasTwoParticipants else { return }
        await hostStartRoundIfReady(difficulty: difficultyProvider())
    }

    private func handleIncoming(_ command: SharePlayMatchCommand) async {
        guard var machine = stateMachine else { return }
        let commands = machine.receive(command)
        stateMachine = machine
        await sendAll(commands)

        if case .countdown = machine.state {
            scheduleCountdownCompletion()
        }
        if case .retryWaiting = machine.state {
            scheduleRetryTimeoutIfNeeded()
        }
        notifyStateChanged()

        if case .waitingForFriend = machine.state {
            await autoStartHostRoundIfReady()
        }
    }

    private func handleDisconnected(generation: Int) async {
        guard generation == sessionGeneration else { return }
        guard var machine = stateMachine else { return }
        cancelTimers()
        machine.disconnected()
        stateMachine = machine
        notifyStateChanged()
    }

    // MARK: - Timers

    private func scheduleCountdownCompletion() {
        countdownTask?.cancel()
        guard case .countdown(let startAt, _) = stateMachine?.state else { return }
        let delay = max(0, startAt.timeIntervalSinceNow)
        countdownTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await self.completeCountdown()
        }
    }

    private func completeCountdown() async {
        guard var machine = stateMachine else { return }
        machine.beginRound()
        stateMachine = machine
        notifyStateChanged()
    }

    private func scheduleRetryTimeoutIfNeeded() {
        retryTimeoutTask?.cancel()
        guard case .retryWaiting(_, _, let deadline) = stateMachine?.state else { return }
        let delay = max(0, deadline.timeIntervalSinceNow)
        retryTimeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await self.completeRetryTimeout()
        }
    }

    private func completeRetryTimeout() async {
        guard var machine = stateMachine else { return }
        machine.retryTimeoutElapsed()
        stateMachine = machine
        notifyStateChanged()
    }

    private func cancelTimers() {
        countdownTask?.cancel()
        retryTimeoutTask?.cancel()
        countdownTask = nil
        retryTimeoutTask = nil
    }

    private func sendAll(_ commands: [SharePlayMatchCommand]) async {
        for command in commands {
            await coordinator.send(command)
        }
    }

    private func notifyStateChanged() {
        guard let state = stateMachine?.state, let handler = stateChangeHandler else { return }
        handler(state)
    }
}
#endif
