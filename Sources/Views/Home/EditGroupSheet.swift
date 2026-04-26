import SwiftUI
import FirebaseAuth

struct EditGroupSheet: View {
    let group: BingoGroup
    let memberID: String
    let onChanged: () -> Void

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var groupName: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false
    @State private var showLeaveConfirm = false

    private var isLeader: Bool { group.leaderID == memberID }

    init(group: BingoGroup, memberID: String, onChanged: @escaping () -> Void) {
        self.group = group
        self.memberID = memberID
        self.onChanged = onChanged
        _groupName = State(initialValue: group.name)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()
                    .allowsHitTesting(false)

                Circle()
                    .fill(BRColors.primaryDim)
                    .frame(width: 220, height: 220)
                    .offset(x: 160, y: -180)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                Circle()
                    .fill(BRColors.surfaceHigh.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .offset(x: -80, y: 500)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headerSection
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                            .padding(.bottom, 32)

                        VStack(spacing: 24) {
                            nameSection

                            if let error = errorMessage {
                                Text(error)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(BRColors.tertiary)
                            }
                        }
                        .padding(.horizontal, 24)

                        actionButtons
                            .padding(.horizontal, 24)
                            .padding(.top, 32)
                            .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.Settings.close) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
            .alert(Localization.EditGroup.deleteBingoTitle, isPresented: $showDeleteConfirm) {
                Button(Localization.EditGroup.deleteButtonText, role: .destructive) {
                    Task {
                        try? await FirestoreService.shared.deleteGroup(groupID: group.id)
                        onChanged()
                        dismiss()
                    }
                }
                Button(Localization.EditGroup.cancel, role: .cancel) {}
            } message: {
                Text(Localization.EditGroup.deleteMessage)
            }
            .alert(Localization.EditGroup.leaveBingoTitle, isPresented: $showLeaveConfirm) {
                Button(Localization.EditGroup.leaveButtonText, role: .destructive) {
                    Task {
                        try? await FirestoreService.shared.leaveGroup(groupID: group.id, memberID: memberID)
                        onChanged()
                        dismiss()
                    }
                }
                Button(Localization.EditGroup.cancel, role: .cancel) {}
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(BRColors.primaryDim)
                        .frame(width: 36, height: 36)
                    Image(systemName: isLeader ? "pencil.and.list.clipboard" : "info.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(BRColors.primary)
                }
                Text(Localization.EditGroup.editMyBingo)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(BRColors.onSurfaceMuted)
            }
            if !isLeader {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(Localization.EditGroup.onlyLeaderCanEdit)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(BRColors.onSurfaceMuted)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nameSection: some View {
        fieldSection(title: Localization.EditGroup.bingoName) {
            if isLeader {
                TextField(Localization.EditGroup.bingoNamePlaceholder, text: $groupName)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(BRColors.onSurface)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(BRColors.surfaceLow)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            } else {
                Text(group.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(BRColors.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(BRColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }


    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if isLeader {
                Button {
                    Task { await save() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(Localization.EditGroup.editComplete)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        groupName.isEmpty
                            ? AnyShapeStyle(BRColors.surfaceContainer)
                            : AnyShapeStyle(BRColors.primaryGradient)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 48))
                    .shadow(
                        color: groupName.isEmpty ? .clear : BRColors.primary.opacity(0.3),
                        radius: 16, y: 5
                    )
                }
                .disabled(groupName.isEmpty || isLoading)

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                        Text(Localization.EditGroup.deleteBingo)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(BRColors.tertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(BRColors.tertiary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 48))
                }
            } else {
                Button(role: .destructive) {
                    showLeaveConfirm = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                        Text(Localization.EditGroup.leaveBingo)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(BRColors.tertiary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(BRColors.tertiary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 48))
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func fieldSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(BRColors.onSurfaceMuted)
                .tracking(0.5)
            content()
        }
    }

    private func save() async {
        isLoading = true
        var updated = group
        updated.name = groupName.trimmingCharacters(in: .whitespaces)
        do {
            try await FirestoreService.shared.updateGroupDetails(updated)
            onChanged()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
