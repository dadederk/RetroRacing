//
//  GameScene+Grid.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SpriteKit

private enum RoadLineConfiguration {
    static let innerMaskAssetName = "laneInnerMask"
    static let outerMaskAssetName = "laneOuterMask"
    static let dashedLineNodeName = "road_dash_line"
    static let verticalSeparatorNodeName = "vertical_grid_line"
    static let lineZPosition: CGFloat = 1.5
    static let minimumContrast: Double = 4.5
    static let innerLineSpreadFactor: CGFloat = 0.6
}

private enum HorizontalRoadAnchor {
    case leftEdge
    case rightEdge
    case centerLeftPerspective
    case centerRightPerspective
}

/// Grid construction and sprite placement helpers scoped to GameScene.
extension GameScene {

    func createGrid() {
        for column in 0 ..< gridState.numberOfColumns {
            for row in 0 ..< gridState.numberOfRows {
                let cell = createCell(column: column, row: row)
                addChild(cell)
            }
        }
    }

    func gridCellFillColor() -> SKColor {
        guard let theme else { return gameBackgroundColor }
        return theme.gridCellColor().skColor
    }

    func createCell(column: Int, row: Int) -> SKShapeNode {
        let cellSize = sizeForCell()
        let origin = positionForCellIn(column: column, row: row, size: cellSize)
        let frame = CGRect(origin: origin, size: cellSize)
        if row == 0 && column == 0 {
            AppLog.log(AppLog.assets, "createGrid scene.size=\(size) cellSize=\(cellSize) firstCell origin=\(origin) frame=\(frame)")
        }
        let cell = SKShapeNode(rect: frame)
        cell.name = nameForCell(column: column, row: row)
        cell.fillColor = gridCellFillColor()
        cell.strokeColor = .clear
        cell.lineWidth = 0
        cell.zPosition = 1

        return cell
    }

    func nameForCell(column: Int, row: Int) -> String {
        "\(column)x\(row)"
    }

    func gridCell(column: Int, row: Int) -> SKShapeNode {
        guard let cell = childNode(withName: nameForCell(column: column, row: row)) as? SKShapeNode else {
            fatalError("Failed to retrieve grid cell at \(column) x \(row)")
        }

        return cell
    }

    func sizeForCell() -> CGSize {
        let width = size.width / CGFloat(gridState.numberOfColumns)
        let height = size.height / CGFloat(gridState.numberOfRows)
        return CGSize(width: width, height: height)
    }

    func positionForCellIn(column: Int, row: Int, size: CGSize) -> CGPoint {
        let x = (CGFloat(column) * size.width)
        let y = (CGFloat(gridState.numberOfRows - row - 1) * size.height)
        return CGPoint(x: x, y: y)
    }

    var roadDashEmptyRowIndex: Int {
        (roadDashPhase + gridState.numberOfRows - 1) % gridState.numberOfRows
    }

    func gridStateDidUpdate(
        _ gridState: GridState,
        shouldPlayFeedback: Bool = true,
        notifyDelegate: Bool = true,
        feedbackEvent: AudioFeedbackEvent = .tick
    ) {
        updateGrid(withGridState: gridState)
        if shouldPlayFeedback {
            playFeedback(event: feedbackEvent)
        }
        if notifyDelegate {
            gameDelegate?.gameSceneDidUpdateGrid(self)
        }
    }

    func resetScene() {
        for sprite in spritesForGivenState {
            sprite.removeFromParent()
        }
        spritesForGivenState.removeAll()

        for lineOverlay in lineOverlayNodes {
            lineOverlay.removeFromParent()
        }
        lineOverlayNodes.removeAll()
    }

    /// Resizes the scene when the hosting view changes (rotation, split view) without restarting gameplay.
    /// Rebuilds the grid using the current game state so visuals stay in sync with logic.
    public func resizeScene(to newSize: CGSize) {
        guard newSize.width > 1,
              newSize.height > 1 else { return }
        if let lastSize = lastConfiguredSize, lastSize == newSize { return }

        lastConfiguredSize = newSize
        size = newSize
        anchorPoint = CGPoint(x: 0, y: 0)
        scaleMode = .aspectFit

        removeAllChildren()
        spritesForGivenState.removeAll()
        lineOverlayNodes.removeAll()
        createGrid()
        gridStateDidUpdate(gridState, shouldPlayFeedback: false)
    }

    func updateGrid(withGridState gridState: GridState) {
        resetScene()
        styleGridCells()
        renderLineOverlays()
        renderCarSprites(gridState: gridState)
    }

    private func styleGridCells() {
        for row in 0..<gridState.numberOfRows {
            for column in 0..<gridState.numberOfColumns {
                let cell = gridCell(column: column, row: row)
                cell.fillColor = gridCellFillColor()
                cell.strokeColor = .clear
                cell.lineWidth = 0
            }
        }
    }

    private func renderLineOverlays() {
        switch lineMode {
        case .dashedRoad:
            renderDashedRoadLines()
        case .verticalGridOnly:
            renderVerticalSeparators()
        }
    }

