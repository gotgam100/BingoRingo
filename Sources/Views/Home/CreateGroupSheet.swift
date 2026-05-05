import SwiftUI
import FirebaseAuth

struct CreateGroupSheet: View {
    let onCreated: () -> Void
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var groupViewModel: GroupViewModel
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var selectedSize = 3
    @State private var inviteCode = String(UUID().uuidString.prefix(6).uppercased())
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var codeCopied = false

    private var memberID: String {
        authViewModel.currentMember?.id ?? Auth.auth().currentUser?.uid ?? ""
    }

    private var sizes: [(Int, String, String)] {
        [
            (3, "3×3", Localization.CreateGroup.sizeFast),
            (4, "4×4", Localization.CreateGroup.sizeClassic),
        ]
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
                        // 헤더
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(BRColors.primaryDim)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "plus.square.fill")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(BRColors.primary)
                                }
                                Text(Localization.CreateGroup.title)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                            }
                            Text(Localization.CreateGroup.subtitle)
                                .font(Paperlogy.black(28))
                                .foregroundStyle(BRColors.onSurface)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 32)

                        VStack(spacing: 24) {
                            // 빙고 이름
                            fieldSection(title: Localization.CreateGroup.bingoName) {
                                TextField(Localization.CreateGroup.bingoNamePlaceholder, text: $groupName)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundStyle(BRColors.onSurface)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 16)
                                    .background(BRColors.surfaceLow)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            // 빙고 크기 선택
                            fieldSection(title: Localization.CreateGroup.gridSize) {
                                HStack(spacing: 10) {
                                    ForEach(sizes, id: \.0) { size, label, desc in
                                        SizeCard(
                                            size: size,
                                            label: label,
                                            desc: desc,
                                            isSelected: selectedSize == size
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(duration: 0.2)) {
                                                selectedSize = size
                                            }
                                        }
                                    }
                                }
                            }

                            // 초대 코드
                            fieldSection(title: Localization.CreateGroup.inviteCode) {
                                HStack {
                                    Text(inviteCode)
                                        .font(Paperlogy.black(24))
                                        .foregroundStyle(BRColors.primary)
                                        .tracking(4)

                                    Spacer()

                                    Button {
                                        UIPasteboard.general.string = inviteCode
                                        withAnimation { codeCopied = true }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                            withAnimation { codeCopied = false }
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                                .font(.system(size: 13, weight: .bold))
                                            Text(codeCopied ? Localization.CreateGroup.copied : Localization.CreateGroup.copy)
                                                .font(.system(size: 13, weight: .bold))
                                        }
                                        .foregroundStyle(codeCopied ? BRColors.onSurfaceMuted : BRColors.primary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(codeCopied ? BRColors.surfaceContainer : BRColors.primaryDim)
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 14)
                                .background(BRColors.surfaceLow)
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                                Text(Localization.CreateGroup.shareCode)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(BRColors.onSurfaceMuted)
                                    .padding(.top, 4)
                            }
                        }
                        .padding(.horizontal, 24)

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(BRColors.tertiary)
                                .padding(.horizontal, 24)
                                .padding(.top, 12)
                        }

                        // 만들기 버튼
                        Button {
                            Task { await create() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(Localization.CreateGroup.create)
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
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.CreateGroup.cancel) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
        }
    }

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

    private func create() async {
        guard !memberID.isEmpty else { return }

        isLoading = true
        do {
            let group = BingoGroup(
                name: groupName,
                inviteCode: inviteCode,
                memberIDs: [memberID],
                leaderID: memberID,
                boardSize: selectedSize
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

// MARK: - 크기 선택 카드
struct SizeCard: View {
    let size: Int
    let label: String
    let desc: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 10) {
            // 미니 그리드 프리뷰
            VStack(spacing: 3) {
                ForEach(0..<size, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<size, id: \.self) { col in
                            let isCenter = row == size / 2 && col == size / 2
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isCenter
                                      ? BRColors.primary
                                      : (isSelected ? BRColors.primaryMid : BRColors.surfaceContainer))
                                .frame(
                                    width: cellDim,
                                    height: cellDim
                                )
                        }
                    }
                }
            }

            // 라벨
            VStack(spacing: 2) {
                Text(label)
                    .font(Paperlogy.black(15))
                    .foregroundStyle(isSelected ? BRColors.primary : BRColors.onSurface)
                Text(desc)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isSelected ? BRColors.primary : BRColors.onSurfaceMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(isSelected ? BRColors.primaryDim : BRColors.surfaceLow)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isSelected ? BRColors.primary : Color.clear,
                            lineWidth: 2
                        )
                )
        )
        .animation(.spring(duration: 0.2), value: isSelected)
    }

    // 크기에 따라 셀 크기 자동 조절
    private var cellDim: CGFloat {
        switch size {
        case 3: return 10
        case 4: return 8
        default: return 6
        }
    }
}
