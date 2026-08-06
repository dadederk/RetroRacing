//
//  TabletopSceneFactory.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import RetroRacingShared

@MainActor
struct TabletopSceneFactory {
    let modelRepository: any TabletopModelRepositoryProtocol

    func makeScene(
        snapshot: GameSnapshot,
        visualStyle: TabletopSceneVisualStyle = .standard
    ) async throws -> TabletopScene {
        let canonicalCars = try await modelRepository.canonicalCars()
        return TabletopScene(
            canonicalPlayerCar: canonicalCars.player,
            canonicalRivalCar: canonicalCars.rival,
            snapshot: snapshot,
            visualStyle: visualStyle
        )
    }
}
