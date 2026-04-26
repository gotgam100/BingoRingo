import SwiftUI

struct CellDetailView: View {
    let cell: BingoCell
    let memberIDs: [String]
    let currentMemberID: String
    let boardID: String
    let cellIndex: Int
    let onToggle: () -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var boardVM: BoardViewModel

    init(cell: BingoCell, memberIDs: [String], currentMemberID: String, boardID: String, cellIndex: Int, boardVM: BoardViewModel, onToggle: @escaping () -> Void) {
        self.cell = cell
        self.memberIDs = memberIDs
        self.currentMemberID = currentMemberID
        self.boardID = boardID
        self.cellIndex = cellIndex
        self.onToggle = onToggle
        _boardVM = StateObject(wrappedValue: boardVM)
    }

    private var isCompletedByMe: Bool { cell.completedBy.contains(currentMemberID) }
    private var completedCount: Int { cell.completedBy.count }
    private var totalCount: Int { memberIDs.count }
    private var ratio: CGFloat { totalCount > 0 ? CGFloat(completedCount) / CGFloat(totalCount) : 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                BRColors.surface.ignoresSafeArea()

                Circle()
                    .fill(BRColors.primaryDim)
                    .frame(width: 200, height: 200)
                    .offset(x: 140, y: -200)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 진행률 원형
                    ZStack {
                        Circle()
                            .fill(BRColors.surfaceLow)
                            .frame(width: 130, height: 130)

                        Circle()
                            .stroke(BRColors.surfaceContainer, lineWidth: 10)
                            .frame(width: 110, height: 110)

                        Circle()
                            .trim(from: 0, to: ratio)
                            .stroke(BRColors.primaryGradient, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 110, height: 110)
                            .animation(.spring(duration: 0.5), value: ratio)

                        VStack(spacing: 2) {
                            Text("\(completedCount)/\(totalCount)")
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(BRColors.primary)
                            Text(Localization.Board.complete)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(BRColors.onSurfaceMuted)
                        }
                    }
                    .padding(.top, 40)

                    // 미션 제목
                    Text(cell.title)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(BRColors.onSurface)
                        .multilineTextAlignment(.center)
                        .tracking(-0.3)
                        .padding(.horizontal, 32)
                        .padding(.top, 24)

                    if !cell.description.isEmpty {
                        Text(cell.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(BRColors.onSurfaceMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                    }

                    // 완료한 멤버 목록
                    if !cell.completedBy.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(Localization.isEnglish ? "Completed by" : "완료한 멤버")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(BRColors.onSurfaceMuted)
                                .tracking(0.5)

                            ForEach(cell.completedBy, id: \.self) { memberID in
                                let profile = boardVM.memberProfiles[memberID]
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(BRColors.primaryDim)
                                            .frame(width: 44, height: 44)
                                        Text(profile?.profileEmoji ?? "😀")
                                            .font(.system(size: 24))
                                    }

                                    Text(profile?.displayName ?? (Localization.isEnglish ? "Unknown" : "알 수 없음"))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(BRColors.onSurface)

                                    if memberID == currentMemberID {
                                        Text(Localization.Home.me)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(BRColors.primary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(BRColors.primaryDim)
                                            .clipShape(Capsule())
                                    }

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(BRColors.primary)
                                        .font(.system(size: 18))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(BRColors.surfaceLow)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                    }

                    Spacer()

                    // 완료 토글 버튼
                    Button {
                        onToggle()
                        dismiss()
                    } label: {
                        Text(isCompletedByMe ? Localization.CellDetail.cancelButton : Localization.CellDetail.completeButton)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                isCompletedByMe
                                    ? AnyShapeStyle(BRColors.tertiary)
                                    : AnyShapeStyle(BRColors.primaryGradient)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 48))
                            .shadow(
                                color: isCompletedByMe
                                    ? BRColors.tertiary.opacity(0.3)
                                    : BRColors.primary.opacity(0.3),
                                radius: 16, y: 5
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(Localization.CellDetail.missionDetail)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.Settings.close) { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(BRColors.primary)
                }
            }
        }
    }
}
