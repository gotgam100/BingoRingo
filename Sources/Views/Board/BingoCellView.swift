import SwiftUI

struct BingoCellView: View {
    let cell: BingoCell
    let memberIDs: [String]
    let currentMemberID: String
    let size: CGFloat

    private let memberColors: [Color] = [BRColors.blue, BRColors.red, BRColors.green, BRColors.yellow]

    private var isCompletedByMe: Bool { cell.completedBy.contains(currentMemberID) }
    private var isFullyCompleted: Bool { cell.isCompleted(for: memberIDs) }

    private var bgColor: Color {
        if isFullyCompleted { return BRColors.blue }
        if isCompletedByMe  { return BRColors.red.opacity(0.12) }
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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: isCompletedByMe || isFullyCompleted ? 2 : 1)

            // 미션 텍스트 - 가득 채우기
            Text(cell.title)
                .font(.system(size: max(size * 0.17, 10), weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, size * 0.06)
                .padding(.vertical, size * 0.08)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 멤버 완료 점 - 우하단 코너
            memberDots
                .padding(3)
        }
        .frame(width: size, height: size)
        .shadow(color: isFullyCompleted ? BRColors.blue.opacity(0.3) : .black.opacity(0.05), radius: 3, y: 1)
        .animation(.spring(duration: 0.25), value: cell.completedBy.count)
    }

    private var memberDots: some View {
        HStack(spacing: 2) {
            ForEach(Array(memberIDs.enumerated()), id: \.element) { idx, id in
                let done = cell.completedBy.contains(id)
                let color = memberColors[idx % memberColors.count]
                let dotSize = max(size * 0.09, 5.0)

                Circle()
                    .fill(done ? color : Color.white.opacity(0.5))
                    .frame(width: dotSize, height: dotSize)
                    .overlay(Circle().strokeBorder(done ? color.opacity(0.3) : BRColors.lightGray, lineWidth: 0.5))
                    .scaleEffect(done ? 1.15 : 1.0)
                    .animation(.spring(duration: 0.2), value: done)
            }
        }
    }
}
