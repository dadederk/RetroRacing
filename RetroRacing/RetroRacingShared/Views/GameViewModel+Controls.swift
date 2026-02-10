//
//  GameViewModel+Controls.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import SwiftUI

extension GameViewModel {
    func setVolume(_ value: Double) {
        scene?.setSoundVolume(value)
    }

    func togglePause() {
        guard let scene, pauseButtonDisabled == false else { return }
        if pause.isUserPaused {
            scene.unpauseGameplay()
            pause.isUserPaused = false
        } else {
            scene.pauseGameplay()
            pause.isUserPaused = true
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

    func tearDown() {
        controls.cancelFlashTasks()
        scene?.stopAllSounds()
        scene = nil
        delegate = nil
        inputAdapter = nil
    }
}
