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

    // MARK: - Firestore 역호환: 키 누락 + 타입 불일치 모두 기본값으로 처리

    enum CodingKeys: String, CodingKey {
        case id, name, inviteCode, memberIDs, leaderID, boardID
        case boardSize, completedLinesCount, lineRewards, allBingoReward, isCompleted, createdAt
    }

    init(from decoder: Decoder) throws {
        let c               = try decoder.container(keyedBy: CodingKeys.self)
        id                  = (try? c.decode(String.self,   forKey: .id))                  ?? UUID().uuidString
        name                = (try? c.decode(String.self,   forKey: .name))                ?? ""
        inviteCode          = (try? c.decode(String.self,   forKey: .inviteCode))          ?? ""
        memberIDs           = (try? c.decode([String].self, forKey: .memberIDs))           ?? []
        leaderID            = (try? c.decode(String.self,   forKey: .leaderID))            ?? ""
        boardID             = try? c.decode(String.self,    forKey: .boardID)
        boardSize           = (try? c.decode(Int.self,      forKey: .boardSize))           ?? 5
        completedLinesCount = (try? c.decode(Int.self,      forKey: .completedLinesCount)) ?? 0
        lineRewards         = (try? c.decode([String].self, forKey: .lineRewards))         ?? []
        allBingoReward      = (try? c.decode(String.self,   forKey: .allBingoReward))      ?? ""
        isCompleted         = (try? c.decode(Bool.self,     forKey: .isCompleted))         ?? false
        createdAt           = (try? c.decode(Date.self,     forKey: .createdAt))           ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(inviteCode, forKey: .inviteCode)
        try c.encode(memberIDs, forKey: .memberIDs)
        try c.encode(leaderID, forKey: .leaderID)
        try c.encodeIfPresent(boardID, forKey: .boardID)
        try c.encode(boardSize, forKey: .boardSize)
        try c.encode(completedLinesCount, forKey: .completedLinesCount)
        try c.encode(lineRewards, forKey: .lineRewards)
        try c.encode(allBingoReward, forKey: .allBingoReward)
        try c.encode(isCompleted, forKey: .isCompleted)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
