import SwiftUI

struct JoinGroupSheet: View {
    @ObservedObject var groupVM: GroupViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("초대 코드")
                        .font(BRTypography.cellTitle)
                        .foregroundStyle(.secondary)
                    TextField("6자리 코드 입력", text: $inviteCode)
                        .textInputAutocapitalization(.characters)
                        .padding()
                        .background(BRColors.lightGray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let error = errorMessage {
                    Text(error)
                        .font(BRTypography.caption)
                        .foregroundStyle(BRColors.red)
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
                                .font(BRTypography.cellTitle)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(inviteCode.count < 6 ? BRColors.lightGray : BRColors.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(inviteCode.count < 6 || isLoading)
            }
            .padding(24)
            .navigationTitle("초대 코드로 참여")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }

    private func join() async {
        guard let id = authViewModel.currentMember?.id else { return }
        isLoading = true
        do {
            try await groupVM.joinGroup(inviteCode: inviteCode, memberID: id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
