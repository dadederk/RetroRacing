//
//  VisionGameSessionCoordinator.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation
import Observation
import RetroRacingShared

/// Owns one gameplay engine while SwiftUI moves the presentation between scenes.
@MainActor
@Observable
final class VisionGameSessionCoordinator: RacingGameController {
    private(set) var snapshot: GameSnapshot
    private(set) var screen: VisionGameScreen = .menu
    private(set) var presentation: VisionGamePresentation = .classic
    private(set) var presentationTransition: VisionPresentationTransition = .idle
    private(set) var transitionFailure: VisionTransitionFailure?
    private(set) var focusRestorationSequence = 0

    @ObservationIgnored private let engine: any GameEngineProtocol
    @ObservationIgnored private let scheduler: any GameLoopScheduling
    @ObservationIgnored private let transitionDriver: VisionPresentationTransitionDriver
    @ObservationIgnored let tabletopModelRepository: any TabletopModelRepositoryProtocol
    @ObservationIgnored private let controllerInputSource: any GameControllerInputSource
    @ObservationIgnored private var nextTransitionID: UInt64 = 0
    @ObservationIgnored private var activePresentations = Set<VisionGamePresentation>()

    init(
        engine: any GameEngineProtocol,
        scheduler: any GameLoopScheduling,
        delayScheduler: any VisionDelayScheduling,
        windowRouter: any VisionWindowRouting,
        tabletopModelRepository: any TabletopModelRepositoryProtocol,
        controllerInputSource: any GameControllerInputSource,
        transitionTimeout: Duration = .seconds(2)
    ) {
        self.engine = engine
        self.scheduler = scheduler
        self.transitionDriver = VisionPresentationTransitionDriver(
            delayScheduler: delayScheduler,
            windowRouter: windowRouter,
            transitionTimeout: transitionTimeout
        )
        self.tabletopModelRepository = tabletopModelRepository
        self.controllerInputSource = controllerInputSource
        self.snapshot = engine.snapshot
    }

    var isPlaying: Bool { screen == .playing || screen == .gameOver }
    var isUserPaused: Bool { snapshot.activePauseReasons.contains(.user) }
    var windowRoutingStrategy: VisionWindowRoutingStrategy { transitionDriver.strategy }

    func play() {
        transitionDriver.reset()
        screen = .playing
        apply(.start)
        refreshScheduler()
    }

    func restart() {
        screen = .playing
        apply(.restart)
        refreshScheduler()
    }

    func finish() {
        transitionDriver.reset()
        scheduler.stop()
        apply(.finish)
        screen = .menu
        presentation = .classic
        presentationTransition = .idle
    }

    func moveLeft() {
        apply(.move(.left))
    }

    func moveRight() {
        apply(.move(.right))
    }

    func selectLane(_ lane: Int) {
        guard let direction = GameLaneSelectionResolver.direction(
            selectedLane: lane,
            currentLane: snapshot.playerColumn,
            laneCount: snapshot.numberOfColumns
        ) else { return }
        apply(.move(direction))
    }

    func togglePause() {
        guard screen == .playing else { return }
        apply(.setPause(reason: .user, isActive: isUserPaused == false))
    }

    @discardableResult
    func beginPresentationTransition(
        to destination: VisionGamePresentation,
        using actions: VisionWindowActions
    ) -> Bool {
        guard screen == .playing,
              presentation != destination,
              presentationTransition == .idle else {
            return false
        }

        nextTransitionID &+= 1
        let request = VisionPresentationRequest(
            id: VisionPresentationTransitionID(rawValue: nextTransitionID),
            source: presentation,
            destination: destination
        )
        presentationTransition = .moving(request)
        transitionFailure = nil
        apply(.setPause(reason: .presentationTransition, isActive: true))
        transitionDriver.begin(request, using: actions) { [weak self] request, failure, error in
            self?.recover(request: request, failure: failure, underlyingError: error)
        }
        return true
    }

    func presentationDidBecomeReady(
        _ destination: VisionGamePresentation,
        transitionID: VisionPresentationTransitionID,
        using actions: VisionWindowActions
    ) {
        guard case .moving(let request) = presentationTransition,
              request.id == transitionID,
              request.destination == destination else {
            return
        }

        transitionDriver.complete(request, using: actions)
        presentation = destination
        presentationTransition = .idle
        apply(.setPause(reason: .presentationTransition, isActive: false))
        focusRestorationSequence &+= 1
    }

