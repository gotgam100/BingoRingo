import SwiftUI

struct BingoCellView: View {
    let cell: BingoCell
    let memberIDs: [String]
    let currentMemberID: String
    let isLeader: Bool
    let completedLineColor: Color?
    let size: CGFloat
    let onTap: () -> Void
    let onEdit: () -> Void
    let onToggle: () -> Void

    private var isCompletedByMe: Bool { cell.completedBy.contains(currentMemberID) }
    private var isFullyCompleted: Bool { cell.isCompleted(for: memberIDs) }
    private var completedCount: Int { cell.completedBy.count }
    private var totalCount: Int { memberIDs.count }
    private var ratio: CGFloat { totalCount > 0 ? CGFloat(completedCount) / CGFloat(totalCount) : 0 }
    private var friendCompletedNotMe: Bool { completedCount > 0 && !isCompletedByMe }

    private var bgColor: Color {
        if isFullyCompleted       { return completedLineColor ?? BRColors.primary }
        if friendCompletedNotMe   { return BRColors.primaryMid }
        if isCompletedByMe        { return BRColors.primaryDim }
        return Color(hex: "#FFF8F0")
    }

    private var textColor: Color {
        if isFullyCompleted     { return .white }
        if friendCompletedNotMe { return .white }
        return BRColors.onSurface
    }

    private var progressBarColor: Color {
        if isFullyCompleted     { return BRColors.surfaceHigh }
        if friendCompletedNotMe { return Color.white.opacity(0.6) }
        return BRColors.primaryMid
    }

    private var progressTrackColor: Color {
        if isFullyCompleted || friendCompletedNotMe {
            return Color.white.opacity(0.2)
        }
        return BRColors.primaryDim
    }

    var body: some View {
        ZStack {
            // 배경 (테두리 없음 — 색상으로 구분)
            RoundedRectangle(cornerRadius: 12)
                .fill(bgColor)

            VStack(spacing: 0) {
                Spacer()

                // 미션 텍스트 or 빈 셀 연필 아이콘
                if cell.title.isEmpty {
                    Image(systemName: "pencil")
                        .font(.system(size: max(size * 0.22, 11), weight: .medium))
                        .foregroundStyle(BRColors.onSurfaceMuted.opacity(0.35))
                } else {
                    Text(cell.title.count > 8 ? String(cell.title.prefix(8)) + "..." : cell.title)
                        .font(.system(size: max(size * 0.15, 9), weight: .bold, design: .rounded))
                        .foregroundStyle(textColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.4)
                        .padding(.horizontal, size * 0.08)
                }

                Spacer()

                // 하단 진행률 바
                VStack(spacing: 3) {
                    // 진행 바
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(progressTrackColor)
                                .frame(height: 3)
                            Capsule()
                                .fill(progressBarColor)
                                .frame(width: geo.size.width * ratio, height: 3)
                                .animation(.spring(duration: 0.4), value: ratio)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, size * 0.1)

                    // 완료 인원 텍스트
                    Text(Localization.isEnglish
                         ? "\(completedCount)/\(totalCount)"
                         : "\(completedCount)/\(totalCount)명")
                        .font(.system(size: max(size * 0.1, 7), weight: .black, design: .rounded))
                        .foregroundStyle(textColor.opacity(0.75))
                }
                .padding(.bottom, size * 0.1)
            }
            .padding(.top, size * 0.08)

        }
        .frame(width: size, height: size)
        .overlay(alignment: .topTrailing) {
            if isFullyCompleted {
                // 전원 완료: 진한 빨간 체크마크
                ZStack {
                    Circle()
                        .fill(BRColors.tertiary)
                        .frame(width: size * 0.24, height: size * 0.24)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.1, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: -size * 0.04, y: size * 0.04)
            } else if friendCompletedNotMe {
                // 친구 완료, 내가 미완료: 반투명 ghost 체크마크
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: size * 0.24, height: size * 0.24)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.1, weight: .bold))
                        .foregroundStyle(BRColors.primary.opacity(0.7))
                }
                .offset(x: -size * 0.04, y: size * 0.04)
            } else if isCompletedByMe {
                // 내가 완료, 친구 미완료: 매우 연한 체크마크
                ZStack {
                    Circle()
                        .fill(BRColors.primaryMid.opacity(0.25))
                        .frame(width: size * 0.24, height: size * 0.24)
                    Image(systemName: "checkmark")
                        .font(.system(size: size * 0.1, weight: .bold))
                        .foregroundStyle(BRColors.primary.opacity(0.35))
                }
                .offset(x: -size * 0.04, y: size * 0.04)
            }
        }
        .shadow(
            color: completedLineColor.map { $0.opacity(0.45) }
                ?? (isFullyCompleted ? BRColors.primary.opacity(0.25) : BRColors.onSurface.opacity(0.04)),
            radius: completedLineColor != nil ? 12 : (isFullyCompleted ? 8 : 3),
            y: 2
        )
        .animation(.spring(duration: 0.25), value: completedCount)
        .onTapGesture {
            if cell.title.isEmpty && isLeader {
                onEdit()
            } else {
                onTap()
            }
        }
        .contextMenu {
            if isLeader {
                Button {
                    onEdit()
                } label: {
                    Label(Localization.CellDetail.editMission, systemImage: "pencil")
                }
            }
            if !cell.title.isEmpty {
                Button {
                    onToggle()
                } label: {
                    Label(
                        isCompletedByMe ? Localization.CellDetail.cancelButton : Localization.CellDetail.checkButton,
                        systemImage: isCompletedByMe ? "xmark.circle" : "checkmark.circle.fill"
                    )
                }
            }
        }
    }
}
