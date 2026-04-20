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

                // 로고
                VStack(spacing: 24) {
                    BingoRingoLogo()
                        .frame(width: 110, height: 110)

                    VStack(spacing: 8) {
                        Text("BingoRingo")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 2)

                        Text("함께하는 빙고 To Do")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(BRColors.yellow)
                            .tracking(1)
                    }
                }

                Spacer()

                // 버튼 영역
                VStack(spacing: 12) {
                    if authViewModel.isLoading {
                        ProgressView().tint(.white)
                            .frame(height: 54)
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
                            .font(.system(size: 12))
                            .foregroundStyle(BRColors.yellow)
                            .multilineTextAlignment(.center)
                    }

                    Text("로그인하면 서비스 이용약관에 동의하게 됩니다.")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
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

struct BingoRingoLogo: View {
    var body: some View {
        ZStack {
            Blob1()
                .fill(Color.white.opacity(0.15))

            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { col in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(logoColor(row: row, col: col))
                                .frame(width: 22, height: 22)
                        }
                    }
                }
            }
        }
    }

    private func logoColor(row: Int, col: Int) -> Color {
        let grid: [[Color]] = [
            [BRColors.yellow, .white.opacity(0.9), BRColors.red],
            [.white.opacity(0.9), BRColors.green.opacity(0.8), .white.opacity(0.9)],
            [BRColors.red, .white.opacity(0.9), BRColors.yellow]
        ]
        return grid[row][col]
    }
}

#Preview {
    OnboardingView().environmentObject(AuthViewModel())
}
