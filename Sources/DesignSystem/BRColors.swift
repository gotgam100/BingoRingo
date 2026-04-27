import SwiftUI

enum BRColors {
    // Action Blue (primary interactions, completed states)
    static let primary        = Color(hex: "#204bde")
    static let primaryLight   = Color(hex: "#859aff")
    static let primaryDim     = Color(hex: "#edf0ff")   // unselected cells
    static let primaryMid     = Color(hex: "#b8c4ff")   // in-progress cells

    // Social Orange-Brown (collaborative highlights)
    static let secondary      = Color(hex: "#9b3f00")
    static let secondaryChip  = Color(hex: "#ffc5aa")

    // High-stake Red (wins, checkmarks, urgent)
    static let tertiary       = Color(hex: "#b71211")

    // Surface hierarchy — warm Canvas Tan
    static let surface        = Color(hex: "#fff5eb")   // base canvas
    static let surfaceLow     = Color(hex: "#ffeeda")   // sub-sections
    static let surfaceContainer = Color(hex: "#ffe4c0") // interactive cards
    static let surfaceHigh    = Color(hex: "#ffd79c")   // floating elements

    // Text on surface
    static let onSurface      = Color(hex: "#3e2b0c")   // warm near-black
    static let onSurfaceMuted = Color(hex: "#9b7a52")   // muted warm brown
    static let outlineVariant = Color(hex: "#c6a97f")   // ghost border (15% opacity)

    // Hero CTA gradient: primary → primaryLight at 135°
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#204bde"), Color(hex: "#859aff")],
            startPoint: UnitPoint(x: 0.15, y: 0),
            endPoint: UnitPoint(x: 0.85, y: 1)
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
