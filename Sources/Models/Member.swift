import Foundation
import FirebaseFirestore

struct Member: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var displayName: String
    var profileImageURL: String?
    var email: String
    var profileEmoji: String = "😀"

    init(id: String, displayName: String, profileImageURL: String? = nil,
         email: String, profileEmoji: String = "😀") {
        self.id = id
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.email = email
        self.profileEmoji = profileEmoji
    }

    // MARK: - Firestore 역호환: @DocumentID는 Firebase SDK가 처리하므로 CodingKeys 제외

    enum CodingKeys: String, CodingKey {
        case displayName, profileImageURL, email, profileEmoji
    }

    init(from decoder: Decoder) throws {
        _id             = try DocumentID<String>(from: decoder)
        let c           = try decoder.container(keyedBy: CodingKeys.self)
        displayName     = (try? c.decode(String.self, forKey: .displayName))     ?? ""
        profileImageURL = try? c.decode(String.self,  forKey: .profileImageURL)
        email           = (try? c.decode(String.self, forKey: .email))           ?? ""
        profileEmoji    = (try? c.decode(String.self, forKey: .profileEmoji))    ?? "😀"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(displayName, forKey: .displayName)
        try c.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try c.encode(email, forKey: .email)
        try c.encode(profileEmoji, forKey: .profileEmoji)
    }
}
