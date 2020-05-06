//
//  GameScene.swift
//  RetroRacing Shared
//
//  Created by Daniel Devesa Derksen-Staats on 19/04/2020.
//  Copyright © 2020 Desfici Ltd. All rights reserved.
//

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
    private var lastFrameUpdateTime: TimeInterval = 0
    private var lastGameUpdateTime: TimeInterval = 0
    private var timeCollisioning: TimeInterval = 0
    private var gamePaused = false

    private var rivalCars = [SKSpriteNode]()
    private var car: SKSpriteNode!
    
    private var carPosition: Int = 0 {
        didSet {
            let cell = gridCell(column: carPosition, row: 0)
            let xPosition = cell.frame.origin.x + (cell.frame.size.width / 2.0)
            let yPosition = cell.frame.origin.y + (cell.frame.size.height / 2.0)
            let point = CGPoint(x: xPosition, y: yPosition)
            let moveCarAction = SKAction.move(to: point, duration: 0.0)
            moveCarAction.timingMode = .easeInEaseOut
            car.run(moveCarAction)
        }
    }
    
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
            timeCollisioning = currentTime
        }
        
        let dt = currentTime - lastFrameUpdateTime
        let dtGameUpdate = currentTime - lastGameUpdateTime
        var dtForGameUpdate = 1.0
        
        if gameState.level > 1 {
            dtForGameUpdate = 1.0 / (Double(gameState.level) *  0.51)
        }
        
        if !gamePaused {
            if gameState.cellState(forColumn: carPosition, andRow: 0) == .Car {
                timeCollisioning = timeCollisioning + dt
                if timeCollisioning >= 0.1 {
                    gameDelegate?.gameScene(self, didDetectCollisionWithScore: gameState.score)
                    gamePaused = true
                }
            } else {
                timeCollisioning = 0
            }
            
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
        addCar()
        initialiseGame()
    }
    
    private func initialiseGame() {
        lastFrameUpdateTime = 0
        timeCollisioning = 0
        
        gameState = GameState(numberOfRows: numberOfRows,
                              numberOfColumns: numberOfColumns)
        
        gameState.delegate = self
        gameState.level = 1
        gameState.score = 0
        
        carPosition = Int(Float(numberOfColumns)/2.0)
        
        gamePaused = false
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
    
    private func addCar() {
        let cellSize = sizeForCell()
        car = SKSpriteNode(imageNamed: "playersCar")
        car.aspectFitToSize(cellSize)
        addChild(car)
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
        if carPosition > 0 {
            carPosition = carPosition - 1
        }
    }
    
    func right() {
        if carPosition < numberOfColumns - 1 {
            carPosition = carPosition + 1
        }
    }
}

#if os(OSX)
// Mouse-based event handling
extension GameScene {
    
    override func mouseDown(with event: NSEvent) {
        if let label = self.label {
            label.run(SKAction.init(named: "Pulse")!, withKey: "fadeInOut")
        }
        self.makeSpinny(at: event.location(in: self), color: SKColor.green)
    }
    
    override func mouseDragged(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.blue)
    }
    
    override func mouseUp(with event: NSEvent) {
        self.makeSpinny(at: event.location(in: self), color: SKColor.red)
    }
    
}
#endif

extension GameScene: GameStateDelegate {
    
    func gameStateDidUpdate(_ gameState: GameState) {
        updateGrid(withGameState: gameState)
    }
    
    private func updateGrid(withGameState gameState: GameState) {
        
        for rivalCar in rivalCars {
            rivalCar.removeFromParent()
        }
        rivalCars.removeAll()
        
        for row in 0..<numberOfRows {
            for column in 0..<numberOfColumns {
                let cell = gridCell(column: column, row: row)
                let cellState = gameState.cellState(forColumn: column, andRow: row)
                var color = UIColor.orange
                
                if cellState == CellState.Car {
                    let cellSize = cell.frame.size
                    let sizeFactor = CGFloat(numberOfRows - row) / CGFloat(numberOfRows)
                    let size = CGSize(width: cellSize.width * sizeFactor, height: cellSize.height * sizeFactor)

                    let car = SKSpriteNode(imageNamed: "playersCar")
                    
                    car.position = CGPoint(x: cell.frame.origin.x + cellSize.width / 2.0,
                                           y: cell.frame.origin.y + cellSize.height / 2.0)
                    car.aspectFitToSize(size)
                    rivalCars.append(car)
                    cell.addChild(car)
                    
                    color = UIColor.lightGray
                }
                cell.fillColor = color
            }
        }
    }
    
    func gameState(_ gameState: GameState, didUpdateScore score: Int) {
        gameDelegate?.gameScene(self, didUpdateScore: score)
    }
}
