import Foundation
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

final class AuthService: @unchecked Sendable {
    static let shared = AuthService()
    private let db = Firestore.firestore()

    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }
    var currentUserID: String? { currentUser?.uid }

    func signInWithApple(credential: AuthCredential) async throws -> Member {
        let result = try await Auth.auth().signIn(with: credential)
        return try await fetchOrCreateMember(from: result.user)
    }

    @MainActor
    func signInWithGoogle() async throws -> Member {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.noToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        return try await fetchOrCreateMember(from: authResult.user)
    }

    func signInWithEmail(email: String, password: String) async throws -> Member {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return try await fetchOrCreateMember(from: result.user)
    }

    func signUpWithEmail(email: String, password: String) async throws -> Member {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return try await fetchOrCreateMember(from: result.user)
    }

    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        try Auth.auth().signOut()
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await FirestoreService.shared.deleteMember(id: user.uid)
        try await user.delete()
    }

    enum AuthError: LocalizedError {
        case noRootViewController
        case noToken

        var errorDescription: String? {
            switch self {
            case .noRootViewController: return "화면 정보를 가져올 수 없어요."
            case .noToken: return "구글 토큰을 가져올 수 없어요."
            }
        }
    }

    private func fetchOrCreateMember(from user: FirebaseAuth.User) async throws -> Member {
        let ref = db.collection("members").document(user.uid)
        let snapshot = try await ref.getDocument()

        if snapshot.exists, let member = try? snapshot.data(as: Member.self) {
            return member
        }

        let newMember = Member(
            id: user.uid,
            displayName: user.displayName ?? (Localization.isEnglish ? "User" : "사용자"),
            profileImageURL: user.photoURL?.absoluteString,
            email: user.email ?? ""
        )
        try ref.setData(from: newMember)
        return newMember
    }
}
