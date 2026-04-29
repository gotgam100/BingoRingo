import SwiftUI

struct EmailAuthSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @FocusState private var focusedField: Field?

    private enum Field { case email, password, passwordConfirm }

    private var isFormValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 6
        if isSignUp { return emailOK && passwordOK && password == passwordConfirm }
        return emailOK && passwordOK
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()
                    .allowsHitTesting(false)

                Circle()
                    .fill(BRColors.primaryDim)
                    .frame(width: 200, height: 200)
                    .offset(x: 150, y: -160)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 헤더
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(BRColors.primaryDim)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(BRColors.primary)
                                }
                                Text(isSignUp ? "회원가입" : "이메일 로그인")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                            }
                            Text(isSignUp ? "이메일로\n시작해요" : "다시\n만났네요!")
                                .font(Paperlogy.black(28))
                                .foregroundStyle(BRColors.onSurface)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 32)

                        VStack(spacing: 16) {
                            // 이메일
                            VStack(alignment: .leading, spacing: 8) {
                                Text("e-mail")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                                    .tracking(0.5)
                                TextField("이메일 주소 입력", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(BRColors.onSurface)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                    .background(BRColors.surfaceLow)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            // 비밀번호
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 5) {
                                    Text("비밀번호")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(BRColors.onSurfaceMuted)
                                        .tracking(0.5)
                                    Text("Password")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(BRColors.onSurfaceMuted.opacity(0.5))
                                }
                                SecureField("6자 이상 입력", text: $password)
                                    .focused($focusedField, equals: .password)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(BRColors.onSurface)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                    .background(BRColors.surfaceLow)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            // 비밀번호 확인 (회원가입만)
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 5) {
                                        Text("비밀번호 확인")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(BRColors.onSurfaceMuted)
                                            .tracking(0.5)
                                        Text("Confirm")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(BRColors.onSurfaceMuted.opacity(0.5))
                                    }
                                    SecureField("비밀번호 다시 입력", text: $passwordConfirm)
                                        .focused($focusedField, equals: .passwordConfirm)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(BRColors.onSurface)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 16)
                                        .background(
                                            !passwordConfirm.isEmpty && passwordConfirm != password
                                                ? BRColors.tertiary.opacity(0.08)
                                                : BRColors.surfaceLow
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .strokeBorder(
                                                    !passwordConfirm.isEmpty && passwordConfirm != password
                                                        ? BRColors.tertiary.opacity(0.5)
                                                        : Color.clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    if !passwordConfirm.isEmpty && passwordConfirm != password {
                                        Text("비밀번호가 일치하지 않아요")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(BRColors.tertiary)
                                    }
                                }
                                .animation(.easeInOut(duration: 0.2), value: isSignUp)
                            }

                            // 오류 메시지
                            if let error = authViewModel.errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text(error)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(BRColors.tertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(BRColors.tertiary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal, 24)

                        // 제출 버튼
                        Button {
                            focusedField = nil
                            authViewModel.errorMessage = nil
                            if isSignUp {
                                authViewModel.signUpWithEmail(email: email, password: password)
                            } else {
                                authViewModel.signInWithEmail(email: email, password: password)
                            }
                        } label: {
                            Group {
                                if authViewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isSignUp ? "가입하기" : "로그인")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                isFormValid
                                    ? AnyShapeStyle(BRColors.primaryGradient)
                                    : AnyShapeStyle(BRColors.surfaceContainer)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 48))
                            .shadow(
                                color: isFormValid ? BRColors.primary.opacity(0.3) : .clear,
                                radius: 16, y: 5
                            )
                        }
                        .disabled(!isFormValid || authViewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                        // 전환 버튼
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSignUp.toggle()
                                authViewModel.errorMessage = nil
                                passwordConfirm = ""
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSignUp ? "이미 계정이 있어요?" : "계정이 없어요?")
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                                HStack(spacing: 3) {
                                    Text(isSignUp ? "로그인" : "회원가입")
                                    if !isSignUp {
                                        Text("Sign Up")
                                            .font(.system(size: 12, weight: .medium))
                                            .opacity(0.7)
                                    }
                                }
                                .foregroundStyle(BRColors.primary)
                                .fontWeight(.bold)
                            }
                            .font(.system(size: 14))
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        authViewModel.errorMessage = nil
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(BRColors.primary)
                }
            }
        }
        .onChange(of: authViewModel.isLoggedIn) { _, loggedIn in
            if loggedIn { dismiss() }
        }
    }
}
