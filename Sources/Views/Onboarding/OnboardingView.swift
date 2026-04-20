import SwiftUI
import AuthenticationServices
import CryptoKit

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentNonce: String?

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                // 로고 영역
                VStack(spacing: 20) {
                    // 기하학 로고
                    BingoRingoLogo()
                        .frame(width: 100, height: 100)

                    VStack(spacing: 8) {
                        Text("BingoRingo")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("함께하는 빙고 To Do")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(BRColors.beige)
                    }
                }

                Spacer()

                // 로그인 버튼
                VStack(spacing: 14) {
                    if authViewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            let nonce = randomNonceString()
                            currentNonce = nonce
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = sha256(nonce)
                        } onCompletion: { result in
                            authViewModel.handleAppleSignIn(result: result, nonce: currentNonce)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(BRColors.beige)
                            .multilineTextAlignment(.center)
                    }

                    Text("로그인하면 서비스 이용약관에 동의하게 됩니다.")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
    }

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

// 기하학 로고 뷰
struct BingoRingoLogo: View {
    var body: some View {
        ZStack {
            // 배경 원
            Circle()
                .fill(Color.white.opacity(0.15))

            // 그리드 패턴 (미니 빙고)
            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(cellColor(row: row, col: col))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }
        }
    }

    private func cellColor(row: Int, col: Int) -> Color {
        let colors: [[Color]] = [
            [BRColors.orange, .white, BRColors.red],
            [.white, BRColors.beige, .white],
            [BRColors.red, .white, BRColors.orange]
        ]
        return colors[row][col]
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
