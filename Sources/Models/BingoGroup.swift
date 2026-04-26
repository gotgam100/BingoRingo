import Foundation

struct BingoGroup: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var inviteCode: String
    var memberIDs: [String]
    var leaderID: String
    var boardID: String?
    var boardSize: Int = 5
    var completedLinesCount: Int = 0
    var lineRewards: [String] = []
    var allBingoReward: String = ""
    var isCompleted: Bool = false
    var createdAt: Date = Date()

    init(name: String, inviteCode: String, memberIDs: [String], leaderID: String,
         boardSize: Int = 5) {
        self.name = name
        self.inviteCode = inviteCode
        self.memberIDs = memberIDs
        self.leaderID = leaderID
        self.boardSize = boardSize
    }
}
