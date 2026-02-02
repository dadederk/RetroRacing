import SpriteKit
import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Input commands for the game. Named to avoid shadowing the GameController framework (physical controllers).
public protocol RacingGameController {
    func moveLeft()
    func moveRight()
}

public class GameScene: SKScene {
    /// Bundle containing all game assets (sprites, sounds). Assets live only in RetroRacingShared; load from here.
    private static let sharedBundle = Bundle(for: GameScene.self)

    // Assets (SKColor is UIColor on iOS/tvOS, NSColor on macOS)
    private let gameBackgroundColor = SKColor(red: 202.0 / 255.0, green: 220.0 / 255.0, blue: 159.0 / 255.0, alpha: 1.0)
    private lazy var startSound: SKAction = makeSoundAction(filename: "start", waitForCompletion: true)
    private lazy var stateUpdatedSound: SKAction = makeSoundAction(filename: "bip", waitForCompletion: false)
    private lazy var failSound: SKAction = makeSoundAction(filename: "fail", waitForCompletion: false)

    /// Retain playing AVAudioPlayers so they are not deallocated before playback finishes.
    private var activeSoundPlayers: [AVAudioPlayer] = []

    private func makeSoundAction(filename: String, waitForCompletion: Bool) -> SKAction {
        guard let url = Self.soundURL(filename: filename) else {
            AppLog.error(AppLog.sound, "sound '\(filename).m4a' NOT FOUND in bundle \(Self.sharedBundle.bundleURL.lastPathComponent)")
            return SKAction.wait(forDuration: 0)
        }
        AppLog.log(AppLog.sound, "sound '\(filename).m4a' resolved → \(url.path)")
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.delegate = self
            let duration = player.duration
            activeSoundPlayers.append(player)
            return SKAction.sequence([
                SKAction.run { player.play() },
                SKAction.wait(forDuration: waitForCompletion ? duration : 0)
            ])
        } catch {
            AppLog.error(AppLog.sound, "AVAudioPlayer failed for '\(filename).m4a': \(error.localizedDescription)")
            return SKAction.wait(forDuration: 0)
        }
    }

    /// Resolves URL to a sound file in the shared framework bundle. playSoundFileNamed only looks in main bundle, so we use AVAudioPlayer with this URL.
    private static func soundURL(filename: String) -> URL? {
        let name = "\(filename).m4a"
        let dirs = ["Audio", "Resources/Audio", ""]
        for dir in dirs where !dir.isEmpty {
            if let u = sharedBundle.url(forResource: filename, withExtension: "m4a", subdirectory: dir.isEmpty ? nil : dir) { return u }
        }
        if let u = sharedBundle.url(forResource: filename, withExtension: "m4a") { return u }
        guard let base = sharedBundle.resourceURL,
              let enumerator = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else {
            return nil
        }
        while let url = enumerator.nextObject() as? URL {
            if url.lastPathComponent == name { return url }
        }
        return nil
    }

    private var initialDtForGameUpdate = 0.6
    private var lastGameUpdateTime: TimeInterval = 0

    private var spritesForGivenState = [SKSpriteNode]()

    private let gridCalculator = GridStateCalculator()
    private var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
    public private(set) var gameState = GameState()

    /// When set, sprite asset names and grid cell color come from the theme; otherwise LCD defaults.
    public var theme: (any GameTheme)?

    /// Loads sprite images from the bundle. Injected so shared code has no UIKit/AppKit conditionals.
    /// Optional so scene can be created before assignment; e.g. on watchOS sceneDidLoad() may run early.
    public var imageLoader: (any ImageLoader)?

    public weak var gameDelegate: GameSceneDelegate?

    public override init(size: CGSize) {
        super.init(size: size)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Creates a new game scene with the given size. Use this for SwiftUI SpriteView when no .sks file is used.
    /// Grid is created when the scene is presented (didMove/to view or sceneDidLoad); use view size when possible so scene size matches view and scaling is 1:1.
    /// - Parameters:
    ///   - size: Scene size.
    ///   - theme: Optional theme; when provided, sprite asset names (playerCarSprite, rivalCarSprite, crashSprite) are used.
    ///   - imageLoader: Loader for sprite textures (platform-specific: UIKit vs AppKit).
    public static func scene(size: CGSize, theme: (any GameTheme)? = nil, imageLoader: some ImageLoader) -> GameScene {
        let scene = GameScene(size: size)
        scene.imageLoader = imageLoader
        scene.theme = theme
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        scene.scaleMode = .aspectFit
        return scene
    }

    /// Creates a new game scene. Use programmatic size; .sks loading uses main bundle and is not used from framework.
    /// Caller must set imageLoader before presenting the scene if using this initializer.
    public class func newGameScene(imageLoader: some ImageLoader) -> GameScene {
        let defaultSize = CGSize(width: 800, height: 600)
        return scene(size: defaultSize, theme: nil, imageLoader: imageLoader)
    }

    public func start() {
        initialiseGame()
    }

    public func resume() {
        gameState.isPaused = false
        gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        run(startSound)
    }

    func setUpScene() {
        AppLog.log(AppLog.game + AppLog.assets, "setUpScene bundle=\(Self.sharedBundle.bundleURL.path)")
        anchorPoint = CGPoint(x: 0, y: 0)
        scaleMode = .aspectFit
        backgroundColor = gameBackgroundColor
        AppLog.log(AppLog.game + AppLog.assets, "setUpScene size=\(size) anchorPoint=\(anchorPoint)")
        createGrid()
        initialiseGame()
    }

#if os(watchOS)
    public override func sceneDidLoad() {
        setUpScene()
    }
#else
    public override func didMove(to view: SKView) {
        setUpScene()
    }
#endif

    public override func update(_ currentTime: TimeInterval) {
        guard gameState.isPaused == false else { return }

        let dtGameUpdate = currentTime - lastGameUpdateTime
        let dtForGameUpdate = initialDtForGameUpdate - (log(Double(gameState.level)) / 4)

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
                    handleCrash()
                }
            }

            gridStateDidUpdate(gridState)
        }
    }

    private func initialiseGame() {
        gameState.isPaused = false
        gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gameState = GameState()
        gridStateDidUpdate(gridState)
        run(startSound)
    }

    private func createGrid() {
        for column in 0 ..< gridState.numberOfColumns {
            for row in 0 ..< gridState.numberOfRows {
                let cell = createCell(column: column, row: row)
                addChild(cell)
            }
        }
    }

    private func gridCellFillColor() -> SKColor {
        guard let theme else { return gameBackgroundColor }
        return theme.gridCellColor().skColor
    }

    private func createCell(column: Int, row: Int) -> SKShapeNode {
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

    private func nameForCell(column: Int, row: Int) -> String {
        "\(column)x\(row)"
    }

    private func gridCell(column: Int, row: Int) -> SKShapeNode {
        guard let cell = childNode(withName: nameForCell(column: column, row: row)) as? SKShapeNode else {
            fatalError("Failed to retrieve grid cell at \(column) x \(row)")
        }

        return cell
    }

    private func sizeForCell() -> CGSize {
        let width = size.width / CGFloat(gridState.numberOfColumns)
        let height = size.height / CGFloat(gridState.numberOfRows)
        return CGSize(width: width, height: height)
    }

    private func positionForCellIn(column: Int, row: Int, size: CGSize) -> CGPoint {
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
                case .Car: addSprite(spriteNode(imageNamed: theme?.rivalCarSprite() ?? "rivalsCar-LCD"), toCell: cell, row: row, column: column)
                case .Player: addSprite(spriteNode(imageNamed: theme?.playerCarSprite() ?? "playersCar-LCD"), toCell: cell, row: row, column: column)
                case .Crash:
                    let crashSprite = spriteNode(imageNamed: theme?.crashSprite() ?? "crash-LCD")
                    crashSprite.name = "crash"
                    addSprite(crashSprite, toCell: cell, row: row, column: column)
                case .Empty: break
                }

                cell.fillColor = gridCellFillColor()
            }
        }
    }

    private func spriteNode(imageNamed name: String) -> SKSpriteNode {
        let texture = texture(imageNamed: name)
        return SKSpriteNode(texture: texture)
    }

    /// Loads texture via injected imageLoader so shared code has no UIKit/AppKit conditionals.
    private func texture(imageNamed name: String) -> SKTexture {
        guard let imageLoader else {
            AppLog.error(AppLog.assets, "texture '\(name)' skipped: imageLoader not set yet (scene not fully initialized)")
            return SKTexture()
        }
        return imageLoader.loadTexture(imageNamed: name, bundle: Self.sharedBundle)
    }

    private func addSprite(_ sprite: SKSpriteNode, toCell cell: SKShapeNode, row: Int, column: Int) {
        let cellSize = cell.frame.size
        let sizeFactor = CGFloat(gridState.numberOfRows - (gridState.numberOfRows - row - 1)) / CGFloat(gridState.numberOfRows)
        let spriteSize = CGSize(width: cellSize.width * sizeFactor, height: cellSize.height * sizeFactor)

        var horizontalTranslationFactor: CGFloat = 0.0

        if column < (gridState.numberOfColumns / 2) {
            horizontalTranslationFactor = (cellSize.width - spriteSize.width)
        } else if column > (gridState.numberOfColumns / 2) {
            horizontalTranslationFactor = -(cellSize.width - spriteSize.width)
        }

        let cellOriginInLocal = cell.frame.origin
        let spritePosInCell = CGPoint(
            x: cellOriginInLocal.x + (cellSize.width + horizontalTranslationFactor) / 2.0,
            y: cellOriginInLocal.y + cellSize.height / 2.0
        )
        sprite.position = spritePosInCell
        sprite.aspectFitToSize(spriteSize)
        sprite.zPosition = 2
        spritesForGivenState.append(sprite)
        cell.addChild(sprite)

        let texSize = sprite.texture?.size() ?? .zero
        if row == 0 && column == 0 && spritesForGivenState.count <= 1 {
            AppLog.log(AppLog.assets, "addSprite row=\(row) col=\(column) cellSize=\(cellSize) spriteSize=\(spriteSize) posInCell=\(spritePosInCell) textureSize=\(texSize) sprite.frame=\(sprite.frame) scale=\(sprite.xScale)")
        }

        if sprite.name == "crash" {
            let blinkOnce = SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.fadeIn(withDuration: 0.2)
            ])
            let blinkThreeTimes = SKAction.repeat(blinkOnce, count: 3)
            sprite.run(blinkThreeTimes)
        }
    }

    private func handleCrash() {
        gameState.isPaused = true
        gameState.lives -= 1
        run(failSound)

        run(SKAction.wait(forDuration: 2.0)) { [weak self] in
            guard let self = self else { return }
            self.gameDelegate?.gameSceneDidDetectCollision(self)
        }
    }
}

extension GameScene: RacingGameController {
    public func moveLeft() {
        guard !gameState.isPaused else { return }

        (gridState, _) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left)])

        gridStateDidUpdate(gridState)
    }

    public func moveRight() {
        guard !gameState.isPaused else { return }

        (gridState, _) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .right)])

        gridStateDidUpdate(gridState)
    }
}

extension GameScene: AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        activeSoundPlayers.removeAll { $0 === player }
    }
}
