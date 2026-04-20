import SwiftUI

struct BingoCellView: View {
    let cell: BingoCell
    let memberIDs: [String]
    let currentMemberID: String
    let size: CGFloat

    private var isCompletedByMe: Bool {
        cell.completedBy.contains(currentMemberID)
    }

    private var isFullyCompleted: Bool {
        cell.isCompleted(for: memberIDs)
    }

    private var ratio: Double {
        cell.completionRatio(for: memberIDs)
    }

    private var bgColor: Color {
        if isFullyCompleted { return BRColors.cobaltBlue }
        if isCompletedByMe { return BRColors.orange }
        return .white
    }

    private var textColor: Color {
        if isFullyCompleted || isCompletedByMe { return .white }
        return .primary
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(bgColor)
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)

            // 부분 완료 오버레이
            if !isFullyCompleted && ratio > 0 {
                GeometryReader { geo in
                    Rectangle()
                        .fill(BRColors.orange.opacity(0.2))
                        .frame(height: geo.size.height * ratio)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(spacing: 4) {
                if isFullyCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size * 0.25))
                        .foregroundStyle(.white)
                }
                Text(cell.title)
                    .font(.system(size: max(size * 0.13, 9), weight: .semibold, design: .rounded))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .padding(4)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(duration: 0.3), value: isCompletedByMe)
        .animation(.spring(duration: 0.3), value: isFullyCompleted)
    }
}
