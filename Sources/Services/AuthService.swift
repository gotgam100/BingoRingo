import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AuthService {
    static let shared = AuthService()
    private let db = Firestore.firestore()

    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }
    var currentUserID: String? { currentUser?.uid }

    func signInWithApple(credential: AuthCredential) async throws -> Member {
        let result = try await Auth.auth().signIn(with: credential)
        return try await fetchOrCreateMember(from: result.user)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    private func fetchOrCreateMember(from user: FirebaseAuth.User) async throws -> Member {
        let ref = db.collection("members").document(user.uid)
        let snapshot = try await ref.getDocument()

        if snapshot.exists, let member = try? snapshot.data(as: Member.self) {
            return member
        }

        let newMember = Member(
            id: user.uid,
            displayName: user.displayName ?? "사용자",
            profileImageURL: user.photoURL?.absoluteString,
            email: user.email ?? ""
        )
        try ref.setData(from: newMember)
        return newMember
    }
}
