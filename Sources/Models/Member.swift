import Foundation
import FirebaseFirestore

struct Member: Identifiable, Codable {
    @DocumentID var id: String?
    var displayName: String
    var profileImageURL: String?
    var email: String

    init(id: String, displayName: String, profileImageURL: String? = nil, email: String) {
        self.id = id
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.email = email
    }
}
