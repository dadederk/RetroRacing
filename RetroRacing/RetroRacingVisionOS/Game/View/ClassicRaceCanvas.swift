//
//  ClassicRaceCanvas.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import RetroRacingShared
import SwiftUI

struct ClassicRaceCanvas: View {
    @Environment(VisionGameSessionCoordinator.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @AppStorage(DirectTouchSetting.conditionalDefaultStorageKey) private var directTouchData = Data()
    @AccessibilityFocusState private var isAccessibilityFocused: Bool
    let snapshot: GameSnapshot
    let theme: any GameTheme

    var body: some View {
        GeometryReader { geometry in
            Canvas(opaque: true, rendersAsynchronously: true) { context, size in
                drawTrack(in: &context, size: size)
                drawCars(in: &context, size: size)
            }
            .gesture(
                SpatialTapGesture().onEnded { value in
                    selectLane(at: value.location.x, width: geometry.size.width)
                }
            )
        }
        .compositingGroup()
        .clipShape(.rect(cornerRadius: 28))
        .accessibilityDirectTouch(isDirectTouchEnabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(GameLocalizedStrings.string("vision_classic_track"))
        .accessibilityValue(accessibilityValue)
        .accessibilityInputLabels([
            GameLocalizedStrings.string("vision_classic_track"),
            GameLocalizedStrings.string("vision_race_track_input_label")
        ])
        .accessibilityAction(named: GameLocalizedStrings.string("move_left"), session.moveLeft)
        .accessibilityAction(named: GameLocalizedStrings.string("move_right"), session.moveRight)
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: session.moveRight()
            case .decrement: session.moveLeft()
            @unknown default: break
            }
        }
        .accessibilityFocused($isAccessibilityFocused)
        .onChange(of: session.focusRestorationSequence) {
            isAccessibilityFocused = true
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.18), value: snapshot.grid)
    }

    private func drawTrack(in context: inout GraphicsContext, size: CGSize) {
        let trackColor = colorSchemeContrast == .increased
            ? Color.black
            : theme.roadExteriorColor() ?? theme.gridCellColor()
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(trackColor))

        let road = roadPath(size: size)
        context.fill(road, with: .color(theme.gridCellColor()))

        for divider in [1.0 / 3.0, 2.0 / 3.0] {
            var path = Path()
            let topX = roadLeft(at: 0, size: size) + roadWidth(at: 0, size: size) * divider
            let bottomX = roadLeft(at: 1, size: size) + roadWidth(at: 1, size: size) * divider
            path.move(to: CGPoint(x: topX, y: size.height * 0.08))
            path.addLine(to: CGPoint(x: bottomX, y: size.height * 0.96))
            context.stroke(
                path,
                with: .color(theme.roadLineColor(
                    isIncreaseContrastEnabled: colorSchemeContrast == .increased
                )),
                style: StrokeStyle(
                    lineWidth: max(2, size.width * 0.006),
                    dash: differentiateWithoutColor ? [12, 8] : []
                )
            )
        }

        for row in snapshot.safetyMarkerRows {
            let depth = rowDepth(row)
            let y = carCenterY(depth: depth, size: size)
            let left = roadLeft(at: depth, size: size)
            let width = roadWidth(at: depth, size: size)
            context.fill(
                Path(CGRect(x: left, y: y - 3, width: width, height: 6)),
                with: .color(theme.lapMarkerColor(
                    isIncreaseContrastEnabled: colorSchemeContrast == .increased
                ))
            )
        }
    }

    private func drawCars(in context: inout GraphicsContext, size: CGSize) {
        let spriteBundle = VisionThemeSpriteAssets.bundle(for: theme)
        let playerAssetName = theme.playerCarSprite() ?? "playersCar-LCD"
        let playerImage = context.resolve(Image(
            decorative: playerAssetName,
            bundle: spriteBundle
        ))
        let rivalImage = context.resolve(Image(
            decorative: theme.rivalCarSprite() ?? "rivalsCar-LCD",
            bundle: spriteBundle
        ))
        let crashImage = context.resolve(Image(
            decorative: VisionThemeSpriteAssets.crashAssetName(for: theme),
            bundle: spriteBundle
        ))

        for row in snapshot.grid.indices {
            for column in snapshot.grid[row].indices {
                let occupant = snapshot.grid[row][column]
                guard occupant != .empty else { continue }
                let depth = rowDepth(row)
                let laneWidth = roadWidth(at: depth, size: size) / 3
                let width = laneWidth * 0.8
                let height = width * (600.0 / 768.0)
                let centerX = roadLeft(at: depth, size: size) + laneWidth * (CGFloat(column) + 0.5)
                let centerY = carCenterY(depth: depth, size: size)
                let destination = CGRect(
                    x: centerX - width / 2,
                    y: centerY - height / 2,
                    width: width,
                    height: height
                )
                switch occupant {
                case .player:
                    context.draw(playerImage, in: destination)
                case .rival:
                    context.draw(rivalImage, in: destination)
                case .crash:
                    context.draw(crashImage, in: destination)
                case .empty:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func roadPath(size: CGSize) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: roadLeft(at: 0, size: size), y: size.height * 0.08))
        path.addLine(to: CGPoint(x: roadLeft(at: 1, size: size), y: size.height * 0.96))
        path.addLine(to: CGPoint(x: roadLeft(at: 1, size: size) + roadWidth(at: 1, size: size), y: size.height * 0.96))
        path.addLine(to: CGPoint(x: roadLeft(at: 0, size: size) + roadWidth(at: 0, size: size), y: size.height * 0.08))
        path.closeSubpath()
        return path
    }

    private func rowDepth(_ row: Int) -> CGFloat {
        CGFloat(row + 1) / CGFloat(max(snapshot.numberOfRows, 1))
    }

    private func roadWidth(at depth: CGFloat, size: CGSize) -> CGFloat {
        size.width * (0.38 + (0.54 * depth))
    }

    private func roadLeft(at depth: CGFloat, size: CGSize) -> CGFloat {
        (size.width - roadWidth(at: depth, size: size)) / 2
    }

    private func carCenterY(depth: CGFloat, size: CGSize) -> CGFloat {
        size.height * (0.06 + (0.82 * depth))
    }

    private var isDirectTouchEnabled: Bool {
        _ = directTouchData
        return VisionGameInteractionPolicy.isDirectTouchEnabled(
            on: .classicBoard,
            userEnabled: DirectTouchPreference.currentSelection(
                from: InfrastructureDefaults.userDefaults
            )
        )
    }

    private var accessibilityValue: String {
        GameLocalizedStrings.format(
            "vision_race_status_format",
            snapshot.score,
            snapshot.lives,
            snapshot.playerColumn + 1,
            snapshot.numberOfColumns,
            phaseDescription
        )
    }

    private var phaseDescription: String {
        switch snapshot.phase {
        case .ready: GameLocalizedStrings.string("vision_state_ready")
        case .running: GameLocalizedStrings.string("vision_state_racing")
        case .paused: GameLocalizedStrings.string("vision_state_paused")
        case .collision: GameLocalizedStrings.string("vision_state_collision")
        case .gameOver: GameLocalizedStrings.string("vision_game_over")
        case .finished: GameLocalizedStrings.string("vision_state_finished")
        @unknown default: GameLocalizedStrings.string("vision_state_ready")
        }
    }

    private func selectLane(at horizontalLocation: CGFloat, width: CGFloat) {
        guard let lane = VisionGameInteractionPolicy.lane(
            at: horizontalLocation,
            width: width,
            laneCount: snapshot.numberOfColumns
        ) else { return }
        session.selectLane(lane)
    }
}
