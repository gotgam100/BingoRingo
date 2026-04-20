import Foundation

struct BingoCell: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var description: String = ""
    var completedBy: [String] = []     // 완료한 멤버 ID 목록
    var proofPhotoURLs: [String: String] = [:]  // memberID: photoURL

    func isCompleted(for memberIDs: [String]) -> Bool {
        memberIDs.allSatisfy { completedBy.contains($0) }
    }

    func completionRatio(for memberIDs: [String]) -> Double {
        guard !memberIDs.isEmpty else { return 0 }
        return Double(completedBy.count) / Double(memberIDs.count)
    }
}
