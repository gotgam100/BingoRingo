import Foundation

struct BingoGroup: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var inviteCode: String
    var memberIDs: [String]
    var leaderID: String
    var boardID: String?
    var boardSize: Int = 5
    var completedLinesCount: Int = 0
    var createdAt: Date = Date()
}
