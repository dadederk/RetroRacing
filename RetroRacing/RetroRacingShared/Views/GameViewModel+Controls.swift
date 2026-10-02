//
//  GameViewModel+Controls.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

extension GameViewModel {
    struct HelpPauseSnapshot {
        let wasScenePaused: Bool
        let wasUserPaused: Bool
    }

    func setVolume(_ value: Double) {
        scene?.setSoundVolume(value)
    }

    func togglePause() {
        guard let scene, pauseButtonDisabled == false else { return }
        if pause.isHingePaused {
            scene.setHingePauseLock(false)
            pause.isHingePaused = false
            return
        }
        if pause.isUserPaused {
            scene.unpauseGameplay()
            pause.isUserPaused = false
        } else {
            scene.pauseGameplay()
            pause.isUserPaused = true
        }
    }

    func observeHingeAngle(_ angleDegrees: Double?, at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        let detectedMovement = hingeMotion.observe(angleDegrees: angleDegrees, at: uptime)
        if angleDegrees == nil {
            hingeSettleTask?.cancel()
            hingeSettleTask = nil
            return
        }
        guard detectedMovement else { return }

        if let scene, scene.gameState.isPaused == false {
            scene.setHingePauseLock(true)
            pause.isHingePaused = true
        }

        hingeSettleTask?.cancel()
        hingeSettleTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, Task.isCancelled == false else { return }
            self.hingeMotion.settle()
            self.hingeSettleTask = nil
        }
    }

    func flashButton(_ side: ControlSide) {
        switch side {
        case .left: controls.leftFlashTask?.cancel()
        case .right: controls.rightFlashTask?.cancel()
        }

        withAnimation(.easeOut(duration: 0.05)) {
            switch side {
            case .left: controls.leftButtonDown = true
            case .right: controls.rightButtonDown = true
            }
        }

        let task = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(150))
            guard let self else { return }
            withAnimation(.easeOut(duration: 0.05)) {
                switch side {
                case .left: self.controls.leftButtonDown = false
                case .right: self.controls.rightButtonDown = false
                }
            }
        }

        switch side {
        case .left: controls.leftFlashTask = task
        case .right: controls.rightFlashTask = task
        }
    }

    func beginManualHelpPresentation() -> HelpPauseSnapshot {
        let snapshot = HelpPauseSnapshot(
            wasScenePaused: pause.scenePaused,
            wasUserPaused: pause.isUserPaused
        )
        scene?.setOverlayPauseLock(true)
        if snapshot.wasScenePaused == false {
            scene?.pauseGameplay()
        }
        return snapshot
    }

    func beginAutomaticHelpPresentation() -> Bool {
        guard let scene else { return false }
        scene.setOverlayPauseLock(true)
        let shouldResumeOnDismiss = scene.gameState.isPaused == false
        if shouldResumeOnDismiss {
            scene.pauseGameplay()
        }
        return shouldResumeOnDismiss
    }

    func endManualHelpPresentation(using snapshot: HelpPauseSnapshot) {
        scene?.setOverlayPauseLock(false)
        pause.isUserPaused = snapshot.wasUserPaused
        if snapshot.wasScenePaused {
            scene?.pauseGameplay()
        } else {
            scene?.unpauseGameplay()
        }
    }

    func endAutomaticHelpPresentation(shouldResumeOnDismiss: Bool) {
        scene?.setOverlayPauseLock(false)
        if shouldResumeOnDismiss && pause.isUserPaused == false {
            scene?.unpauseGameplay()
        }
    }

    func tearDown() {
        controls.cancelFlashTasks()
        hingeSettleTask?.cancel()
        hingeSettleTask = nil
        scene?.stopAllSounds()
        currentUpcomingFriendMilestone = nil
        scene = nil
        delegate = nil
        inputAdapter = nil
    }
}
