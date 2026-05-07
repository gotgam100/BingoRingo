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
            await registerForNotifications(memberID: user.uid)
        }
    }

    /// 로그인 성공 시 호출 — 알림 권한 요청 + 보류 중이던 FCM 토큰 저장 + 언어 동기화
    private func registerForNotifications(memberID: String) async {
        await NotificationService.shared.requestPermission()
        await NotificationService.shared.flushPendingToken(memberID: memberID)
        await NotificationService.shared.syncCurrentToken(memberID: memberID)
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "한글"
        try? await FirestoreService.shared.updateLanguage(memberID: memberID, language: language)
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
                    if let id = member.id { await self.registerForNotifications(memberID: id) }
                } catch {
                    self.errorMessage = "로그인 실패: \(error.localizedDescription)"
                }
                self.isLoading = false
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = "로그인 실패: \(error.localizedDescription)"
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
                if let id = member.id { await self.registerForNotifications(memberID: id) }
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
                if let id = member.id { await self.registerForNotifications(memberID: id) }
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
                if let id = member.id { await self.registerForNotifications(memberID: id) }
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
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        // 단일 기기 멀티 계정 시나리오: 로그아웃 시 FCM 토큰을 제거하여
        // 다음 사용자에게 잘못된 알림이 가지 않도록 한다.
        if let memberID = currentMember?.id {
            Task { await NotificationService.shared.clearFCMToken(memberID: memberID) }
        }
        try? AuthService.shared.signOut()
        PremiumManager.shared.resetStatus()
        currentMember = nil
        isLoggedIn = false
    }

    func deleteAccount() async {
        isLoading = true
        if let memberID = currentMember?.id {
            await NotificationService.shared.clearFCMToken(memberID: memberID)
        }
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
