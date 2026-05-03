import Foundation

struct BingoCell: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var description: String = ""
    var completedBy: [String] = []
    var completedAt: [String: Date] = [:]

    func isCompleted(for memberIDs: [String]) -> Bool {
        memberIDs.allSatisfy { completedBy.contains($0) }
    }


}
