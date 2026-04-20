import Foundation
import FirebaseFirestore

struct Member: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var profileImageURL: String?
    var email: String
}
