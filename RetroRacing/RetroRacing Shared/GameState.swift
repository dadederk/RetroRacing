import Foundation

protocol GameStateDelegate: AnyObject {
    func gameStateDidUpdate(_ gameState: GameState)
    func gameState(_ gameState: GameState, didUpdateScore score: Int)
}

enum PlayersCarDirection {
    case left
    case right
}

enum CellState: Int {
    case Car = 0
    case Empty = 1
    case Player
    case Crash
}

struct GameState {
    private let numberOfRows: Int
    private let numberOfColumns: Int
    
    var level = 1
    
    var playerCarPosition: Int
    
    private(set) var score = 0 {
        didSet { delegate?.gameState(self, didUpdateScore: score) }
    }
    
    private var cellStates = [CellState]() {
        didSet { delegate?.gameStateDidUpdate(self) }
    }
    
    weak var delegate: GameStateDelegate?
    
    init(numberOfRows: Int, numberOfColumns: Int) {
        self.numberOfRows = numberOfRows
        self.numberOfColumns = numberOfColumns
        
        playerCarPosition = numberOfColumns / 2
        
        cellStates = Array(repeating: .Empty, count: numberOfRows * numberOfColumns)
    }
    
    mutating func movePlayersCar(to direction: PlayersCarDirection) {
        cellStates[playerCarPosition] = .Empty
        
        switch direction {
        case .left: playerCarPosition = (playerCarPosition > 0) ? playerCarPosition - 1 : playerCarPosition
        case .right: playerCarPosition = (playerCarPosition < numberOfColumns - 1) ? playerCarPosition + 1 : playerCarPosition
        }
        
        cellStates[playerCarPosition] = .Player
        
        self.delegate?.gameStateDidUpdate(self)
    }
    
    func cellState(forColumn column: Int, andRow row: Int) -> CellState? {
        guard isColumnInRange(column) && isRowInRange(row) else { return nil }
        let index = position(forColumn: column, andRow: row)
        return cellStates[index]
    }
    
    private func isColumnInRange(_ column: Int) -> Bool {
        return (column >= 0) && (column < numberOfColumns)
    }
    
    private func isRowInRange(_ row: Int) -> Bool {
        return (row >= 0) && (row < numberOfRows)
    }
    
    private func getRow(_ index: Int) -> [CellState] {
        let startIndex = numberOfRows * index
        let endIndex = startIndex + numberOfColumns
        let row = cellStates[startIndex ..< endIndex]
        
        return Array(row)
    }
    
    private func numberOfCars(inRow row: [CellState]) -> Int {
        var numberOfCars = 0
        
        for cellState in row where cellState == CellState.Car {
            numberOfCars += 1
        }
        
        return numberOfCars
    }
    
