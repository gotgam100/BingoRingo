import Foundation

struct BingoBoard: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var size: Int = 5
    var cells: [BingoCell]          // 1D 배열, index = row * size + col
    var memberIDs: [String]
    var leaderID: String
    var createdAt: Date = Date()

    func cell(row: Int, col: Int) -> BingoCell {
        cells[row * size + col]
    }

    mutating func setCell(_ cell: BingoCell, row: Int, col: Int) {
        cells[row * size + col] = cell
    }
}
