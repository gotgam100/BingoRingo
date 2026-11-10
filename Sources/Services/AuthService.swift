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

    /// Firebase는 로그인한 지 오래되면(약 5분) 계정 삭제를 거부한다.
    /// 데이터를 지우기 전에 미리 확인해서, 데이터만 지워지고 계정은 남는 상태를 막는다.
    var needsRecentLoginForDeletion: Bool {
        guard let lastSignIn = currentUser?.metadata.lastSignInDate else { return true }
        return Date().timeIntervalSince(lastSignIn) > 4 * 60
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        // 1. 참여 중인 방에서 빠지기 (남은 멤버들이 빙고를 계속 달성할 수 있도록)
        try await FirestoreService.shared.removeMemberFromAllGroups(memberID: user.uid)
        // 2. 회원 정보 삭제 → 3. 로그인 계정 삭제 (Firestore 권한이 필요하므로 이 순서)
        try await FirestoreService.shared.deleteMember(id: user.uid)
        try await user.delete()
    }

    static func isRequiresRecentLogin(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == AuthErrorDomain
            && nsError.code == AuthErrorCode.requiresRecentLogin.rawValue
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
