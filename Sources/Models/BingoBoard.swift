import Foundation

struct BingoBoard: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var size: Int = 5
    var cells: [BingoCell]
    var memberIDs: [String]
    var leaderID: String
    var createdAt: Date = Date()

    /// 안전한 셀 접근 — 인덱스 범위 초과 시 빈 셀 반환
    func cell(row: Int, col: Int) -> BingoCell {
        let index = row * size + col
        guard index >= 0, index < cells.count else { return BingoCell(title: "") }
        return cells[index]
    }

    mutating func setCell(_ cell: BingoCell, row: Int, col: Int) {
        let index = row * size + col
        guard index >= 0, index < cells.count else { return }
        cells[index] = cell
    }

    // MARK: - Firestore 역호환: 키 누락 + 타입 불일치 모두 기본값으로 처리

    enum CodingKeys: String, CodingKey {
        case id, title, size, cells, memberIDs, leaderID, createdAt
    }

    init(from decoder: Decoder) throws {
        let c     = try decoder.container(keyedBy: CodingKeys.self)
        id        = (try? c.decode(String.self,      forKey: .id))        ?? UUID().uuidString
        title     = (try? c.decode(String.self,      forKey: .title))     ?? ""
        let s     = (try? c.decode(Int.self,         forKey: .size))      ?? 5
        size      = s
        memberIDs = (try? c.decode([String].self,    forKey: .memberIDs)) ?? []
        leaderID  = (try? c.decode(String.self,      forKey: .leaderID))  ?? ""
        createdAt = (try? c.decode(Date.self,        forKey: .createdAt)) ?? Date()

        // cells: 디코딩 실패 시 size×size 개의 빈 셀로 복구
        let decoded = (try? c.decode([BingoCell].self, forKey: .cells)) ?? []
        if decoded.count == s * s {
            cells = decoded
        } else if decoded.isEmpty {
            cells = (0..<(s * s)).map { _ in BingoCell(title: "") }
        } else {
            // 일부만 디코딩된 경우: 있는 것 유지 + 나머지 빈 셀로 채움
            var result = decoded
            while result.count < s * s { result.append(BingoCell(title: "")) }
            cells = Array(result.prefix(s * s))
        }
    }

    init(title: String, size: Int = 5, cells: [BingoCell],
         memberIDs: [String], leaderID: String) {
        self.title = title
        self.size = size
        self.cells = cells
        self.memberIDs = memberIDs
        self.leaderID = leaderID
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(size, forKey: .size)
        try c.encode(cells, forKey: .cells)
        try c.encode(memberIDs, forKey: .memberIDs)
        try c.encode(leaderID, forKey: .leaderID)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