    mutating func calculateGameState() {
        var newRandomRow = Array(repeating: CellState.Empty, count: numberOfColumns)
        
        // Check empty indexes in last row
        let lastRowStart = cellStates.count - numberOfColumns
        let lastRowEnd = cellStates.count - 1
        let lastRow = Array(cellStates[lastRowStart...lastRowEnd])
        
        var emptyIndexesInLastRow = [Int]()
        
        for (i, cellState) in lastRow.enumerated() {
            if cellState == .Empty {
                emptyIndexesInLastRow.append(i)
            }
        }
        
        // Create new random row
        var numberOfCarsInRow = 0
        
        for i in 0..<numberOfColumns {
            newRandomRow[i] = CellState(rawValue: randomNumber(range: 0...1))!
            
            if newRandomRow[i] == .Car {
                numberOfCarsInRow = numberOfCarsInRow + 1
            }
        }
        
        // New random row should have at least one empty cell. If not, remove
        // remove one in an aleatory position
        if numberOfCarsInRow == numberOfColumns {
            newRandomRow = removingAleatoryCar(inRow: newRandomRow)
        }
        
        // To have a valid path for the car, check the new random row
        // has at least one empty neighbour of the last row empty
        // indexes
        var emptyIndexesWithoutEmptyNeighbours = [Int]()
        
        for emptyIndex in emptyIndexesInLastRow {
            
            var numberOfEmptyNeighbours = 0
            
            if let northWest = cellState(forRow: newRandomRow, atIndex: emptyIndex - 1),
                northWest == .Empty {
                numberOfEmptyNeighbours += 1
            }
            
            if let north = cellState(forRow: newRandomRow, atIndex: emptyIndex),
                north == .Empty {
                numberOfEmptyNeighbours += 1
            }
            
            if let northEast = cellState(forRow: newRandomRow, atIndex: emptyIndex + 1),
                northEast == .Empty {
                numberOfEmptyNeighbours += 1
            }
            
            if numberOfEmptyNeighbours == 0 {
                emptyIndexesWithoutEmptyNeighbours.append(emptyIndex)
            }
        }
        
        if emptyIndexesWithoutEmptyNeighbours.count > 0 {
            for indexToEmpty in emptyIndexesWithoutEmptyNeighbours {
                // TODO: Randomly remove one of the neighbours
                newRandomRow[indexToEmpty] = .Empty
            }
        }
        
        let collision = detectCollision()
        let scoreToUpdate = numberOfCars(inRow: getRow(1))
        
        replaceTopRow(withNewRow: newRandomRow)
        emptyRowFromRivalCars(0)
        
        cellStates[position(forColumn: playerCarPosition, andRow: 0)] = collision ? .Crash : .Player
        
        delegate?.gameStateDidUpdate(self)
        
        if !collision {
            score += scoreToUpdate
            level = Int(floor(Double(score / 100))) + 1
        }
    }
    
    private mutating func replaceTopRow(withNewRow row: [CellState]) {
        guard row.count == numberOfColumns else { fatalError("The row passed should have \(numberOfColumns) elements") }
        var newCellStates = cellStates
        newCellStates.removeFirst(row.count)
        newCellStates.append(contentsOf: row)
        cellStates = newCellStates
    }
    
    private func detectCollision() -> Bool {
        var collision = false
        
        if cellStates[position(forColumn: playerCarPosition, andRow: 1)] == .Car {
            collision = true
        }
        
        return collision
    }
    
    private mutating func emptyRowFromRivalCars(_ row: Int) {
        guard row >= 0 && row < numberOfRows - 1 else { fatalError("The row \(row) to be emptied does not exist. There are \(numberOfRows) rows.") }
        var newCellStates = cellStates
        
        for column in 0..<numberOfColumns {
            let position = self.position(forColumn: column, andRow: row)
            if cellStates[position] == .Car {
                newCellStates[position] = .Empty
            }
        }

        self.cellStates = newCellStates
    }
    
    private func cellState(forRow row: [CellState], atIndex index: Int) -> CellState? {
        var cellState: CellState?
        
        if index >= 0 && index < row.count {
            cellState = row[index]
        }
        
        return cellState
    }
    
    private func numberOfEmptyNeighbours(forColumn column: Int, andRow row: Int) -> Int {
        var numberOfEmptyNeighbours = 0
        
        if let southWest = cellState(forColumn: column - 1, andRow: row - 1),
            southWest == .Empty {
            numberOfEmptyNeighbours += 1
        }
        
        if let south = cellState(forColumn: column, andRow: row - 1),
            south == .Empty {
            numberOfEmptyNeighbours += 1
        }
        
        if let southEast = cellState(forColumn: column + 1, andRow: row - 1),
            southEast == .Empty {
            numberOfEmptyNeighbours += 1
        }
        
        return numberOfEmptyNeighbours
    }
    
    private func position(forColumn column: Int, andRow row: Int) -> Int {
        return (row * numberOfColumns) + column
    }
    
    private func removingAleatoryCar(inRow row: [CellState]) -> [CellState] {
        let position = randomNumber(range: 0...row.count - 1)
        var newRow = row
        newRow[position] = .Empty
        
        return newRow
    }
    
    private func randomNumber(range: ClosedRange<Int>) -> Int {
        let min = range.lowerBound
        let max = range.upperBound
        return Int(arc4random_uniform(UInt32(1 + max - min))) + min
    }
}
