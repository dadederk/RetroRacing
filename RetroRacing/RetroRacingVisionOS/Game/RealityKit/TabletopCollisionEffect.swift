//
//  TabletopCollisionEffect.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 07/08/2026.
//

import RealityKit
import RetroRacingShared
import UIKit

@MainActor
final class TabletopCollisionEffect {
    static let rootName = "tabletop-impact-burst"

    let root = Entity()
    private(set) var isPulsing = false
    private var reduceMotion: Bool
    private var pulseTask: Task<Void, Never>?

    init(visualStyle: TabletopSceneVisualStyle) {
        reduceMotion = visualStyle.reduceMotion
        root.name = Self.rootName
        root.isEnabled = false
        addBurstGeometry(visualStyle: visualStyle)
    }

    deinit {
        pulseTask?.cancel()
    }

    func setReduceMotionEnabled(_ isEnabled: Bool) {
        guard reduceMotion != isEnabled else { return }
        reduceMotion = isEnabled
        if isEnabled, isPulsing {
            stopPulsing(isVisible: true)
        }
    }

    func update(phase: GamePhase, position: SIMD3<Float>) {
        root.position = position
        switch phase {
        case .collision:
            if reduceMotion {
                stopPulsing(isVisible: true)
            } else {
                startPulsing()
            }
        case .gameOver:
            stopPulsing(isVisible: true)
        case .ready, .running, .paused, .finished:
            stopPulsing(isVisible: false)
        @unknown default:
            stopPulsing(isVisible: false)
        }
    }

    private func startPulsing() {
        guard pulseTask == nil else { return }
        root.isEnabled = true
        isPulsing = true
        pulseTask = Task { [weak self] in
            var isVisible = true
            while Task.isCancelled == false {
                self?.root.isEnabled = isVisible
                do {
                    try await Task.sleep(for: .milliseconds(120))
                } catch {
                    break
                }
                isVisible.toggle()
            }
        }
    }

    private func stopPulsing(isVisible: Bool) {
        pulseTask?.cancel()
        pulseTask = nil
        isPulsing = false
        root.isEnabled = isVisible
    }

    private func addBurstGeometry(visualStyle: TabletopSceneVisualStyle) {
        let emphasizesShape = visualStyle.increasedContrast
            || visualStyle.differentiateWithoutColor
        let coreMaterial = UnlitMaterial(color: emphasizesShape ? .white : .yellow)
        let rayMaterial = UnlitMaterial(color: emphasizesShape ? .yellow : .orange)

        let core = ModelEntity(
            mesh: .generateBox(size: SIMD3(repeating: 0.072), cornerRadius: 0.004),
            materials: [coreMaterial]
        )
        core.orientation = simd_quatf(angle: .pi / 4, axis: SIMD3(0, 1, 1))
        root.addChild(core)

        let raySize = SIMD3<Float>(0.018, 0.12, 0.018)
        for index in 0..<6 {
            let angle = Float(index) * .pi / 3
            let ray = ModelEntity(
                mesh: .generateBox(size: raySize, cornerRadius: 0.002),
                materials: [rayMaterial]
            )
            ray.position = SIMD3(cos(angle) * 0.055, 0.015, sin(angle) * 0.055)
            ray.orientation = simd_quatf(
                angle: .pi / 3,
                axis: SIMD3(-sin(angle), 0, cos(angle))
            )
            root.addChild(ray)
        }
    }
}
