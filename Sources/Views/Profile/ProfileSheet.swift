import SwiftUI

struct ProfileSheet: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var nickname: String = ""
    @State private var selectedEmoji: String = "😀"
    @State private var isSaving = false
    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false

    private let emojiGrid: [[String]] = [
        ["😀","😄","😊","🥹","😎","🤩","🥳","😏","🤔","😴"],
        ["🐶","🐱","🐭","🐰","🦊","🐻","🐼","🐨","🐯","🦁"],
        ["🐸","🐧","🦋","🦄","🐉","🦖","🐙","🦈","🦊","🐺"],
        ["🍎","🍊","🍋","🍇","🍓","🍔","🍕","🍣","🍦","🎂"],
        ["⚽️","🏀","🎯","🎨","🎸","🎮","🚀","⭐️","🔥","💎"],
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()
                    .allowsHitTesting(false)

                // 배경 장식
                Circle()
                    .fill(BRColors.primaryDim)
                    .frame(width: 200, height: 200)
                    .offset(x: 150, y: -180)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                Blob2()
                    .fill(BRColors.surfaceHigh.opacity(0.4))
                    .frame(width: 160, height: 160)
                    .offset(x: -120, y: 440)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // 헤더
                        VStack(spacing: 6) {
                            // 선택된 이모지 큰 프리뷰
                            ZStack {
                                Circle()
                                    .fill(BRColors.primaryDim)
                                    .frame(width: 90, height: 90)
                                Text(selectedEmoji)
                                    .font(.system(size: 46))
                            }
                            .padding(.top, 32)

                            Text(nickname.isEmpty ? Localization.Profile.noNickname : nickname)
                                .font(Paperlogy.black(20))
                                .foregroundStyle(BRColors.onSurface)
                                .padding(.top, 8)


                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 32)

                        VStack(spacing: 24) {
                            // 닉네임
                            profileSection(title: Localization.Profile.displayName) {
                                TextField(Localization.Profile.displayNamePlaceholder, text: $nickname)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(BRColors.onSurface)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                    .background(BRColors.surfaceLow)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))

                                if let email = authViewModel.currentMember?.email, !email.isEmpty {
                                    HStack(spacing: 5) {
                                        Image(systemName: "person.circle")
                                            .font(.system(size: 11))
                                        Text(email)
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundStyle(BRColors.onSurfaceMuted.opacity(0.6))
                                    .padding(.horizontal, 4)
                                }
                            }

                            // 이모지 선택
                            profileSection(title: Localization.Profile.profileEmoji) {
                                VStack(spacing: 8) {
                                    ForEach(emojiGrid, id: \.self) { row in
                                        HStack(spacing: 6) {
                                            ForEach(row, id: \.self) { emoji in
                                                Button {
                                                    withAnimation(.spring(duration: 0.15)) {
                                                        selectedEmoji = emoji
                                                    }
                                                } label: {
                                                    Text(emoji)
                                                        .font(.system(size: 26))
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 44)
                                                        .background(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .fill(selectedEmoji == emoji
                                                                      ? BRColors.primaryDim
                                                                      : Color.clear)
                                                        )
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .strokeBorder(
                                                                    selectedEmoji == emoji
                                                                        ? BRColors.primary
                                                                        : Color.clear,
                                                                    lineWidth: 2
                                                                )
                                                        )
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(12)
                                .background(BRColors.surfaceLow)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }

                            // 저장 버튼
                            Button {
                                Task {
                                    isSaving = true
                                    await authViewModel.updateProfile(nickname: nickname, emoji: selectedEmoji)
                                    isSaving = false
                                    dismiss()
                                }
                            } label: {
                                Group {
                                    if isSaving {
                                        ProgressView().tint(.white)
                                    } else {
                                        Text(Localization.Profile.save)
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(
                                    nickname.isEmpty
                                        ? AnyShapeStyle(BRColors.surfaceContainer)
                                        : AnyShapeStyle(BRColors.primaryGradient)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 48))
                                .shadow(
                                    color: nickname.isEmpty ? .clear : BRColors.primary.opacity(0.3),
                                    radius: 16, y: 5
                                )
                            }
                            .disabled(nickname.isEmpty || isSaving)

                            // 로그아웃
                            Button(role: .destructive) {
                                showLogoutConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text(Localization.Profile.logout)
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundStyle(BRColors.tertiary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(BRColors.tertiary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 48))
                            }

                            // 계정 삭제
                            Button(role: .destructive) {
                                showDeleteConfirm = true
                            } label: {
                                Text(Localization.Profile.deleteAccount)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(BRColors.tertiary.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.Profile.close) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
            .alert(Localization.Profile.logoutConfirm, isPresented: $showLogoutConfirm) {
                Button(Localization.Profile.logout, role: .destructive) {
                    authViewModel.signOut()
                    dismiss()
                }
                Button(Localization.Profile.cancel, role: .cancel) {}
            }
            .alert(Localization.Profile.deleteAccountConfirm, isPresented: $showDeleteConfirm) {
                Button(Localization.Profile.deleteAccount, role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                        dismiss()
                    }
                }
                Button(Localization.Profile.cancel, role: .cancel) {}
            } message: {
                Text(Localization.Profile.deleteAccountMessage)
            }
        }
        .onAppear {
            nickname = authViewModel.currentMember?.displayName ?? ""
            selectedEmoji = authViewModel.currentMember?.profileEmoji ?? "😀"
        }
    }

    @ViewBuilder
    private func profileSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BRColors.onSurfaceMuted)
                .tracking(0.5)
            content()
        }
    }
}
