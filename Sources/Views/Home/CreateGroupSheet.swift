import SwiftUI

struct CreateGroupSheet: View {
    @ObservedObject var groupVM: GroupViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("빙고 이름")
                        .font(BRTypography.cellTitle)
                        .foregroundStyle(.secondary)
                    TextField("예: 우리팀 2026 버킷리스트", text: $groupName)
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
                    Task { await create() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("만들기")
                                .font(BRTypography.cellTitle)
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(groupName.isEmpty ? BRColors.lightGray : BRColors.cobaltBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(groupName.isEmpty || isLoading)
            }
            .padding(24)
            .navigationTitle("새 빙고 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }

    private func create() async {
        guard let id = authViewModel.currentMember?.id else { return }
        isLoading = true
        do {
            try await groupVM.createGroup(name: groupName, leaderID: id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
