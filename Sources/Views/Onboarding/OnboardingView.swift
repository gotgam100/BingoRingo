import SwiftUI
import AuthenticationServices
import CryptoKit
import GoogleSignIn

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var currentNonce: String?
    @State private var showEmailAuth = false

    var body: some View {
        ZStack {
            OnboardingBackground()

            VStack(spacing: 0) {
                Spacer()

                // 로고 + 타이틀
                VStack(spacing: 32) {
                    BingoRingoLogo()
                        .frame(width: 120, height: 120)

                    VStack(spacing: 10) {
                        Text("BingoRingo")
                            .font(Paperlogy.black(48))
                            .foregroundStyle(BRColors.onSurface)
                            .tracking(-1)

                        Text("함께하는 빙고 To Do")
                            .font(Paperlogy.medium(15))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                            .tracking(0.5)
                    }
                }

                Spacer()

                // 버튼 영역
                VStack(spacing: 12) {
                    if authViewModel.isLoading {
                        ProgressView().tint(BRColors.primary).frame(height: 58)
                    } else {
                        // Apple 로그인
                        ZStack {
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = randomNonceString()
                                currentNonce = nonce
                                request.requestedScopes = [.fullName, .email]
                                request.nonce = sha256(nonce)
                            } onCompletion: { result in
                                authViewModel.handleAppleSignIn(result: result, nonce: currentNonce)
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 58)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 48))
                        .shadow(color: .black.opacity(0.15), radius: 16, y: 5)

                        // 구분선
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(BRColors.outlineVariant)
                                .frame(height: 1)
                            Text("또는")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(BRColors.onSurfaceMuted)
                            Rectangle()
                                .fill(BRColors.outlineVariant)
                                .frame(height: 1)
                        }
                        .padding(.vertical, 2)

                        // 구글 로그인
                        Button {
                            authViewModel.signInWithGoogle()
                        } label: {
                            HStack(spacing: 10) {
                                GoogleLogoMark()
                                    .frame(width: 22, height: 22)
                                Text("Google로 계속하기")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#3c4043"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 48))
                            .overlay(
                                RoundedRectangle(cornerRadius: 48)
                                    .strokeBorder(Color(hex: "#dadce0"), lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
                        }

                        // 이메일 로그인
                        Button {
                            showEmailAuth = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(BRColors.primary)
                                Text("이메일로 계속하기")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(BRColors.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(BRColors.primaryDim)
                            .clipShape(RoundedRectangle(cornerRadius: 48))
                        }
                    }

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BRColors.tertiary)
                            .multilineTextAlignment(.center)
                    }

                    Text("로그인하면 서비스 이용약관에 동의하게 됩니다.")
                        .font(.system(size: 11))
                        .foregroundStyle(BRColors.onSurfaceMuted)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthSheet()
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

// MARK: - Google 로고 (공식 색상 G 마크)
struct GoogleLogoMark: View {
    var body: some View {
        Canvas { ctx, size in
            let s = size.width
            // 파란 호
            ctx.stroke(Path { p in
                p.addArc(center: CGPoint(x: s/2, y: s/2), radius: s/2 - 1,
                         startAngle: .degrees(-10), endAngle: .degrees(85), clockwise: false)
            }, with: .color(Color(hex: "#4285F4")), lineWidth: s * 0.22)
            // 초록 호
            ctx.stroke(Path { p in
                p.addArc(center: CGPoint(x: s/2, y: s/2), radius: s/2 - 1,
                         startAngle: .degrees(85), endAngle: .degrees(165), clockwise: false)
            }, with: .color(Color(hex: "#34A853")), lineWidth: s * 0.22)
            // 노란 호
            ctx.stroke(Path { p in
                p.addArc(center: CGPoint(x: s/2, y: s/2), radius: s/2 - 1,
                         startAngle: .degrees(165), endAngle: .degrees(225), clockwise: false)
            }, with: .color(Color(hex: "#FBBC05")), lineWidth: s * 0.22)
            // 빨간 호
            ctx.stroke(Path { p in
                p.addArc(center: CGPoint(x: s/2, y: s/2), radius: s/2 - 1,
                         startAngle: .degrees(225), endAngle: .degrees(350), clockwise: false)
            }, with: .color(Color(hex: "#EA4335")), lineWidth: s * 0.22)
            // 가로바 (파란)
            ctx.fill(Path { p in
                p.addRect(CGRect(x: s/2 - 1, y: s/2 - s*0.12, width: s/2 - 1, height: s * 0.22))
            }, with: .color(Color(hex: "#4285F4")))
        }
    }
}

// 3×3 미니 빙고 로고
struct BingoRingoLogo: View {
    private let palette: [[Color]] = [
        [Color(hex: "#204bde"), Color(hex: "#edf0ff"),  Color(hex: "#ffc5aa")],
        [Color(hex: "#edf0ff"),  Color(hex: "#204bde"), Color(hex: "#edf0ff")],
        [Color(hex: "#ffd79c"),  Color(hex: "#edf0ff"),  Color(hex: "#204bde")]
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(BRColors.surfaceLow)
                .shadow(color: BRColors.primary.opacity(0.15), radius: 20, y: 8)

            VStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { col in
                            RoundedRectangle(cornerRadius: 6)
                                .fill(palette[row][col])
                                .frame(width: 26, height: 26)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    OnboardingView().environmentObject(AuthViewModel())
}
