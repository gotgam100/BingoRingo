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

    func signInWithGoogle() async throws -> Member {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else {
                continuation.resume(throwing: AuthError.noRootViewController)
                return
            }

            Task { @MainActor [weak self] in
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    continuation.resume(throwing: AuthError.noRootViewController)
                    return
                }

                // GIDSignIn completion handler 기반 API - async/await 대체 함수 없음 (라이브러리 제한)
                nonisolated(unsafe) let _ = GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let result = result, let idToken = result.user.idToken?.tokenString else {
                        continuation.resume(throwing: AuthError.noToken)
                        return
                    }

                    let credential = GoogleAuthProvider.credential(
                        withIDToken: idToken,
                        accessToken: result.user.accessToken.tokenString
                    )

                    Task { [weak self] in
                        do {
                            let authResult = try await Auth.auth().signIn(with: credential)
                            guard let self = self else {
                                continuation.resume(throwing: AuthError.noRootViewController)
                                return
                            }
                            let member = try await self.fetchOrCreateMember(from: authResult.user)
                            continuation.resume(returning: member)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
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
            displayName: user.displayName ?? "사용자",
            profileImageURL: user.photoURL?.absoluteString,
            email: user.email ?? ""
        )
        try ref.setData(from: newMember)
        return newMember
    }
}
