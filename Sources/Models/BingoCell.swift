import Foundation

struct BingoCell: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var description: String = ""
    var completedBy: [String] = []
    var completedAt: [String: Date] = [:]
    var proofImageURLs: [String: String] = [:]

    init(title: String, description: String = "") {
        self.title = title
        self.description = description
    }

    func isCompleted(for memberIDs: [String]) -> Bool {
        memberIDs.allSatisfy { completedBy.contains($0) }
    }

    // MARK: - Firestore 역호환: 키 누락 + 타입 불일치 모두 기본값으로 처리

    enum CodingKeys: String, CodingKey {
        case id, title, description, completedBy, completedAt, proofImageURLs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = (try? c.decode(String.self,             forKey: .id))             ?? UUID().uuidString
        title          = (try? c.decode(String.self,             forKey: .title))          ?? ""
        description    = (try? c.decode(String.self,             forKey: .description))    ?? ""
        completedBy    = (try? c.decode([String].self,           forKey: .completedBy))    ?? []
        completedAt    = (try? c.decode([String: Date].self,     forKey: .completedAt))    ?? [:]
        proofImageURLs = (try? c.decode([String: String].self,   forKey: .proofImageURLs)) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(description, forKey: .description)
        try c.encode(completedBy, forKey: .completedBy)
        try c.encode(completedAt, forKey: .completedAt)
        try c.encode(proofImageURLs, forKey: .proofImageURLs)
    }
}
