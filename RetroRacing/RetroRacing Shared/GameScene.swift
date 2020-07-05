import SpriteKit

protocol GameSceneDelegate: AnyObject {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int)
    func gameScene(_ gameScene: GameScene, didDetectCollisionWithScore score: Int)
}

protocol GameController {
    func left()
    func right()
}

class GameScene: SKScene {
    private let numberOfRows = 5
    private let numberOfColumns = 3
    private let startSound = SKAction.playSoundFileNamed("start.m4a", waitForCompletion: true)
    private let stateUpdatedSound = SKAction.playSoundFileNamed("bip.m4a", waitForCompletion: false)
    private let failSound = SKAction.playSoundFileNamed("fail.m4a", waitForCompletion: false)
    
    private var lastFrameUpdateTime: TimeInterval = 0
    private var lastGameUpdateTime: TimeInterval = 0
    private var gamePaused = false
    private var spritesForGivenState = [SKSpriteNode]()
    
    private var gameState: GameState!
    
    weak var gameDelegate: GameSceneDelegate?
    
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
        if (lastFrameUpdateTime == 0) {
            lastFrameUpdateTime = currentTime
        }

        let dtGameUpdate = currentTime - lastGameUpdateTime
        var dtForGameUpdate = 0.5
        
        if gameState.level > 1 {
            dtForGameUpdate = 1.0 / (Double(gameState.level) *  0.50)
            // dtForGameUpdate = 2.25 - ((Double(gameState.level) * 0.25)
        }
        
        if !gamePaused {
            if dtGameUpdate > dtForGameUpdate {
                lastGameUpdateTime = currentTime
                gameState.calculateGameState()
            }
        }
        
        lastFrameUpdateTime = currentTime
    }
    
    private func setUpScene() {
        scaleMode = .aspectFit
        createGrid()
        initialiseGame()
    }
    
    private func initialiseGame() {
        lastFrameUpdateTime = 0
        
        gameState = GameState(numberOfRows: numberOfRows,
                              numberOfColumns: numberOfColumns)
    
        gameState.delegate = self
        gameState.level = 1
        
        gamePaused = false
        
        run(startSound)
    }
    
    private func createGrid() {
        for column in 0 ..< numberOfColumns {
            var rowOfCells = [SKShapeNode]()
            for row in 0 ..< numberOfRows {
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
        cell.name = stringNameForCell(column: column, row: row)
        cell.fillColor = .orange
        cell.strokeColor = .gray
        
        return cell
    }
    
    private func stringNameForCell(column: Int, row: Int) -> String {
        return "\(column)x\(row)"
    }
    
    private func gridCell(column: Int, row: Int) -> SKShapeNode {
        guard let cell = childNode(withName: stringNameForCell(column: column, row: row)) as? SKShapeNode else {
            fatalError("Failed to retrieve grid cell at \(column) x \(row)")
        }
        
        return cell
    }
    
    private func sizeForCell() -> (CGSize) {
        let width = size.width / CGFloat(numberOfColumns)
        let height = size.height / CGFloat(numberOfRows)
        return CGSize(width: width, height: height)
    }
    
    private func positionForCellIn(column:Int, row:Int, size: CGSize) -> (CGPoint) {
        let x = (CGFloat(column) * size.width)
        let y = (CGFloat(row) * size.height)
        return CGPoint(x: x, y: y)
    }
    
    func start() {
        initialiseGame()
    }
}

extension GameScene: GameController {
    func left() {
        gameState.movePlayersCar(to: .left)
    }
    
    func right() {
        gameState.movePlayersCar(to: .right)
    }
}

#if os(OSX)
// Mouse-based event handling
extension GameScene {
    
    override func mouseDown(with event: NSEvent) {}
    
    override func mouseDragged(with event: NSEvent) {}
    
    override func mouseUp(with event: NSEvent) {}
    
}
#endif

extension GameScene: GameStateDelegate {
    func gameStateDidUpdate(_ gameState: GameState) {
        updateGrid(withGameState: gameState)
        run(stateUpdatedSound)
    }
    
    private func resetScene() {
        for sprite in spritesForGivenState {
            sprite.removeFromParent()
        }
        spritesForGivenState.removeAll()
    }
    
    private func updateGrid(withGameState gameState: GameState) {
        resetScene()
        
        for row in 0..<numberOfRows {
            for column in 0..<numberOfColumns {
                guard let cellState = gameState.cellState(forColumn: column, andRow: row) else { return }
                let cell = gridCell(column: column, row: row)
                
                switch cellState {
                case .Car:
                    let car = SKSpriteNode(imageNamed: "playersCar")
                    addSprite(car, toCell: cell, row: row, column: column)
                case .Empty:
                    break
                case .Player:
                    let car = SKSpriteNode(imageNamed: "playersCar")
                    addSprite(car, toCell: cell, row: row, column: column)
                case .Crash:
                    let crash = SKSpriteNode(imageNamed: "crash")
                    addSprite(crash, toCell: cell, row: row, column: column)
                    gamePaused = true
                    gameDelegate?.gameScene(self, didDetectCollisionWithScore: gameState.score)
                    run(failSound)
                }

                cell.fillColor = UIColor.orange
            }
        }
    }
    
    func addSprite(_ sprite: SKSpriteNode, toCell cell: SKShapeNode, row: Int, column: Int) {
        let cellSize = cell.frame.size
        let sizeFactor = CGFloat(numberOfRows - row) / CGFloat(numberOfRows)
        let size = CGSize(width: cellSize.width * sizeFactor, height: cellSize.height * sizeFactor)
        
        var horizontalTranslationFactor: CGFloat = 0.0
        if column < (numberOfColumns / 2) {
            horizontalTranslationFactor = (cellSize.width - size.width)
        } else if column > (numberOfColumns / 2) {
            horizontalTranslationFactor = -(cellSize.width - size.width)
        }
        
        sprite.position = CGPoint(x: cell.frame.origin.x + ((cellSize.width + horizontalTranslationFactor) / 2.0),
                               y: cell.frame.origin.y + (cellSize.height / 2.0))
        sprite.aspectFitToSize(size)
        spritesForGivenState.append(sprite)
        cell.addChild(sprite)
    }
    
    func gameState(_ gameState: GameState, didUpdateScore score: Int) {
        gameDelegate?.gameScene(self, didUpdateScore: score)
    }
}
