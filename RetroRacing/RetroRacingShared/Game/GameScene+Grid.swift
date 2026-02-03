//
//  GameScene+Grid.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SpriteKit

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
        cell.strokeColor = .gray
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

    func gridStateDidUpdate(_ gridState: GridState, shouldPlayFeedback: Bool = true, notifyDelegate: Bool = true) {
        updateGrid(withGridState: gridState)
        if shouldPlayFeedback {
            play(SoundEffect.bip)
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
        createGrid()
        gridStateDidUpdate(gridState, shouldPlayFeedback: false)
    }

    func updateGrid(withGridState gridState: GridState) {
        resetScene()

        for row in 0..<gridState.numberOfRows {
            for column in 0..<gridState.numberOfColumns {
                let cellState = gridState.grid[row][column]
                let cell = gridCell(column: column, row: row)

                switch cellState {
                case .Car: addSprite(spriteNode(imageNamed: theme?.rivalCarSprite() ?? "rivalsCar-LCD"), toCell: cell, row: row, column: column, accessibilityLabel: GameLocalizedStrings.string("rival_car"))
                case .Player: addSprite(spriteNode(imageNamed: theme?.playerCarSprite() ?? "playersCar-LCD"), toCell: cell, row: row, column: column, accessibilityLabel: GameLocalizedStrings.string("player_car"))
                case .Crash:
                    let crashSprite = spriteNode(imageNamed: theme?.crashSprite() ?? "crash-LCD")
                    crashSprite.name = "crash"
                    addSprite(crashSprite, toCell: cell, row: row, column: column, accessibilityLabel: GameLocalizedStrings.string("crash_sprite"))
                case .Empty: break
                }

                cell.fillColor = gridCellFillColor()
            }
        }
    }
}
