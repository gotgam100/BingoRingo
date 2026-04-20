import Foundation

struct BingoBoard: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var size: Int = 5
    var cells: [[BingoCell]]
    var rewards: [BingoReward]
    var memberIDs: [String]
    var leaderID: String
    var createdAt: Date = Date()
}
