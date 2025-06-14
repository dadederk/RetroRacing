//
//  GameScene.swift
//  RetroRacing Shared
//
//  Created by Dani on 04/04/2025.
//

import SpriteKit

protocol GameSceneDelegate: AnyObject {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int)
    func gameSceneDidDetectCollision(_ gameScene: GameScene)
}

protocol GameController {
    func moveLeft()
    func moveRight()
}

class GameScene: SKScene {
    // Assets
    private let gameBackgroundColor = UIColor(red: 202.0 / 255.0, green: 220.0 / 255.0, blue: 159.0 / 255.0, alpha: 1.0)
    private let startSound = SKAction.playSoundFileNamed("start.m4a", waitForCompletion: true)
    private let stateUpdatedSound = SKAction.playSoundFileNamed("bip.m4a", waitForCompletion: false)
    private let failSound = SKAction.playSoundFileNamed("fail.m4a", waitForCompletion: false)
    
    private var initialDtForGameUpdate = 0.6
    private var lastGameUpdateTime: TimeInterval = 0
    
    private var spritesForGivenState = [SKSpriteNode]()
    
    private let gridCalculator = GridStateCalculator()
    private var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
    private(set) var gameState = GameState()
    
    weak var gameDelegate: GameSceneDelegate?
    
    class func newGameScene() -> GameScene {
        // Load 'GameScene.sks' as an SKScene.
        guard let scene = SKScene(fileNamed: "GameScene") as? GameScene else {
            print("Failed to load GameScene.sks")
            abort()
        }
        return scene
    }
    
    func start() {
        initialiseGame()
    }
    
    func resume() {
        gameState.isPaused = false
        gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        run(startSound)
    }
    
    func setUpScene() {
        scaleMode = .aspectFit
        createGrid()
        initialiseGame()
    }
    
#if os(watchOS)
    override func sceneDidLoad() {
        setUpScene()
    }
#else
    override func didMove(to view: SKView) {
        setUpScene()
    }
#endif
    
    override func update(_ currentTime: TimeInterval) {
        guard gameState.isPaused == false else { return }
        
        let dtGameUpdate = currentTime - lastGameUpdateTime
        var dtForGameUpdate = initialDtForGameUpdate - (log(Double(gameState.level)) / 4)
        
        if dtGameUpdate > dtForGameUpdate {
            lastGameUpdateTime = currentTime
            
            var effects: [GridStateCalculator.Effect]
            (gridState, effects) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.update])
            
            for effect in effects {
                switch effect {
                case .scored(points: let points):
                    gameState.score += points
                    gameDelegate?.gameScene(self, didUpdateScore: gameState.score)
                case .crashed:
                    gameState.isPaused = true
                    gameState.lives -= 1
                    run(failSound)
                    gameDelegate?.gameSceneDidDetectCollision(self)
                }
            }
            
            gridStateDidUpdate(gridState)
        }
    }
    
    private func initialiseGame() {
        gameState.isPaused = false
        gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gameState = GameState()
        run(startSound)
    }
    
    private func createGrid() {
        for column in 0 ..< gridState.numberOfColumns {
            var rowOfCells = [SKShapeNode]()
            for row in 0 ..< gridState.numberOfRows {
                let cell = createCell(column:column, row:row)
                rowOfCells.append(cell)
                addChild(cell)
            }
        }
    }
    
    private func createCell(column: Int, row:Int) -> (SKShapeNode) {
        let size = sizeForCell()
        let origin = positionForCellIn(column: column, row: row, size:size)
        let frame = CGRect(origin: origin, size: size)
        let cell = SKShapeNode(rect: frame)
        cell.name = nameForCell(column: column, row: row)
        cell.fillColor = gameBackgroundColor
        cell.strokeColor = .gray
        
        return cell
    }
    
    private func nameForCell(column: Int, row: Int) -> String {
        return "\(column)x\(row)"
    }
    
    private func gridCell(column: Int, row: Int) -> SKShapeNode {
        guard let cell = childNode(withName: nameForCell(column: column, row: row)) as? SKShapeNode else {
            fatalError("Failed to retrieve grid cell at \(column) x \(row)")
        }
        
        return cell
    }
    
    private func sizeForCell() -> (CGSize) {
        let width = size.width / CGFloat(gridState.numberOfColumns)
        let height = size.height / CGFloat(gridState.numberOfRows)
        return CGSize(width: width, height: height)
    }
    
    private func positionForCellIn(column: Int, row: Int, size: CGSize) -> (CGPoint) {
        let x = (CGFloat(column) * size.width)
        let y = (CGFloat(gridState.numberOfRows - row - 1) * size.height)
        return CGPoint(x: x, y: y)
    }
    
    private func gridStateDidUpdate(_ gridState: GridState) {
        updateGrid(withGridState: gridState)
        run(stateUpdatedSound)
    }
    
    private func resetScene() {
        for sprite in spritesForGivenState {
            sprite.removeFromParent()
        }
        spritesForGivenState.removeAll()
    }
    
    private func updateGrid(withGridState gridState: GridState) {
        resetScene()
        
        for row in 0..<gridState.numberOfRows {
            for column in 0..<gridState.numberOfColumns {
                let cellState = gridState.grid[row][column]
                let cell = gridCell(column: column, row: row)
                
                switch cellState {
                case .Car: addSprite(SKSpriteNode(imageNamed: "playersCar"), toCell: cell, row: row, column: column)
                case .Player: addSprite(SKSpriteNode(imageNamed: "playersCar"), toCell: cell, row: row, column: column)
                case .Crash: addSprite(SKSpriteNode(imageNamed: "crash"), toCell: cell, row: row, column: column)
                case .Empty: break
                }
                
                cell.fillColor = gameBackgroundColor
            }
        }
    }
    
    private func addSprite(_ sprite: SKSpriteNode, toCell cell: SKShapeNode, row: Int, column: Int) {
        let cellSize = cell.frame.size
        let sizeFactor = CGFloat(gridState.numberOfRows - (gridState.numberOfRows - row - 1)) / CGFloat(gridState.numberOfRows)
        let size = CGSize(width: cellSize.width * sizeFactor, height: cellSize.height * sizeFactor)
        
        var horizontalTranslationFactor: CGFloat = 0.0
        
        if column < (gridState.numberOfColumns / 2) {
            horizontalTranslationFactor = (cellSize.width - size.width)
        } else if column > (gridState.numberOfColumns / 2) {
            horizontalTranslationFactor = -(cellSize.width - size.width)
        }
        
        sprite.position = CGPoint(x: cell.frame.origin.x + ((cellSize.width + horizontalTranslationFactor) / 2.0),
                                  y: cell.frame.origin.y + (cellSize.height / 2.0))
        sprite.aspectFitToSize(size)
        spritesForGivenState.append(sprite)
        cell.addChild(sprite)
    }
}

extension GameScene: GameController {
    func moveLeft() {
        guard !gameState.isPaused else { return }
        
        (gridState, _) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left)])
        
        gridStateDidUpdate(gridState)
    }
    
    func moveRight() {
        guard !gameState.isPaused else { return }
        
        (gridState, _) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .right)])
        
        gridStateDidUpdate(gridState)
    }
}

#if os(iOS) || os(tvOS)
// Touch-based event handling
extension GameScene {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {

    }
    
   
}
#endif

#if os(OSX)
// Mouse-based event handling
extension GameScene {

    override func mouseDown(with event: NSEvent) {

    }
    
    override func mouseDragged(with event: NSEvent) {
        
    }
    
    override func mouseUp(with event: NSEvent) {

    }

}
#endif

