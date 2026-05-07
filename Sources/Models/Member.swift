import Foundation
import FirebaseFirestore

struct Member: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var displayName: String
    var profileImageURL: String?
    var email: String
    var profileEmoji: String = "😀"
    var fcmToken: String?
    var fcmTokenUpdatedAt: Date?
    var language: String

    init(id: String, displayName: String, profileImageURL: String? = nil,
         email: String, profileEmoji: String = "😀",
         fcmToken: String? = nil, fcmTokenUpdatedAt: Date? = nil,
         language: String = "한글") {
        self.id = id
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.email = email
        self.profileEmoji = profileEmoji
        self.fcmToken = fcmToken
        self.fcmTokenUpdatedAt = fcmTokenUpdatedAt
        self.language = language
    }

    // MARK: - Firestore 역호환: @DocumentID는 Firebase SDK가 처리하므로 CodingKeys 제외

    enum CodingKeys: String, CodingKey {
        case displayName, profileImageURL, email, profileEmoji, fcmToken, fcmTokenUpdatedAt, language
    }

    init(from decoder: Decoder) throws {
        _id               = try DocumentID<String>(from: decoder)
        let c             = try decoder.container(keyedBy: CodingKeys.self)
        displayName       = (try? c.decode(String.self, forKey: .displayName))     ?? ""
        profileImageURL   = try? c.decode(String.self,  forKey: .profileImageURL)
        email             = (try? c.decode(String.self, forKey: .email))           ?? ""
        profileEmoji      = (try? c.decode(String.self, forKey: .profileEmoji))    ?? "😀"
        fcmToken          = try? c.decode(String.self,  forKey: .fcmToken)
        fcmTokenUpdatedAt = try? c.decode(Date.self,    forKey: .fcmTokenUpdatedAt)
        language          = (try? c.decode(String.self, forKey: .language))        ?? "한글"
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(displayName, forKey: .displayName)
        try c.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try c.encode(email, forKey: .email)
        try c.encode(profileEmoji, forKey: .profileEmoji)
        try c.encodeIfPresent(fcmToken, forKey: .fcmToken)
        try c.encodeIfPresent(fcmTokenUpdatedAt, forKey: .fcmTokenUpdatedAt)
        try c.encode(language, forKey: .language)
    }
}
