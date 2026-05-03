import Foundation

struct BingoReward: Identifiable, Codable {
    var id: String = UUID().uuidString
    var lineIndex: Int          // 완성된 라인 번호
    var lineType: LineType
    var description: String


    enum LineType: String, Codable {
        case row, column, diagonal
    }
}
