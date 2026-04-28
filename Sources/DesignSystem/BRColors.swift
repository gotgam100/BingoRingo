import SwiftUI

enum BRColors {
    // Primary: 앱 아이콘 주황
    static let primary        = Color(hex: "#FF9500")
    static let primaryLight   = Color(hex: "#FFB84D")
    static let primaryDim     = Color(hex: "#FFF3E0")   // 연한 주황 (미완료 셀 배경)
    static let primaryMid     = Color(hex: "#FFD0A0")   // 중간 주황 (내가 완료한 셀)

    // Secondary: 파티클 노랑
    static let secondary      = Color(hex: "#E67E00")
    static let secondaryChip  = Color(hex: "#FFE680")

    // Tertiary: 핑크-레드 (완료 체크, 경고)
    static let tertiary       = Color(hex: "#C8184B")

    // Surface: 따뜻한 크림 배경
    static let surface          = Color(hex: "#FFFBF5")
    static let surfaceLow       = Color(hex: "#FFF5E8")
    static let surfaceContainer = Color(hex: "#FFE9CC")
    static let surfaceHigh      = Color(hex: "#FFD79C")

    // Text
    static let onSurface      = Color(hex: "#2D1A00")
    static let onSurfaceMuted = Color(hex: "#8B5E2A")
    static let outlineVariant = Color(hex: "#E0B07A")

    // 앱 아이콘 파티클 색상
    static let particlePink   = Color(hex: "#C8184B")
    static let particleCyan   = Color(hex: "#00B4D8")
    static let particleRed    = Color(hex: "#E64A19")
    static let particleYellow = Color(hex: "#FFD700")

    // 주황→노랑 Hero CTA 그라데이션
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#FF9500"), Color(hex: "#FFB84D")],
            startPoint: UnitPoint(x: 0.15, y: 0),
            endPoint: UnitPoint(x: 0.85, y: 1)
        )
    }

    // 배경용 그라데이션 (방장 카드 / 온보딩)
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#FF9500"), Color(hex: "#FFCC00")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // 멤버 카드 그라데이션 (시안)
    static var memberGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#00B4D8"), Color(hex: "#4FC3F7")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
