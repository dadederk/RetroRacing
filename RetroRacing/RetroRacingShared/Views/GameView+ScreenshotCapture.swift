//
//  GameView+ScreenshotCapture.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

extension GameView {
    @ViewBuilder
    var screenshotCaptureReadinessOverlay: some View {
        if let screenshotReadinessIdentifier, isScreenshotCaptureReady {
            ScreenshotCaptureReadinessMarker(identifier: screenshotReadinessIdentifier)
        }
    }

    func resetScreenshotCaptureReadiness() {
        screenshotReadinessTask?.cancel()
        screenshotReadinessTask = nil
        isScreenshotCaptureReady = false
    }

    func markScreenshotCaptureReadyIfNeeded() {
        guard isScreenshotCaptureReady == false else { return }
        guard let screenshotLayout else { return }
        guard screenshotReadinessIdentifier != nil || onScreenshotLayoutReady != nil else { return }
        guard screenshotReadinessTask == nil else { return }

        #if os(iOS)
        guard measuredGameSide > 0 else { return }
        #endif

        let effectiveSide = effectiveScreenshotCaptureSide(from: measuredGameSide)
        guard effectiveSide > 0 else { return }

        if model.scene == nil {
            model.setupSceneIfNeeded(side: effectiveSide, volume: selectedSoundEffectsVolume)
        }

        screenshotReadinessTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(screenshotReadinessDelayMilliseconds))
            for _ in 0..<100 {
                guard Task.isCancelled == false else { return }
                #if os(iOS)
                guard measuredGameSide > 0 else {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }
                #endif

                let side = effectiveScreenshotCaptureSide(from: measuredGameSide)
                guard side > 0 else {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }

                if model.scene == nil {
                    model.setupSceneIfNeeded(side: side, volume: selectedSoundEffectsVolume)
                }

                guard let scene = model.scene, scene.isReadyToApplyScreenshotLayout else {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }

                model.applyScreenshotLayout(screenshotLayout, to: scene)
                isScreenshotCaptureReady = true
                screenshotReadinessTask = nil
                onScreenshotLayoutReady?()
                return
            }
        }
    }

    private var screenshotReadinessDelayMilliseconds: Int {
        #if os(macOS)
        if screenshotLayout != nil {
            return 900
        }
        #endif
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 1_500
        }
        #endif
        return 300
    }

    func effectiveScreenshotCaptureSide(from side: CGFloat) -> CGFloat {
        if side > 0 { return side }
        if measuredGameSide > 0 { return measuredGameSide }
        guard screenshotLayout != nil else { return 0 }
        #if os(macOS)
        return ScreenshotCaptureWindowConfiguration.macLandscapeContentSize.width
        #else
        return 0
        #endif
    }
}
