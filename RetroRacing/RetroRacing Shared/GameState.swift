import Foundation

struct GameState {
    private(set) var level = 1
    
    var lives = 3
    var score = 0 {
        didSet {
            level = (score / 100) + 1
        }
    }
}
