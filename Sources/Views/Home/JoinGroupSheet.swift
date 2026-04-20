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
                BRColors.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    // 헤더 장식
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(BRColors.orange)
                            .frame(height: 100)
                        HStack {
                            Circle()
                                .fill(BRColors.red.opacity(0.6))
                                .frame(width: 60, height: 60)
                                .offset(x: -10)
                            Spacer()
                            Triangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .offset(x: 10)
                        }
                        .padding(.horizontal)

                        Text("초대 코드로 참여")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("초대 코드 6자리")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        TextField("예: AB12CD", text: $inviteCode)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.characters)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white)
                                    .shadow(color: .black.opacity(0.05), radius: 4)
                            )
                    }
                    .padding(.horizontal)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(BRColors.red)
                            .padding(.horizontal)
                    }

                    Spacer()

                    Button {
                        Task { await join() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("참여하기")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(inviteCode.count < 6 ? BRColors.lightGray : BRColors.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(inviteCode.count < 6 || isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding(.top, 24)
            }
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }

    private func join() async {
        guard !memberID.isEmpty else { return }
        isLoading = true
        do {
            guard var group = try await FirestoreService.shared.fetchGroup(byInviteCode: inviteCode) else {
                errorMessage = "초대 코드를 찾을 수 없어요."
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
