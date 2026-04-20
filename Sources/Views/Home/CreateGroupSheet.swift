import SwiftUI
import FirebaseAuth

struct CreateGroupSheet: View {
    let onCreated: () -> Void
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
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
                            .fill(BRColors.cobaltBlue)
                            .frame(height: 100)
                        HStack {
                            Triangle()
                                .fill(BRColors.orange.opacity(0.7))
                                .frame(width: 50, height: 50)
                                .offset(x: -10)
                            Spacer()
                            Circle()
                                .fill(BRColors.red.opacity(0.6))
                                .frame(width: 60, height: 60)
                                .offset(x: 10)
                        }
                        .padding(.horizontal)

                        Text("새 빙고 만들기")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("빙고 이름")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                        TextField("예: 우리팀 2026 버킷리스트", text: $groupName)
                            .font(.system(size: 16, design: .rounded))
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
                        Task { await create() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("만들기")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(groupName.isEmpty ? BRColors.lightGray : BRColors.cobaltBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(groupName.isEmpty || isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
                .padding(.top, 24)
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            .navigationBarHidden(false)
        }
    }

    private func create() async {
        guard !memberID.isEmpty else { return }
        isLoading = true
        do {
            let code = String(UUID().uuidString.prefix(6).uppercased())
            let group = BingoGroup(
                name: groupName,
                inviteCode: code,
                memberIDs: [memberID],
                leaderID: memberID
            )
            try await FirestoreService.shared.createGroup(group)
            onCreated()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
