import SwiftUI

struct GeometricBackground: View {
    var body: some View {
        ZStack {
            BRColors.background.ignoresSafeArea()

            // 좌상단 큰 원
            Circle()
                .fill(BRColors.cobaltBlue)
                .frame(width: 200, height: 200)
                .offset(x: -80, y: -120)

            // 우상단 삼각형
            Triangle()
                .fill(BRColors.orange)
                .frame(width: 140, height: 140)
                .offset(x: 130, y: -160)

            // 중앙 우측 사각형
            Rectangle()
                .fill(BRColors.red)
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(20))
                .offset(x: 150, y: 60)

            // 좌측 중단 작은 원
            Circle()
                .fill(BRColors.beige)
                .frame(width: 70, height: 70)
                .offset(x: -140, y: 80)

            // 하단 좌 큰 사각형
            Rectangle()
                .fill(BRColors.cobaltBlue.opacity(0.15))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(15))
                .offset(x: -100, y: 280)

            // 하단 우 원
            Circle()
                .fill(BRColors.orange.opacity(0.3))
                .frame(width: 120, height: 120)
                .offset(x: 140, y: 320)

            // 작은 다이아몬드
            Rectangle()
                .fill(BRColors.red.opacity(0.5))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(45))
                .offset(x: 60, y: 200)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
