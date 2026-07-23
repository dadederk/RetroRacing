//
//  GroupActivitiesSharePlayMatchService.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 22/07/2026.
//

#if canImport(GroupActivities) && os(iOS)
import GroupActivities
import Foundation
import RetroRacingShared

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
    private var lastNotifiedStateName: String?
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
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_ACTIVATE",
            outcome: .requested,
            fields: [.bool("pendingHostActivation", pendingHostActivation)]
        )
        let activity = RetroRacingGroupActivity()
        do {
            let activated = try await activity.activate()
            if activated {
                AppLog.info(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_ACTIVATE",
                    outcome: .succeeded,
                    fields: [.bool("pendingHostActivation", pendingHostActivation)]
                )
            } else {
                pendingHostActivation = false
                AppLog.info(.game, "SHAREPLAY_ACTIVATE", outcome: .cancelled)
            }
        } catch {
            pendingHostActivation = false
            AppLog.error(.game, "SHAREPLAY_ACTIVATE", outcome: .failed, fields: AppLog.Field.error(error))
        }
    }

    public func prepareHostActivation() async {
        pendingHostActivation = true
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_ACTIVATION",
            outcome: .requested,
            fields: [.bool("pendingHostActivation", pendingHostActivation)]
        )
    }

    public func cancelHostActivation() async {
        let wasPending = pendingHostActivation
        pendingHostActivation = false
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_ACTIVATE",
            outcome: .cancelled,
            fields: [.bool("wasPendingHostActivation", wasPending)]
        )
    }

    /// Awaits both host-activated and system-activated (incoming) sessions for this activity.
    /// Intended to run for the lifetime of the app in a single long-lived `.task`.
    public func observeIncomingSessions() async {
        guard sessionsTask == nil else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_SESSION_OBSERVER",
                outcome: .ignored,
                fields: [.reason("already_running")]
            )
            return
        }
        AppLog.info(AppLog.lifecycle + AppLog.game, "SHAREPLAY_SESSION_OBSERVER", outcome: .started)
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
        guard var machine = stateMachine else {
            logHostStartBlocked(reason: "missing_state_machine")
            return
        }
        guard machine.localRole == .host else {
            logHostStartBlocked(reason: "not_host", machine: machine)
            return
        }
        guard case .waitingForFriend = machine.state else {
            logHostStartBlocked(reason: "not_waiting_for_friend", machine: machine)
            return
        }
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_START_ROUND",
            outcome: .requested,
            fields: [
                .int("generation", sessionGeneration),
                .string("difficulty", difficulty.rawValue)
            ]
        )
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
    }

    public func reportLocalElimination(finalScore: Int) async {
        guard var machine = stateMachine, case .inRound = machine.state else { return }
        var commands = machine.updateLocalScore(finalScore, lives: 0)
        commands += machine.localPlayerEliminated(finalScore: finalScore)
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

        let wasPendingHostActivation = pendingHostActivation
        let previousStateName = stateMachine?.state.diagnosticName
        let role: SharePlayPlayerRole = pendingHostActivation ? .host : .guest
        pendingHostActivation = false
        hasTwoParticipants = false
        opponentDisplayName = nil
        lastNotifiedStateName = nil

        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_SESSION_HANDLE",
            outcome: .started,
            fields: [
                .int("generation", generation),
                .string("role", role.rawValue),
                .bool("wasPendingHostActivation", wasPendingHostActivation),
                .string("previousState", previousStateName)
            ]
        )

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
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_SESSION_HANDLE",
            outcome: .completed,
            fields: [
                .int("generation", generation),
                .string("state", machine.state.diagnosticName),
                .string("role", role.rawValue)
            ]
        )
    }

    private func updateOpponentDisplayName(_ name: String?) {
        opponentDisplayName = name
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_OPPONENT_NAME",
            outcome: .completed,
            fields: [
                .int("generation", sessionGeneration),
                .string("opponentName", AppLog.redactedPlayer(name))
            ]
        )
        notifyStateChanged()
    }

    private func participantsBecameReady() async {
        hasTwoParticipants = true
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_PARTICIPANTS_READY",
            outcome: .completed,
            fields: [
                .int("generation", sessionGeneration),
                .string("state", stateMachine?.state.diagnosticName),
                .bool("remoteReady", stateMachine?.isRemoteReady == true)
            ]
        )
        await autoStartHostRoundIfReady()
    }

    private func autoStartHostRoundIfReady() async {
        guard hasTwoParticipants else {
            logAutoStartBlocked(reason: "waiting_for_two_participants")
            return
        }
        guard stateMachine?.isRemoteReady == true else {
            logAutoStartBlocked(reason: "waiting_for_remote_ready")
            return
        }
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_AUTO_START_ROUND",
            outcome: .requested,
            fields: [
                .int("generation", sessionGeneration),
                .string("state", stateMachine?.state.diagnosticName),
                .string("role", stateMachine?.localRole.rawValue)
            ]
        )
        await hostStartRoundIfReady(difficulty: difficultyProvider())
    }

    private func handleIncoming(_ command: SharePlayMatchCommand) async {
        guard var machine = stateMachine else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COMMAND_RECEIVE",
                outcome: .ignored,
                fields: [
                    .reason("missing_state_machine"),
                    .int("generation", sessionGeneration),
                    .string("command", command.diagnosticName)
                ]
            )
            return
        }
        let previousState = machine.state
        let shouldLogCommandLifecycle = shouldLogLifecycle(for: command)
        if shouldLogCommandLifecycle {
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COMMAND_RECEIVE",
                outcome: .completed,
                fields: [
                    .int("generation", sessionGeneration),
                    .string("command", command.diagnosticName),
                    .string("previousState", previousState.diagnosticName)
                ]
            )
        }
        let commands = machine.receive(command)
        stateMachine = machine
        await sendAll(commands)
        let previousStateName = previousState.diagnosticName
        let newStateName = machine.state.diagnosticName
        let didStateKindChange = previousStateName != newStateName
        if didStateKindChange || shouldLogCommandLifecycle {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_COMMAND_APPLY",
                outcome: .completed,
                fields: [
                    .int("generation", sessionGeneration),
                    .string("command", command.diagnosticName),
                    .string("previousState", previousStateName),
                    .string("newState", newStateName),
                    .int("emittedCommands", commands.count)
                ]
            )
        }

        if case .countdown = machine.state {
            scheduleCountdownCompletion()
        } else {
            cancelCountdown()
        }
        if case .retryWaiting = machine.state {
            scheduleRetryTimeoutIfNeeded()
        } else {
            cancelRetryTimeout()
        }
        notifyStateChanged()

        if case .waitingForFriend = machine.state {
            await autoStartHostRoundIfReady()
        }
    }

    private func handleDisconnected(generation: Int) async {
        guard generation == sessionGeneration else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_DISCONNECTED",
                outcome: .ignored,
                fields: [
                    .reason("stale_generation"),
                    .int("callbackGeneration", generation),
                    .int("sessionGeneration", sessionGeneration)
                ]
            )
            return
        }
        guard var machine = stateMachine else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_DISCONNECTED",
                outcome: .ignored,
                fields: [
                    .reason("missing_state_machine"),
                    .int("generation", generation)
                ]
            )
            return
        }
        let previousState = machine.state
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_DISCONNECTED",
            outcome: .started,
            fields: [
                .int("generation", generation),
                .string("previousState", previousState.diagnosticName)
            ]
        )
        cancelTimers()
        machine.disconnected()
        stateMachine = machine
        notifyStateChanged()
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_DISCONNECTED",
            outcome: .completed,
            fields: [
                .int("generation", generation),
                .string("previousState", previousState.diagnosticName),
                .string("newState", machine.state.diagnosticName)
            ]
        )
    }

    // MARK: - Timers

    private func scheduleCountdownCompletion() {
        cancelCountdown()
        guard case .countdown(let startAt, _) = stateMachine?.state else { return }
        let delay = max(0, startAt.timeIntervalSinceNow)
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COUNTDOWN_TIMER",
            outcome: .deferred,
            fields: [
                .int("generation", sessionGeneration),
                .double("delaySeconds", delay)
            ]
        )
        countdownTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await self.completeCountdown()
        }
    }

    private func completeCountdown() async {
        guard var machine = stateMachine else { return }
        countdownTask = nil
        let previousState = machine.state
        machine.beginRound()
        stateMachine = machine
        notifyStateChanged()
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_COUNTDOWN_TIMER",
            outcome: .completed,
            fields: [
                .int("generation", sessionGeneration),
                .string("previousState", previousState.diagnosticName),
                .string("newState", machine.state.diagnosticName)
            ]
        )
    }

    private func scheduleRetryTimeoutIfNeeded() {
        cancelRetryTimeout()
        guard case .retryWaiting(_, _, let deadline) = stateMachine?.state else { return }
        let delay = max(0, deadline.timeIntervalSinceNow)
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_RETRY_TIMER",
            outcome: .deferred,
            fields: [
                .int("generation", sessionGeneration),
                .double("delaySeconds", delay)
            ]
        )
        retryTimeoutTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard Task.isCancelled == false else { return }
            await self.completeRetryTimeout()
        }
    }

    private func completeRetryTimeout() async {
        guard var machine = stateMachine else { return }
        retryTimeoutTask = nil
        let previousState = machine.state
        machine.retryTimeoutElapsed()
        stateMachine = machine
        notifyStateChanged()
        AppLog.warning(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_RETRY_TIMER",
            outcome: .completed,
            fields: [
                .int("generation", sessionGeneration),
                .string("previousState", previousState.diagnosticName),
                .string("newState", machine.state.diagnosticName)
            ]
        )
    }

    private func cancelCountdown() {
        countdownTask?.cancel()
        countdownTask = nil
    }

    private func cancelRetryTimeout() {
        retryTimeoutTask?.cancel()
        retryTimeoutTask = nil
    }

    private func cancelTimers() {
        cancelCountdown()
        cancelRetryTimeout()
    }

    private func sendAll(_ commands: [SharePlayMatchCommand]) async {
        for command in commands {
            if shouldLogLifecycle(for: command) {
                AppLog.debug(
                    AppLog.lifecycle + AppLog.game,
                    "SHAREPLAY_COMMAND_SEND",
                    outcome: .requested,
                    fields: [
                        .int("generation", sessionGeneration),
                        .string("command", command.diagnosticName),
                        .string("state", stateMachine?.state.diagnosticName)
                    ]
                )
            }
            await coordinator.send(command)
        }
    }

    private func shouldLogLifecycle(for command: SharePlayMatchCommand) -> Bool {
        switch command {
        case .scoreUpdate:
            return false
        case .sessionReady,
             .roundStart,
             .playerEliminated,
             .roundResult,
             .retryReady,
             .sessionFinished,
             .sessionAborted:
            return true
        @unknown default:
            return true
        }
    }

    private func notifyStateChanged() {
        guard let state = stateMachine?.state else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .skipped,
                fields: [
                    .reason("missing_state_machine"),
                    .int("generation", sessionGeneration)
                ]
            )
            return
        }
        guard let handler = stateChangeHandler else {
            AppLog.warning(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .skipped,
                fields: [
                    .reason("missing_handler"),
                    .int("generation", sessionGeneration),
                    .string("state", state.diagnosticName)
                ]
            )
            return
        }
        let stateName = state.diagnosticName
        if lastNotifiedStateName != stateName {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .completed,
                fields: [
                    .int("generation", sessionGeneration),
                    .string("previousState", lastNotifiedStateName),
                    .string("newState", stateName),
                    .string("role", stateMachine?.localRole.rawValue)
                ]
            )
        } else {
            AppLog.debug(
                AppLog.lifecycle + AppLog.game,
                "SHAREPLAY_STATE_NOTIFY",
                outcome: .completed,
                fields: [
                    .int("generation", sessionGeneration),
                    .string("newState", stateName),
                    .bool("sameStateKind", true)
                ]
            )
        }
        lastNotifiedStateName = stateName
        handler(state)
    }

    private func logHostStartBlocked(reason: String, machine: SharePlayMatchStateMachine? = nil) {
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_HOST_START_ROUND",
            outcome: .blocked,
            fields: [
                .reason(reason),
                .int("generation", sessionGeneration),
                .string("state", machine?.state.diagnosticName ?? stateMachine?.state.diagnosticName),
                .string("role", machine?.localRole.rawValue ?? stateMachine?.localRole.rawValue)
            ]
        )
    }

    private func logAutoStartBlocked(reason: String) {
        AppLog.debug(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_AUTO_START_ROUND",
            outcome: .blocked,
            fields: [
                .reason(reason),
                .int("generation", sessionGeneration),
                .bool("hasTwoParticipants", hasTwoParticipants),
                .bool("remoteReady", stateMachine?.isRemoteReady == true),
                .string("state", stateMachine?.state.diagnosticName),
                .string("role", stateMachine?.localRole.rawValue)
            ]
        )
    }
}
#endif
