import SwiftUI

struct BingoCellView: View {
    let cell: BingoCell
    let memberIDs: [String]
    let currentMemberID: String
    let size: CGFloat

    private var isCompletedByMe: Bool { cell.completedBy.contains(currentMemberID) }
    private var isFullyCompleted: Bool { cell.isCompleted(for: memberIDs) }
    private var ratio: Double { cell.completionRatio(for: memberIDs) }

    private var bgColor: Color {
        if isFullyCompleted { return BRColors.blue }
        if isCompletedByMe  { return BRColors.red }
        return BRColors.cream
    }

    private var textColor: Color {
        isFullyCompleted || isCompletedByMe ? .white : BRColors.primary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor)
                .shadow(color: .black.opacity(0.07), radius: 3, y: 1)

            // 부분 완료 채우기
            if !isFullyCompleted && ratio > 0 && !isCompletedByMe {
                GeometryReader { geo in
                    Rectangle()
                        .fill(BRColors.yellow.opacity(0.3))
                        .frame(height: geo.size.height * ratio)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(spacing: 3) {
                if isFullyCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size * 0.22))
                        .foregroundStyle(.white)
                }
                Text(cell.title)
                    .font(.system(size: max(size * 0.13, 9), weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(5)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(duration: 0.25), value: isCompletedByMe)
        .animation(.spring(duration: 0.25), value: isFullyCompleted)
    }
}
