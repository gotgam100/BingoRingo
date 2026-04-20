import SwiftUI

enum BRColors {
    static let background  = Color(hex: "#F7F0E3")   // 따뜻한 크림
    static let primary     = Color(hex: "#1A1512")   // 거의 검정 (밝은 배경 텍스트)
    static let secondary   = Color(hex: "#6B5B4E")   // 브라운 그레이

    static let red         = Color(hex: "#E84A2F")   // 웜 레드-오렌지
    static let blue        = Color(hex: "#2B5BA8")   // 레트로 블루
    static let yellow      = Color(hex: "#F5A623")   // 웜 옐로
    static let green       = Color(hex: "#2D6A4F")   // 딥 그린
    static let lightGray   = Color(hex: "#E8DFD0")   // 웜 라이트
    static let cream       = Color(hex: "#FBF6ED")   // 밝은 크림 (카드)

    // 레거시 alias
    static var cobaltBlue: Color { blue }
    static var orange: Color { red }
    static var beige: Color { yellow }
    static var darkText: Color { primary }
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
