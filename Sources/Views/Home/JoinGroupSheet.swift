import SwiftUI
import FirebaseAuth

struct JoinGroupSheet: View {
    let onJoined: () -> Void
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var memberID: String {
        authViewModel.currentMember?.id ?? Auth.auth().currentUser?.uid ?? ""
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()
                    .allowsHitTesting(false)

                // 기하학적 배경 장식
                Blob1()
                    .fill(BRColors.secondaryChip.opacity(0.4))
                    .frame(width: 180, height: 180)
                    .offset(x: 140, y: -160)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                Circle()
                    .fill(BRColors.primaryDim)
                    .frame(width: 120, height: 120)
                    .offset(x: -90, y: 380)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    // 헤더
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(BRColors.secondaryChip)
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(BRColors.secondary)
                            }
                            Text("초대 코드로 참여")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(BRColors.onSurfaceMuted)
                        }

                        Text("초대 코드를\n입력하세요")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(BRColors.onSurface)
                            .tracking(-0.5)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 36)

                    // 입력 필드
                    VStack(alignment: .leading, spacing: 10) {
                        Text("초대 코드 6자리")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                            .tracking(0.5)

                        TextField("예: AB12CD", text: $inviteCode)
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(BRColors.onSurface)
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.characters)
                            .tracking(4)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                            .background(BRColors.surfaceLow)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(BRColors.tertiary)
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }

                    Spacer()

                    // 참여하기 버튼
                    Button {
                        Task { await join() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("참여하기")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            inviteCode.count < 6
                                ? AnyShapeStyle(BRColors.surfaceContainer)
                                : AnyShapeStyle(BRColors.primaryGradient)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 48))
                        .shadow(
                            color: inviteCode.count < 6 ? .clear : BRColors.primary.opacity(0.3),
                            radius: 16, y: 5
                        )
                    }
                    .disabled(inviteCode.count < 6 || isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
        }
    }

    private func join() async {
        guard !memberID.isEmpty else { return }
        isLoading = true
        do {
            guard var group = try await FirestoreService.shared.fetchGroup(byInviteCode: inviteCode) else {
                errorMessage = Localization.isEnglish ? "Invite code not found." : "초대 코드를 찾을 수 없어요."
                isLoading = false
                return
            }
            if group.memberIDs.count >= 10 {
                errorMessage = Localization.isEnglish ? "This room is full (max 10 members)." : "방이 꽉 찼어요. (최대 10명)"
                isLoading = false
                return
            }
            if !group.memberIDs.contains(memberID) {
                group.memberIDs.append(memberID)
                try await FirestoreService.shared.createGroup(group)
            }
            onJoined()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
