import Foundation
import FirebaseAuth
import AuthenticationServices
import CryptoKit

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published var currentMember: Member?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var authListener: AuthStateDidChangeListenerHandle?
    private(set) var currentNonce: String?

    override init() {
        super.init()
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            self.isLoggedIn = user != nil
            if let user {
                Task { await self.loadMemberIfNeeded(user: user) }
            } else {
                self.currentMember = nil
            }
        }
    }

    private func loadMemberIfNeeded(user: FirebaseAuth.User) async {
        guard currentMember == nil else { return }
        if let member = try? await FirestoreService.shared.fetchMember(id: user.uid) {
            self.currentMember = member
        }
    }

    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, Error>, nonce: String?) {
        switch result {
        case .success(let auth):
            guard
                let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = appleCredential.identityToken,
                let token = String(data: tokenData, encoding: .utf8),
                let nonce = nonce
            else {
                errorMessage = "Apple 로그인 정보를 가져오지 못했어요."
                return
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: token,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )
            isLoading = true
            Task {
                do {
                    let member = try await AuthService.shared.signInWithApple(credential: credential)
                    self.currentMember = member
                    self.isLoggedIn = true
                } catch {
                    self.errorMessage = "로그인 실패: \(error.localizedDescription)"
                    print("❌ Apple Sign In error: \(error)")
                }
                self.isLoading = false
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "로그인 실패: \(error.localizedDescription)"
                print("❌ Apple auth error: \(error)")
            }
        }
    }

    func signInWithGoogle() {
        isLoading = true
        Task {
            do {
                let member = try await AuthService.shared.signInWithGoogle()
                self.currentMember = member
                self.isLoggedIn = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func signInWithEmail(email: String, password: String) {
        isLoading = true
        Task {
            do {
                let member = try await AuthService.shared.signInWithEmail(email: email, password: password)
                self.currentMember = member
                self.isLoggedIn = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func signUpWithEmail(email: String, password: String) {
        isLoading = true
        Task {
            do {
                let member = try await AuthService.shared.signUpWithEmail(email: email, password: password)
                self.currentMember = member
                self.isLoggedIn = true
            } catch {
                self.errorMessage = error.localizedDescription
            }
            self.isLoading = false
        }
    }

    func updateProfile(nickname: String, emoji: String) async {
        guard var member = currentMember else { return }
        member.displayName = nickname
        member.profileEmoji = emoji
        do {
            try await FirestoreService.shared.updateMember(member)
            self.currentMember = member
        } catch {
            print("❌ profile update error: \(error)")
        }
    }

    func signOut() {
        try? AuthService.shared.signOut()
        PremiumManager.shared.resetStatus()
        currentMember = nil
        isLoggedIn = false
    }

    func deleteAccount() async {
        isLoading = true
        do {
            try await AuthService.shared.deleteAccount()
            PremiumManager.shared.resetStatus()
            currentMember = nil
            isLoggedIn = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Nonce

    private func randomNonceString(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
