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
    static let rootName = "tabletop-collision-pose"
    static let burstName = "tabletop-impact-burst"

    let root = Entity()
    let burst = Entity()
    let playerCar: Entity
    let rivalCar: Entity
    private(set) var isPulsing = false
    private var reduceMotion: Bool
    private var pulseTask: Task<Void, Never>?
    private var presentedPhase: GamePhase?

    init(
        playerCar: Entity,
        rivalCar: Entity,
        visualStyle: TabletopSceneVisualStyle
    ) {
        self.playerCar = playerCar
        self.rivalCar = rivalCar
        reduceMotion = visualStyle.reduceMotion
        root.name = Self.rootName
        root.isEnabled = false
        burst.name = Self.burstName
        playerCar.position = SIMD3(-0.026, 0, 0.012)
        playerCar.orientation = simd_quatf(angle: 0.17, axis: SIMD3(0, 1, 0))
        rivalCar.position = SIMD3(0.026, 0.006, -0.012)
        rivalCar.orientation = simd_quatf(angle: -0.20, axis: SIMD3(0, 1, 0))
        burst.position.y = 0.055
        root.addChild(playerCar)
        root.addChild(rivalCar)
        root.addChild(burst)
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
        let phaseChanged = presentedPhase != phase
        presentedPhase = phase
        switch phase {
        case .collision:
            if reduceMotion {
                stopPulsing(isVisible: true)
            } else if phaseChanged {
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
            guard let self else { return }
            for pulse in 0..<3 {
                guard Task.isCancelled == false else { break }
                root.isEnabled = true
                do {
                    try await Task.sleep(for: .milliseconds(120))
                } catch {
                    break
                }
                root.isEnabled = false
                guard pulse < 2 else { continue }
                do {
                    try await Task.sleep(for: .milliseconds(120))
                } catch {
                    break
                }
            }
            guard Task.isCancelled == false else { return }
            root.isEnabled = true
            isPulsing = false
            pulseTask = nil
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
        burst.addChild(core)

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
            burst.addChild(ray)
        }
    }
}
