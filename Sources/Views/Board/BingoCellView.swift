import SwiftUI

struct BingoCellView: View {
    let cell: BingoCell
    let memberIDs: [String]
    let currentMemberID: String
    let isLeader: Bool
    let size: CGFloat
    let onTap: () -> Void
    let onEdit: () -> Void
    let onToggle: () -> Void

    private let memberColors: [Color] = [BRColors.blue, BRColors.red, BRColors.green, BRColors.yellow]

    private var isCompletedByMe: Bool { cell.completedBy.contains(currentMemberID) }
    private var isFullyCompleted: Bool { cell.isCompleted(for: memberIDs) }
    private var completedCount: Int { cell.completedBy.count }
    private var totalCount: Int { memberIDs.count }
    private var ratio: CGFloat { totalCount > 0 ? CGFloat(completedCount) / CGFloat(totalCount) : 0 }

    private var bgColor: Color {
        if isFullyCompleted { return BRColors.blue }
        if isCompletedByMe  { return BRColors.red.opacity(0.1) }
        return BRColors.cream
    }

    private var borderColor: Color {
        if isFullyCompleted { return BRColors.blue }
        if isCompletedByMe  { return BRColors.red }
        return BRColors.lightGray
    }

    private var textColor: Color {
        isFullyCompleted ? .white : BRColors.primary
    }

    private var arcColor: Color {
        if isFullyCompleted { return BRColors.yellow }
        if isCompletedByMe  { return BRColors.red }
        return BRColors.blue
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: isCompletedByMe || isFullyCompleted ? 2 : 1)

            // 미션 텍스트
            Text(cell.title)
                .font(.system(size: max(size * 0.17, 10), weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.45)
                .padding(.horizontal, size * 0.07)
                .padding(.vertical, size * 0.22)

            // 우상단 아크 진행 표시
            arcIndicator
                .frame(width: size * 0.38, height: size * 0.38)
                .offset(x: size * 0.28, y: -size * 0.28)
        }
        .frame(width: size, height: size)
        .shadow(color: isFullyCompleted ? BRColors.blue.opacity(0.3) : .black.opacity(0.05), radius: 3, y: 1)
        .animation(.spring(duration: 0.25), value: completedCount)
        .onTapGesture { onTap() }
        .contextMenu {
            Button {
                onToggle()
            } label: {
                Label(isCompletedByMe ? "완료 취소" : "완료 체크", systemImage: isCompletedByMe ? "xmark.circle" : "checkmark.circle.fill")
            }
            if isLeader {
                Button {
                    onEdit()
                } label: {
                    Label("제목 수정", systemImage: "pencil")
                }
            }
        }
    }

    private var arcIndicator: some View {
        ZStack {
            // 배경 트랙
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: size * 0.045)

            // 진행 아크
            Circle()
                .trim(from: 0, to: ratio)
                .stroke(arcColor, style: StrokeStyle(lineWidth: size * 0.045, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.4), value: ratio)

            // 텍스트
            Text("\(completedCount)/\(totalCount)")
                .font(.system(size: max(size * 0.1, 7), weight: .black, design: .rounded))
                .foregroundStyle(isFullyCompleted ? .white : BRColors.primary)
                .minimumScaleFactor(0.5)
        }
    }
}
