//
//  GameScene+Grid.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SpriteKit
#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

private enum RoadLineConfiguration {
    static let lapStripMaskAssetName = "lapStripMask"
    static let dashedLineNodeName = "road_dash_line"
    static let verticalSeparatorNodeName = "vertical_grid_line"
    static let lapMarkerNodeName = "lap_marker_line"
    static let lineZPosition: CGFloat = 1.5
    static let minimumContrast: Double = 4.5
    static let lapStripHeightFactor: CGFloat = 0.42
}

private enum CarPerspectiveConfiguration {
    static let sideLaneConvergenceFactor: CGFloat = 0
}

private enum RoadPerspectiveConfiguration {
    static let topRoadWidthRatio: CGFloat = 0.38
    static let bottomRoadWidthRatio: CGFloat = 0.94
    static let topDashHeightFactor: CGFloat = 0.26
    static let bottomDashHeightFactor: CGFloat = 0.64
    static let topLineWidthFactor: CGFloat = 0.043
    static let bottomLineWidthFactor: CGFloat = 0.078
    static let lapInteriorInsetLaneFactor: CGFloat = 0
    static let minimumLapInset: CGFloat = 0
    static let lapOuterExpansionLineWidthFactor: CGFloat = 0.85
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

        for overlay in friendMilestoneOverlayNodes {
            overlay.removeFromParent()
        }
        friendMilestoneOverlayNodes.removeAll()
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
        friendMilestoneOverlayNodes.removeAll()
        createGrid()
        gridStateDidUpdate(gridState, shouldPlayFeedback: false)
    }

    func updateGrid(withGridState gridState: GridState) {
        resetScene()
        styleGridCells()
        renderLineOverlays()
        renderCarSprites(gridState: gridState)
        renderUpcomingFriendMilestoneMarkers()
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
            if bigRivalCarsEnabled {
                renderFlatDashedSeparatorsForBigCars()
            } else {
                renderVerticalSeparators()
            }
        }
    }

    private func renderDashedRoadLines() {
        let tintColor = roadLineColor()
        let suppressedRows = lapSuppressedRowsForDashes()
        for row in 0..<gridState.numberOfRows where row != roadDashEmptyRowIndex && !suppressedRows.contains(row) {
            addDashedRoadLineSegments(forRow: row, tintColor: tintColor)
        }
    }

    private func addDashedRoadLineSegments(forRow row: Int, tintColor: SKColor) {
        let rowFrame = gridCell(column: 1, row: row).frame
        let centerY = rowFrame.midY
        let depthFromTop = normalizedDepthFromTop(sceneY: centerY)
        let dashHeight = rowFrame.height * interpolatedFactor(
            top: RoadPerspectiveConfiguration.topDashHeightFactor,
            bottom: RoadPerspectiveConfiguration.bottomDashHeightFactor,
            depthFromTop: depthFromTop
        )
        let topY = min(size.height, centerY + (dashHeight / 2))
        let bottomY = max(0, centerY - (dashHeight / 2))
        guard topY > bottomY else { return }

        for boundaryIndex in 0...gridState.numberOfColumns {
            addRoadDashLine(
                boundaryIndex: boundaryIndex,
                topY: topY,
                bottomY: bottomY,
                tintColor: tintColor
            )
        }
    }

    private func addRoadDashLine(
        boundaryIndex: Int,
        topY: CGFloat,
        bottomY: CGFloat,
        tintColor: SKColor
    ) {
        let topBounds = roadBounds(atSceneY: topY)
        let bottomBounds = roadBounds(atSceneY: bottomY)
        let topX = laneBoundaryX(in: topBounds, boundaryIndex: boundaryIndex)
        let bottomX = laneBoundaryX(in: bottomBounds, boundaryIndex: boundaryIndex)
        let topThickness = laneLineWidth(atSceneY: topY)
        let bottomThickness = laneLineWidth(atSceneY: bottomY)
        let centerX = (topX + bottomX) / 2
        let centerY = (topY + bottomY) / 2

        let path = CGMutablePath()
        path.move(to: CGPoint(x: (topX - (topThickness / 2)) - centerX, y: topY - centerY))
        path.addLine(to: CGPoint(x: (topX + (topThickness / 2)) - centerX, y: topY - centerY))
        path.addLine(to: CGPoint(x: (bottomX + (bottomThickness / 2)) - centerX, y: bottomY - centerY))
        path.addLine(to: CGPoint(x: (bottomX - (bottomThickness / 2)) - centerX, y: bottomY - centerY))
        path.closeSubpath()

        let lineNode = SKShapeNode(path: path)
        lineNode.name = RoadLineConfiguration.dashedLineNodeName
        lineNode.position = CGPoint(x: centerX, y: centerY)
        lineNode.fillColor = tintColor
        lineNode.strokeColor = .clear
        lineNode.lineWidth = 0
        lineNode.zPosition = RoadLineConfiguration.lineZPosition
        lineOverlayNodes.append(lineNode)
        addChild(lineNode)
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

    private func renderFlatDashedSeparatorsForBigCars() {
        let tintColor = roadLineColor()
        let cellSize = sizeForCell()
        let lineWidth = max(1.5, cellSize.width * 0.04)

        for row in 0..<gridState.numberOfRows where row != roadDashEmptyRowIndex {
            let rowFrame = gridCell(column: 1, row: row).frame
            let rowCenterY = rowFrame.midY
            let segmentHeight = rowFrame.height * 0.84
            let topY = segmentHeight / 2
            let bottomY = -segmentHeight / 2

            for separatorIndex in 1..<gridState.numberOfColumns {
                let separatorX = CGFloat(separatorIndex) * cellSize.width
                let path = CGMutablePath()
                path.move(to: CGPoint(x: 0, y: bottomY))
                path.addLine(to: CGPoint(x: 0, y: topY))

                let separator = SKShapeNode(path: path)
                separator.name = RoadLineConfiguration.dashedLineNodeName
                separator.position = CGPoint(x: separatorX, y: rowCenterY)
                separator.strokeColor = tintColor
                separator.lineWidth = lineWidth
                separator.zPosition = RoadLineConfiguration.lineZPosition
                lineOverlayNodes.append(separator)
                addChild(separator)
            }
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
        let centerY = virtualCellFrame(column: 1, row: row).midY
        let bounds = roadBounds(atSceneY: centerY)
        let laneWidth = (bounds.upperBound - bounds.lowerBound) / CGFloat(gridState.numberOfColumns)
        let interiorInset = max(
            RoadPerspectiveConfiguration.minimumLapInset,
            laneWidth * RoadPerspectiveConfiguration.lapInteriorInsetLaneFactor
        )
        let expansion = laneLineWidth(atSceneY: centerY) * RoadPerspectiveConfiguration.lapOuterExpansionLineWidthFactor
        let leftInteriorX = max(0, bounds.lowerBound + interiorInset - expansion)
        let rightInteriorX = min(size.width, bounds.upperBound - interiorInset + expansion)
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

    private func roadBounds(atSceneY y: CGFloat) -> ClosedRange<CGFloat> {
        let depthFromTop = normalizedDepthFromTop(sceneY: y)
        let widthRatio = interpolatedFactor(
            top: RoadPerspectiveConfiguration.topRoadWidthRatio,
            bottom: RoadPerspectiveConfiguration.bottomRoadWidthRatio,
            depthFromTop: depthFromTop
        )
        let halfWidth = (size.width * widthRatio) / 2
        let centerX = size.width / 2
        let minX = max(0, centerX - halfWidth)
        let maxX = min(size.width, centerX + halfWidth)
        return minX...maxX
    }

    private func normalizedDepthFromTop(sceneY y: CGFloat) -> CGFloat {
        guard size.height > 0 else { return 0 }
        let normalized = (size.height - y) / size.height
        return min(max(normalized, 0), 1)
    }

    private func interpolatedFactor(top: CGFloat, bottom: CGFloat, depthFromTop: CGFloat) -> CGFloat {
        top + ((bottom - top) * depthFromTop)
    }

    private func laneBoundaryX(in bounds: ClosedRange<CGFloat>, boundaryIndex: Int) -> CGFloat {
        let span = bounds.upperBound - bounds.lowerBound
        let ratio = CGFloat(boundaryIndex) / CGFloat(gridState.numberOfColumns)
        return bounds.lowerBound + (span * ratio)
    }

    func laneCenterX(forColumn column: Int, row: Int) -> CGFloat {
        let centerY = virtualCellFrame(column: 1, row: row).midY
        let bounds = roadBounds(atSceneY: centerY)
        let span = bounds.upperBound - bounds.lowerBound
        let laneWidth = span / CGFloat(gridState.numberOfColumns)
        return bounds.lowerBound + (laneWidth * (CGFloat(column) + 0.5))
    }

    private func laneLineWidth(atSceneY y: CGFloat) -> CGFloat {
        let depthFromTop = normalizedDepthFromTop(sceneY: y)
        let bounds = roadBounds(atSceneY: y)
        let laneWidth = (bounds.upperBound - bounds.lowerBound) / CGFloat(gridState.numberOfColumns)
        let widthFactor = interpolatedFactor(
            top: RoadPerspectiveConfiguration.topLineWidthFactor,
            bottom: RoadPerspectiveConfiguration.bottomLineWidthFactor,
            depthFromTop: depthFromTop
        )
        return max(1.25, laneWidth * widthFactor)
    }

    func roadLineColor() -> SKColor {
        guard let theme else {
            return ContrastColorResolver.minimumDarkerColor(
                against: gridCellFillColor(),
                minimumContrast: RoadLineConfiguration.minimumContrast
            )
        }

        let increaseContrastEnabled = isSystemIncreaseContrastEnabled()
        return theme.roadLineColor(isIncreaseContrastEnabled: increaseContrastEnabled).skColor
    }

    private func isSystemIncreaseContrastEnabled() -> Bool {
        #if os(iOS) || os(tvOS) || os(visionOS)
        UIAccessibility.isDarkerSystemColorsEnabled
        #elseif os(macOS)
        NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
        #else
        false
        #endif
    }

    private func renderCarSprites(gridState: GridState) {
        for row in 0..<gridState.numberOfRows {
            for column in 0..<gridState.numberOfColumns {
                let cellState = gridState.grid[row][column]
                let cell = gridCell(column: column, row: row)
                let laneCenter = bigRivalCarsEnabled ? nil : laneCenterX(forColumn: column, row: row)

                switch cellState {
                case .Car:
                    addSprite(
                        spriteNode(imageNamed: theme?.rivalCarSprite() ?? "rivalsCar-LCD"),
                        toCell: cell,
                        row: row,
                        column: column,
                        accessibilityLabel: GameLocalizedStrings.string("rival_car"),
                        usesPlayerScale: bigRivalCarsEnabled,
                        laneCenterSceneX: laneCenter,
                        sideLaneConvergenceFactor: bigRivalCarsEnabled ? 0 : CarPerspectiveConfiguration.sideLaneConvergenceFactor
                    )
                case .Player:
                    addSprite(
                        spriteNode(imageNamed: theme?.playerCarSprite() ?? "playersCar-LCD"),
                        toCell: cell,
                        row: row,
                        column: column,
                        accessibilityLabel: GameLocalizedStrings.string("player_car"),
                        usesPlayerScale: bigRivalCarsEnabled,
                        laneCenterSceneX: laneCenter
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
                        usesPlayerScale: bigRivalCarsEnabled,
                        laneCenterSceneX: laneCenter,
                        sideLaneConvergenceFactor: bigRivalCarsEnabled ? 0 : CarPerspectiveConfiguration.sideLaneConvergenceFactor
                    )
                case .Empty:
                    break
                }
            }
        }
    }

}