    private func renderDashedRoadLines() {
        let tintColor = roadLineColor()
        for row in 0..<gridState.numberOfRows where row != roadDashEmptyRowIndex {
            let leftCell = gridCell(column: 0, row: row)
            addRoadDashMask(
                named: RoadLineConfiguration.outerMaskAssetName,
                toCell: leftCell,
                row: row,
                anchor: .rightEdge,
                mirrored: false,
                tintColor: tintColor
            )

            let centerCell = gridCell(column: 1, row: row)
            addRoadDashMask(
                named: RoadLineConfiguration.innerMaskAssetName,
                toCell: centerCell,
                row: row,
                anchor: .centerLeftPerspective,
                mirrored: false,
                tintColor: tintColor
            )
            addRoadDashMask(
                named: RoadLineConfiguration.innerMaskAssetName,
                toCell: centerCell,
                row: row,
                anchor: .centerRightPerspective,
                mirrored: true,
                tintColor: tintColor
            )

            let rightCell = gridCell(column: 2, row: row)
            addRoadDashMask(
                named: RoadLineConfiguration.outerMaskAssetName,
                toCell: rightCell,
                row: row,
                anchor: .leftEdge,
                mirrored: true,
                tintColor: tintColor
            )
        }
    }

    private func renderVerticalSeparators() {
        let tintColor = roadLineColor()
        let cellSize = sizeForCell()
        let lineWidth = max(1.5, cellSize.width * 0.04)

        for separatorIndex in 1..<gridState.numberOfColumns {
            let xPosition = CGFloat(separatorIndex) * cellSize.width
            let path = CGMutablePath()
            path.move(to: CGPoint(x: xPosition, y: 0))
            path.addLine(to: CGPoint(x: xPosition, y: size.height))

            let separator = SKShapeNode(path: path)
            separator.name = RoadLineConfiguration.verticalSeparatorNodeName
            separator.strokeColor = tintColor
            separator.lineWidth = lineWidth
            separator.zPosition = RoadLineConfiguration.lineZPosition
            lineOverlayNodes.append(separator)
            addChild(separator)
        }
    }

    private func addRoadDashMask(
        named assetName: String,
        toCell cell: SKShapeNode,
        row: Int,
        anchor: HorizontalRoadAnchor,
        mirrored: Bool,
        tintColor: SKColor
    ) {
        let sprite = spriteNode(imageNamed: assetName)
        let spriteSize = roadLineSize(forRow: row, cellSize: cell.frame.size)
        let xPosition = roadLineXPosition(
            inCellFrame: cell.frame,
            spriteWidth: spriteSize.width,
            anchor: anchor
        )
        sprite.name = RoadLineConfiguration.dashedLineNodeName
        sprite.position = CGPoint(x: xPosition, y: cell.frame.midY)
        sprite.aspectFitToSize(spriteSize)
        if mirrored {
            sprite.xScale = -abs(sprite.xScale)
        }
        sprite.color = tintColor
        sprite.colorBlendFactor = 1
        sprite.zPosition = RoadLineConfiguration.lineZPosition
        lineOverlayNodes.append(sprite)
        addChild(sprite)
    }

    private func roadLineSize(forRow row: Int, cellSize: CGSize) -> CGSize {
        let sizeFactor = CGFloat(row + 1) / CGFloat(gridState.numberOfRows)
        return CGSize(
            width: cellSize.width * sizeFactor,
            height: cellSize.height * sizeFactor
        )
    }

    private func roadLineXPosition(
        inCellFrame frame: CGRect,
        spriteWidth: CGFloat,
        anchor: HorizontalRoadAnchor
    ) -> CGFloat {
        switch anchor {
        case .leftEdge:
            frame.minX + (spriteWidth / 2)
        case .rightEdge:
            frame.maxX - (spriteWidth / 2)
        case .centerLeftPerspective:
            frame.midX - ((spriteWidth * RoadLineConfiguration.innerLineSpreadFactor) / 2)
        case .centerRightPerspective:
            frame.midX + ((spriteWidth * RoadLineConfiguration.innerLineSpreadFactor) / 2)
        }
    }

    private func roadLineColor() -> SKColor {
        ContrastColorResolver.minimumDarkerColor(
            against: gridCellFillColor(),
            minimumContrast: RoadLineConfiguration.minimumContrast
        )
    }

    private func renderCarSprites(gridState: GridState) {
        for row in 0..<gridState.numberOfRows {
            for column in 0..<gridState.numberOfColumns {
                let cellState = gridState.grid[row][column]
                let cell = gridCell(column: column, row: row)

                switch cellState {
                case .Car:
                    addSprite(
                        spriteNode(imageNamed: theme?.rivalCarSprite() ?? "rivalsCar-LCD"),
                        toCell: cell,
                        row: row,
                        column: column,
                        accessibilityLabel: GameLocalizedStrings.string("rival_car"),
                        usesPlayerScale: bigRivalCarsEnabled
                    )
                case .Player:
                    addSprite(
                        spriteNode(imageNamed: theme?.playerCarSprite() ?? "playersCar-LCD"),
                        toCell: cell,
                        row: row,
                        column: column,
                        accessibilityLabel: GameLocalizedStrings.string("player_car")
                    )
                case .Crash:
                    let crashSprite = spriteNode(imageNamed: theme?.crashSprite() ?? "crash-LCD")
                    crashSprite.name = "crash"
                    addSprite(
                        crashSprite,
                        toCell: cell,
                        row: row,
                        column: column,
                        accessibilityLabel: GameLocalizedStrings.string("crash_sprite")
                    )
                case .Empty:
                    break
                }
            }
        }
    }
}
