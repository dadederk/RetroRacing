import Foundation

struct GridState: CustomStringConvertible {
    enum CellState {
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
    var description: String {
        grid.reduce("") { "\($0)\($1.reduce("") { "\($0)\($1.toString) " })\n" }
    }
    
    init(numberOfRows: Int, numberOfColumns: Int) {
        self.numberOfRows = numberOfRows
        self.numberOfColumns = numberOfColumns
        
        grid = Array(repeating: Array(repeating: .Empty, count: numberOfColumns), count: numberOfRows)
        
        grid[numberOfRows - 1][numberOfColumns / 2] = .Player
    }
}
