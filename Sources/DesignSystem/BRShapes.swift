import SwiftUI

// 온보딩 배경 — 따뜻한 Canvas Tan + 기하학적 블롭
struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            BRColors.surface.ignoresSafeArea()

            // 상단 우: 큰 블루 원
            Circle()
                .fill(BRColors.primary.opacity(0.12))
                .frame(width: 320, height: 320)
                .offset(x: 160, y: -200)

            // 상단 좌: 중간 오렌지 블롭
            Blob1()
                .fill(BRColors.secondaryChip.opacity(0.55))
                .frame(width: 180, height: 180)
                .offset(x: -120, y: -260)

            // 하단 좌: 큰 블루 블롭
            Blob2()
                .fill(BRColors.primaryDim)
                .frame(width: 260, height: 260)
                .offset(x: -140, y: 320)

            // 하단 우: 작은 오렌지 원
            Circle()
                .fill(BRColors.surfaceHigh.opacity(0.8))
                .frame(width: 110, height: 110)
                .offset(x: 150, y: 380)

            // 중앙 작은 점들
            Circle()
                .fill(BRColors.primary.opacity(0.18))
                .frame(width: 28, height: 28)
                .offset(x: 100, y: 120)

            Circle()
                .fill(BRColors.secondaryChip.opacity(0.6))
                .frame(width: 16, height: 16)
                .offset(x: -60, y: 180)
        }
    }
}

// 유기적 블롭 형태 1
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

// 유기적 블롭 형태 2
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
