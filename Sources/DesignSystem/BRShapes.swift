import SwiftUI

// 온보딩 배경 - 레트로 블루 + 유기적 blob
struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            BRColors.blue.ignoresSafeArea()

            // 상단 우 blob
            Blob1()
                .fill(BRColors.red.opacity(0.85))
                .frame(width: 260, height: 260)
                .offset(x: 140, y: -220)

            // 하단 좌 blob
            Blob2()
                .fill(BRColors.yellow.opacity(0.7))
                .frame(width: 200, height: 200)
                .offset(x: -140, y: 300)

            // 중앙 작은 원
            Circle()
                .fill(BRColors.green.opacity(0.6))
                .frame(width: 80, height: 80)
                .offset(x: -120, y: -100)

            // 하단 우 원
            Circle()
                .fill(BRColors.red.opacity(0.4))
                .frame(width: 120, height: 120)
                .offset(x: 150, y: 360)

            // 작은 점
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 20, height: 20)
                .offset(x: 60, y: 140)

            Circle()
                .fill(BRColors.yellow.opacity(0.5))
                .frame(width: 14, height: 14)
                .offset(x: -50, y: 200)
        }
    }
}

// Blob 형태들
struct Blob1: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.width * 0.5, y: 0))
            p.addCurve(
                to: CGPoint(x: rect.width, y: rect.height * 0.4),
                control1: CGPoint(x: rect.width * 0.9, y: 0),
                control2: CGPoint(x: rect.width, y: rect.height * 0.2)
            )
            p.addCurve(
                to: CGPoint(x: rect.width * 0.6, y: rect.height),
                control1: CGPoint(x: rect.width, y: rect.height * 0.7),
                control2: CGPoint(x: rect.width * 0.8, y: rect.height)
            )
            p.addCurve(
                to: CGPoint(x: 0, y: rect.height * 0.5),
                control1: CGPoint(x: rect.width * 0.3, y: rect.height),
                control2: CGPoint(x: 0, y: rect.height * 0.8)
            )
            p.addCurve(
                to: CGPoint(x: rect.width * 0.5, y: 0),
                control1: CGPoint(x: 0, y: rect.height * 0.2),
                control2: CGPoint(x: rect.width * 0.2, y: 0)
            )
        }
    }
}

struct Blob2: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.width * 0.3, y: 0))
            p.addCurve(
                to: CGPoint(x: rect.width, y: rect.height * 0.3),
                control1: CGPoint(x: rect.width * 0.8, y: -rect.height * 0.1),
                control2: CGPoint(x: rect.width, y: rect.height * 0.1)
            )
            p.addCurve(
                to: CGPoint(x: rect.width * 0.7, y: rect.height),
                control1: CGPoint(x: rect.width * 1.1, y: rect.height * 0.6),
                control2: CGPoint(x: rect.width * 0.9, y: rect.height)
            )
            p.addCurve(
                to: CGPoint(x: 0, y: rect.height * 0.6),
                control1: CGPoint(x: rect.width * 0.4, y: rect.height * 1.1),
                control2: CGPoint(x: 0, y: rect.height * 0.9)
            )
            p.addCurve(
                to: CGPoint(x: rect.width * 0.3, y: 0),
                control1: CGPoint(x: 0, y: rect.height * 0.2),
                control2: CGPoint(x: rect.width * 0.1, y: 0)
            )
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
