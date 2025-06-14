import Foundation

struct GridState: CustomStringConvertible {
    enum CellState: Equatable {
        case Empty
        case Car
        case Player
        case Crash
        
        var toString: String {
            switch self {
            case .Empty: return "-"
            case .Car: return "C"
            case .Player: return "P"
            case .Crash: return "X"
            }
        }
    }
    
    let numberOfRows: Int
    let numberOfColumns: Int
    
    var grid: [[CellState]]
    var hasCrashed: Bool {
        grid.contains(where: { $0.contains(where: { $0 == .Crash }) })
    }
    var description: String {
        grid.reduce("") { "\($0)\($1.reduce("") { "\($0)\($1.toString) " })\n" }
    }
    var playerRowIndex: Int {
        numberOfRows - 1
    }
    
    init(numberOfRows: Int, numberOfColumns: Int) {
        self.numberOfRows = numberOfRows
        self.numberOfColumns = numberOfColumns

        grid = Array(repeating: Array(repeating: CellState.Empty, count: numberOfColumns), count: numberOfRows)
        
        grid[numberOfRows - 1][numberOfColumns / 2] = .Player
    }
    
    func playerRow() -> [CellState] {
        grid[playerRowIndex]
    }
}
