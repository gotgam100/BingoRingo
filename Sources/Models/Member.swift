import Foundation

struct Member: Identifiable, Codable {
    var id: String
    var displayName: String
    var profileImageURL: String?
    var email: String
}
