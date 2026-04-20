import SwiftUI
import AuthenticationServices

struct OnboardingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            GeometricBackground()

            VStack(spacing: 0) {
                Spacer()

                // 로고 영역
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(BRColors.cobaltBlue)
                            .frame(width: 100, height: 100)
                        Text("🎯")
                            .font(.system(size: 48))
                    }

                    Text("BingoRingo")
                        .font(BRTypography.appTitle)
                        .foregroundStyle(BRColors.cobaltBlue)

                    Text("함께하는 빙고 To Do")
                        .font(BRTypography.sectionTitle)
                        .foregroundStyle(BRColors.orange)
                }

                Spacer()

                // 로그인 버튼 영역
                VStack(spacing: 16) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(BRColors.cobaltBlue)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            let appleRequest = authViewModel.startSignInWithApple()
                            request.requestedScopes = appleRequest.requestedScopes
                            request.nonce = appleRequest.nonce
                        } onCompletion: { result in
                            authViewModel.handleAppleSignIn(result: result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(BRTypography.caption)
                            .foregroundStyle(BRColors.red)
                            .multilineTextAlignment(.center)
                    }

                    Text("로그인 시 서비스 이용약관에 동의하게 됩니다.")
                        .font(BRTypography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthViewModel())
}
