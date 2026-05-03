import Foundation
import FirebaseFirestore

struct Member: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var displayName: String
    var profileImageURL: String?
    var email: String
    var profileEmoji: String = "😀"

    init(id: String, displayName: String, profileImageURL: String? = nil, email: String, profileEmoji: String = "😀") {
        self.id = id
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.email = email
        self.profileEmoji = profileEmoji
    }
}
