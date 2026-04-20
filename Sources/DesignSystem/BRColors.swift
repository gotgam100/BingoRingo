import SwiftUI

enum BRColors {
    static let cobaltBlue   = Color(hex: "#3B3FCB")
    static let orange       = Color(hex: "#F26522")
    static let red          = Color(hex: "#D7263D")
    static let beige        = Color(hex: "#D4A96A")
    static let lightGray    = Color(hex: "#E8E8E4")
    static let background   = Color(hex: "#F5F3EE")
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
