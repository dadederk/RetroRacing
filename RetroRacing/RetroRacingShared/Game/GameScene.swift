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
    static let sharedBundle = Bundle(for: GameScene.self)

    // Assets (SKColor is UIColor on iOS/tvOS, NSColor on macOS). Internal so GameScene+Grid/Effects can access.
    let gameBackgroundColor = SKColor(red: 202.0 / 255.0, green: 220.0 / 255.0, blue: 159.0 / 255.0, alpha: 1.0)
    private lazy var startSound: SKAction = makeSoundAction(filename: "start", waitForCompletion: true)
    lazy var stateUpdatedSound: SKAction = makeSoundAction(filename: "bip", waitForCompletion: false)
    lazy var failSound: SKAction = makeSoundAction(filename: "fail", waitForCompletion: false)

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

    var spritesForGivenState = [SKSpriteNode]()

    let gridCalculator = GridStateCalculator()
    var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
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
            gameDelegate?.gameSceneDidUpdateGrid(self)
        }
    }

    private func initialiseGame() {
        gameState.isPaused = false
        gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        gameState = GameState()
        gridStateDidUpdate(gridState)
        run(startSound)
    }

    func handleCrash() {
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