    func destinationDidFail(
        transitionID: VisionPresentationTransitionID,
        failure: VisionTransitionFailure,
        underlyingError: Error? = nil
    ) {
        guard case .moving(let request) = presentationTransition,
              request.id == transitionID else {
            return
        }
        recover(request: request, failure: failure, underlyingError: underlyingError)
    }

    func tabletopDidDisappear(using actions: VisionWindowActions) {
        if case .moving(let request) = presentationTransition {
            guard request.destination != .tabletop else { return }
            return
        }
        guard presentation == .tabletop else { return }

        presentation = .classic
        apply(.setPause(reason: .presentationTransition, isActive: false))
        focusRestorationSequence &+= 1
        if transitionDriver.strategy == .explicit {
            Task {
                try? await actions.open(VisionSceneID.classic)
            }
        }
    }

    func setPresentationActive(_ presentation: VisionGamePresentation, isActive: Bool) {
        let hadActivePresentation = activePresentations.isEmpty == false
        if isActive {
            activePresentations.insert(presentation)
        } else {
            activePresentations.remove(presentation)
        }
        let hasActivePresentation = activePresentations.isEmpty == false
        if hadActivePresentation == false, hasActivePresentation {
            controllerInputSource.start { [weak self] action in
                self?.handleControllerAction(action)
            }
        } else if hadActivePresentation, hasActivePresentation == false {
            controllerInputSource.stop()
        }
        apply(.setPause(reason: .appInactive, isActive: activePresentations.isEmpty))
        refreshScheduler()
    }

    func clearTransitionFailure() {
        transitionFailure = nil
    }

    func currentTransitionID(for destination: VisionGamePresentation) -> VisionPresentationTransitionID? {
        guard case .moving(let request) = presentationTransition,
              request.destination == destination else {
            return nil
        }
        return request.id
    }

    private func tick(elapsedTime: TimeInterval) {
        guard screen == .playing, activePresentations.isEmpty == false else { return }
        apply(.tick(elapsedTime: elapsedTime))
    }

    private func handleControllerAction(_ action: GameControllerAction) {
        switch action {
        case .moveLeft: moveLeft()
        case .moveRight: moveRight()
        case .pauseResume: togglePause()
        @unknown default: break
        }
    }

    private func apply(_ command: GameCommand) {
        let events = engine.handle(command)
        let newSnapshot = engine.snapshot
        if snapshot != newSnapshot {
            snapshot = newSnapshot
        }
        process(events)
    }

    private func process(_ events: [GameEvent]) {
        for event in events {
            switch event {
            case .gameOver:
                screen = .gameOver
                scheduler.stop()
            case .started, .laneChanged, .scoreChanged, .collision, .collisionResolved,
                 .levelChangeImminent, .pauseChanged, .restarted, .finished:
                break
            @unknown default:
                break
            }
        }
    }

    private func recover(
        request: VisionPresentationRequest,
        failure: VisionTransitionFailure,
        underlyingError: Error? = nil
    ) {
        guard presentationTransition == .moving(request) else { return }
        transitionDriver.cancel(request)
        presentation = request.source
        presentationTransition = .idle
        transitionFailure = failure
        apply(.setPause(reason: .presentationTransition, isActive: false))
        focusRestorationSequence &+= 1
        logTransitionFailure(failure, request: request, underlyingError: underlyingError)
    }

    private func logTransitionFailure(
        _ failure: VisionTransitionFailure,
        request: VisionPresentationRequest,
        underlyingError: Error?
    ) {
        var fields: [AppLog.Field] = [
            .reason(failure.rawValue),
            .string("source", String(describing: request.source)),
            .string("destination", String(describing: request.destination)),
            .int64("transitionID", Int64(request.id.rawValue))
        ]
        if let underlyingError {
            fields.append(contentsOf: AppLog.Field.error(underlyingError))
        }
        AppLog.error(
            AppLog.game + AppLog.lifecycle,
            "VISION_PRESENTATION_TRANSITION",
            outcome: .failed,
            fields: fields
        )
    }

    private func refreshScheduler() {
        guard screen == .playing, activePresentations.isEmpty == false else {
            scheduler.stop()
            return
        }
        scheduler.start { [weak self] elapsedTime in
            self?.tick(elapsedTime: elapsedTime)
        }
    }
}
