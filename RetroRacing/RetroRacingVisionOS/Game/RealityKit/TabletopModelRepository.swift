//
//  TabletopModelRepository.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import RealityKit
import RetroRacingShared

enum TabletopModelError: String, Error, Equatable {
    case resourceUnavailable
    case invalidHierarchy
    case invalidBounds
    case invisibleGeometry
    case missingMaterials
}

@MainActor
struct TabletopCanonicalCars {
    let player: Entity
    let rival: Entity
}

@MainActor
protocol TabletopModelRepositoryProtocol: AnyObject {
    func canonicalCars() async throws -> TabletopCanonicalCars
}

/// Loads and validates both shipping models once for cloning into the fixed scene pool.
@MainActor
final class TabletopModelRepository: TabletopModelRepositoryProtocol {
    private enum Role {
        case player
        case rival

        var rootName: String {
            switch self {
            case .player: "PlayerCar64Bit"
            case .rival: "RivalCar64Bit"
            }
        }

        var requiredNames: [String] {
            let shared = [
                "RedMid_MainBody",
                "RedHighlight_CenterSpine",
                "Graphite_Undertray",
                "Steel_Exhaust1",
                "Steel_Exhaust2",
                "Steel_Exhaust3",
                "Steel_Exhaust4",
            ]
            switch self {
            case .player:
                return shared + [
                    "Ivory_HelmetXLeft",
                    "Ivory_HelmetXRight",
                    "Amber_TailLightLeft",
                    "Amber_TailLightRight",
                ]
            case .rival:
                return shared + [
                    "Amber_RivalTailLightStackLeft",
                    "Amber_RivalTailLightStackRight",
                ]
            }
        }

        var forbiddenNames: [String] {
            switch self {
            case .player:
                ["Amber_RivalTailLightStackLeft", "Amber_RivalTailLightStackRight"]
            case .rival:
                [
                    "Ivory_HelmetXLeft",
                    "Ivory_HelmetXRight",
                    "Amber_TailLightLeft",
                    "Amber_TailLightRight",
                ]
            }
        }
    }

    private let playerResourceName: String
    private let rivalResourceName: String
    private let bundle: Bundle
    private var cachedCanonicalCars: TabletopCanonicalCars?
    private(set) var loadCount = 0

    init(playerResourceName: String, rivalResourceName: String, bundle: Bundle) {
        self.playerResourceName = playerResourceName
        self.rivalResourceName = rivalResourceName
        self.bundle = bundle
    }

    func canonicalCars() async throws -> TabletopCanonicalCars {
        if let cachedCanonicalCars {
            return cachedCanonicalCars
        }
        let player = try await load(resourceName: playerResourceName, role: .player)
        let rival = try await load(resourceName: rivalResourceName, role: .rival)
        let cars = TabletopCanonicalCars(player: player, rival: rival)
        cachedCanonicalCars = cars
        return cars
    }

    private func load(resourceName: String, role: Role) async throws -> Entity {
        let entity: Entity
        do {
            loadCount += 1
            entity = try await Entity(named: resourceName, in: bundle)
        } catch {
            AppLog.error(
                AppLog.assets + AppLog.game,
                "VISION_MODEL_LOAD",
                outcome: .failed,
                fields: [.reason(TabletopModelError.resourceUnavailable.rawValue)]
                    + AppLog.Field.error(error)
            )
            throw TabletopModelError.resourceUnavailable
        }
        try validate(entity, role: role)
        return entity
    }

    private func validate(_ entity: Entity, role: Role) throws {
        let names = Set(allNames(in: entity))
        let requiredNames = [role.rootName] + role.requiredNames
        guard requiredNames.allSatisfy(names.contains),
              role.forbiddenNames.allSatisfy({ names.contains($0) == false }) else {
            try throwLogged(.invalidHierarchy)
        }

        let bounds = entity.visualBounds(relativeTo: nil)
        let extents = bounds.extents
        guard bounds.isEmpty == false,
              extents.x.isFinite, extents.y.isFinite, extents.z.isFinite,
              extents.x > 0, extents.y > 0, extents.z > 0,
              extents.x < 100, extents.y < 100, extents.z < 100 else {
            try throwLogged(.invalidBounds)
        }

        let enabledModels = enabledModelComponents(in: entity, ancestorsEnabled: true)
        guard enabledModels.isEmpty == false else {
            try throwLogged(.invisibleGeometry)
        }
        guard enabledModels.allSatisfy({ $0.materials.isEmpty == false }) else {
            try throwLogged(.missingMaterials)
        }
    }

    private func enabledModelComponents(
        in entity: Entity,
        ancestorsEnabled: Bool
    ) -> [ModelComponent] {
        let isEnabled = ancestorsEnabled && entity.isEnabled
        var models = [ModelComponent]()
        if isEnabled, let model = entity.components[ModelComponent.self] {
            models.append(model)
        }
        for child in entity.children {
            models.append(contentsOf: enabledModelComponents(
                in: child,
                ancestorsEnabled: isEnabled
            ))
        }
        return models
    }

    private func allNames(in entity: Entity) -> [String] {
        [entity.name] + entity.children.flatMap(allNames(in:))
    }

    private func throwLogged(_ error: TabletopModelError) throws -> Never {
        AppLog.error(
            AppLog.assets + AppLog.game,
            "VISION_MODEL_VALIDATION",
            outcome: .failed,
            fields: [.reason(error.rawValue)]
        )
        throw error
    }
}
