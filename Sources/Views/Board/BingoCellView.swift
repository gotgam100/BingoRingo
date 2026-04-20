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
        if isCompletedByMe  { return BRColors.red.opacity(0.15) }
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
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor, lineWidth: isCompletedByMe || isFullyCompleted ? 2 : 1)

            VStack(spacing: 2) {
                // 미션 텍스트
                Text(cell.title)
                    .font(.system(size: max(size * 0.12, 8), weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 3)
                    .padding(.top, 4)

                Spacer(minLength: 0)

                // 멤버 완료 상태 점
                memberDots
                    .padding(.bottom, 4)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: isFullyCompleted ? BRColors.blue.opacity(0.3) : .black.opacity(0.05), radius: 3, y: 1)
        .animation(.spring(duration: 0.25), value: cell.completedBy.count)
    }

    private var memberDots: some View {
        HStack(spacing: 2) {
            ForEach(Array(memberIDs.enumerated()), id: \.element) { idx, memberID in
                let done = cell.completedBy.contains(memberID)
                let color = memberColors[idx % memberColors.count]
                let dotSize = max(size * 0.1, 5.0)

                Circle()
                    .fill(done ? color : BRColors.lightGray)
                    .frame(width: dotSize, height: dotSize)
                    .overlay(
                        Circle().strokeBorder(done ? color : BRColors.secondary.opacity(0.3), lineWidth: 0.5)
                    )
                    .scaleEffect(done ? 1.1 : 1.0)
                    .animation(.spring(duration: 0.2), value: done)
            }
        }
    }
}
