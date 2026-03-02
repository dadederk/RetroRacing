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
    static let lapStripMaskAssetName = "lapStripMask"
    static let dashedLineNodeName = "road_dash_line"
    static let verticalSeparatorNodeName = "vertical_grid_line"
    static let lapMarkerNodeName = "lap_marker_line"
    static let lineZPosition: CGFloat = 1.5
    static let minimumContrast: Double = 4.5
    static let innerLineSpreadFactor: CGFloat = 0.6
    // Mid-height horizontal center of the generated outer mask shape.
    static let outerMaskMidlineCenterRatio: CGFloat = 0.195
    static let lapInteriorInsetRatio: CGFloat = 0.03
    static let lapStripHeightFactor: CGFloat = 0.42
}

private enum CarPerspectiveConfiguration {
    static let sideLaneConvergenceFactor: CGFloat = 0.5
}

private enum HorizontalRoadAnchor {
    case leftEdge
    case rightEdge
    case center
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
        case .detailedRoad:
            renderDashedRoadLines()
            renderLapMarkers()
        case .verticalOnly:
            renderVerticalSeparators()
        }
    }

    private func renderDashedRoadLines() {
        let tintColor = roadLineColor()
        let suppressedRows = lapSuppressedRowsForDashes()
        for row in 0..<gridState.numberOfRows where row != roadDashEmptyRowIndex && !suppressedRows.contains(row) {
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

    private func renderLapMarkers() {
        guard let layout = lapStripLayoutForRendering() else {
            return
        }

        let tintColor = roadLineColor()
        addLapMarker(layout: layout, tintColor: tintColor)
    }

    private func lapMarkerRowsForRendering() -> [Int] {
        // When the first safety row has just entered at the top of the screen
        // (second not yet inserted), synthesize a virtual row above screen so
        // the strip can partially appear as it enters from the top.
        if safetyMarkerRows == [0] {
            return [-1, 0]
        }
        guard safetyMarkerRows.count == 2 else { return [] }
        // Allow one row beyond each visible edge so the strip can partially
        // appear/disappear at the screen boundaries.
        let extendedRange = (-1...gridState.numberOfRows)
        let validRows = safetyMarkerRows
            .filter { extendedRange.contains($0) }
            .sorted()
        guard validRows.count == 2 else { return [] }
        return validRows
    }

    private func lapStripLayoutForRendering() -> (interiorBounds: ClosedRange<CGFloat>, centerY: CGFloat, stripHeight: CGFloat)? {
        let rows = lapMarkerRowsForRendering()
        guard rows.count == 2,
              let topRow = rows.first,
              let bottomRow = rows.last,
              let topBounds = lapRoadInteriorBounds(forRow: topRow),
              let bottomBounds = lapRoadInteriorBounds(forRow: bottomRow) else {
            return nil
        }

        // Use analytically computed frames so virtual rows (outside 0..<numberOfRows)
        // don't trigger a fatalError in gridCell(column:row:).
        let topBoundaryY = virtualCellFrame(column: 1, row: topRow).minY
        let bottomBoundaryY = virtualCellFrame(column: 1, row: bottomRow).maxY
        let centerY = (topBoundaryY + bottomBoundaryY) / 2
        let cellHeight = sizeForCell().height
        let stripPerspectiveFactor = lapStripPerspectiveFactor(topRow: topRow, bottomRow: bottomRow)
        let stripHeight = cellHeight * RoadLineConfiguration.lapStripHeightFactor * stripPerspectiveFactor
        let interpolatedBounds = ((topBounds.lowerBound + bottomBounds.lowerBound) / 2)...((topBounds.upperBound + bottomBounds.upperBound) / 2)
        return (interpolatedBounds, centerY, stripHeight)
    }

    private func lapStripPerspectiveFactor(topRow: Int, bottomRow: Int) -> CGFloat {
        let averageRow = (CGFloat(topRow) + CGFloat(bottomRow)) / 2
        return (averageRow + 1) / CGFloat(gridState.numberOfRows)
    }

    private func lapSuppressedRowsForDashes() -> Set<Int> {
        var rows = Set(lapMarkerRowsForRendering())
        if let layout = lapStripLayoutForRendering(),
           let nearestRow = closestRowIndex(toSceneY: layout.centerY) {
            rows.insert(nearestRow)
        }
        return rows
    }

    private func closestRowIndex(toSceneY y: CGFloat) -> Int? {
        guard gridState.numberOfRows > 0 else { return nil }
        var bestRow = 0
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for row in 0..<gridState.numberOfRows {
            let centerY = gridCell(column: 1, row: row).frame.midY
            let distance = abs(centerY - y)
            if distance < bestDistance {
                bestDistance = distance
                bestRow = row
            }
        }
        return bestRow
    }

    private func addLapMarker(layout: (interiorBounds: ClosedRange<CGFloat>, centerY: CGFloat, stripHeight: CGFloat), tintColor: SKColor) {
        let stripWidth = layout.interiorBounds.upperBound - layout.interiorBounds.lowerBound
        let stripSize = CGSize(width: stripWidth, height: layout.stripHeight)
        let centerX = (layout.interiorBounds.lowerBound + layout.interiorBounds.upperBound) / 2

        addLapMask(
            named: RoadLineConfiguration.lapStripMaskAssetName,
            position: CGPoint(x: centerX, y: layout.centerY),
            size: stripSize,
            mirroredHorizontally: false,
            mirroredVertically: false,
            tintColor: tintColor
        )
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

    private func addLapMask(
        named assetName: String,
        position: CGPoint,
        size: CGSize,
        mirroredHorizontally: Bool,
        mirroredVertically: Bool,
        tintColor: SKColor
    ) {
        let sprite = spriteNode(imageNamed: assetName)
        sprite.name = RoadLineConfiguration.lapMarkerNodeName
        sprite.position = position
        sprite.size = size
        if mirroredHorizontally {
            sprite.xScale = -abs(sprite.xScale)
        }
        if mirroredVertically {
            sprite.yScale = -abs(sprite.yScale)
        }
        sprite.color = tintColor
        sprite.colorBlendFactor = 1
        sprite.zPosition = RoadLineConfiguration.lineZPosition
        lineOverlayNodes.append(sprite)
        addChild(sprite)
    }

    private func lapRoadInteriorBounds(forRow row: Int) -> ClosedRange<CGFloat>? {
        // Use analytically computed frames so virtual rows (outside 0..<numberOfRows)
        // don't trigger a fatalError in gridCell(column:row:).
        let cellSize = sizeForCell()
        let leftCellMaxX = virtualCellFrame(column: 0, row: row).maxX
        let rightCellMinX = virtualCellFrame(column: 2, row: row).minX
        let dashSize = roadLineSize(forRow: row, cellSize: cellSize)
        let leftDashMinX = leftCellMaxX - dashSize.width
        let rightDashMaxX = rightCellMinX + dashSize.width
        let inset = max(1, dashSize.width * RoadLineConfiguration.lapInteriorInsetRatio)

        let leftInteriorX = leftDashMinX + (dashSize.width * RoadLineConfiguration.outerMaskMidlineCenterRatio) + inset
        let rightInteriorX = rightDashMaxX - (dashSize.width * RoadLineConfiguration.outerMaskMidlineCenterRatio) - inset
        guard rightInteriorX > leftInteriorX else { return nil }
        return leftInteriorX...rightInteriorX
    }

    /// Computes the frame for a cell at the given column and row index analytically,
    /// supporting virtual rows outside the visible grid (e.g. row -1 or numberOfRows).
    private func virtualCellFrame(column: Int, row: Int) -> CGRect {
        let cellSize = sizeForCell()
        let origin = positionForCellIn(column: column, row: row, size: cellSize)
        return CGRect(origin: origin, size: cellSize)
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
        case .center:
            frame.midX
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
                        usesPlayerScale: bigRivalCarsEnabled,
                        sideLaneConvergenceFactor: bigRivalCarsEnabled ? 0 : CarPerspectiveConfiguration.sideLaneConvergenceFactor
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
                        accessibilityLabel: GameLocalizedStrings.string("crash_sprite"),
                        sideLaneConvergenceFactor: bigRivalCarsEnabled ? 0 : CarPerspectiveConfiguration.sideLaneConvergenceFactor
                    )
                case .Empty:
                    break
                }
            }
        }
    }
}
