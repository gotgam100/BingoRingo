import SwiftUI

// 온보딩 배경 - 다크 블루 + 기하학 도형
struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            BRColors.cobaltBlue.ignoresSafeArea()

            // 우상단 큰 원
            Circle()
                .fill(BRColors.orange.opacity(0.9))
                .frame(width: 220, height: 220)
                .offset(x: 130, y: -200)

            // 좌상단 삼각형
            Triangle()
                .fill(BRColors.red.opacity(0.7))
                .frame(width: 120, height: 120)
                .offset(x: -140, y: -260)

            // 중앙 좌 작은 사각형
            Rectangle()
                .fill(BRColors.beige.opacity(0.5))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(30))
                .offset(x: -150, y: 20)

            // 하단 우 원
            Circle()
                .fill(BRColors.red.opacity(0.4))
                .frame(width: 140, height: 140)
                .offset(x: 150, y: 320)

            // 하단 좌 큰 사각형
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(20))
                .offset(x: -120, y: 350)

            // 작은 다이아몬드
            Rectangle()
                .fill(BRColors.beige.opacity(0.6))
                .frame(width: 36, height: 36)
                .rotationEffect(.degrees(45))
                .offset(x: 60, y: 160)

            // 작은 원
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 50, height: 50)
                .offset(x: -60, y: 280)
        }
    }
}

// 홈 배경 - 라이트 + 상단 컬러 블록
struct HomeHeaderBackground: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            BRColors.background.ignoresSafeArea()

            // 상단 컬러 블록
            Rectangle()
                .fill(BRColors.cobaltBlue)
                .frame(height: 200)
                .ignoresSafeArea(edges: .top)

            // 장식 도형들
            Circle()
                .fill(BRColors.orange.opacity(0.8))
                .frame(width: 80, height: 80)
                .offset(x: UIScreen.main.bounds.width - 60, y: 20)

            Rectangle()
                .fill(BRColors.red.opacity(0.6))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(20))
                .offset(x: UIScreen.main.bounds.width - 120, y: 100)

            Triangle()
                .fill(BRColors.beige.opacity(0.7))
                .frame(width: 60, height: 60)
                .offset(x: 30, y: 80)
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
