import SwiftUI

// Paperlogy 폰트 — 브랜드 강조용 (앱 이름, 큰 숫자, 임팩트 헤드라인)
// 일반 UI 텍스트는 system font 그대로 사용
enum Paperlogy {
    static func black(_ size: CGFloat)     -> Font { .custom("Paperlogy-9Black",     size: size) }
    static func extraBold(_ size: CGFloat) -> Font { .custom("Paperlogy-8ExtraBold", size: size) }
    static func bold(_ size: CGFloat)      -> Font { .custom("Paperlogy-7Bold",      size: size) }
    static func semiBold(_ size: CGFloat)  -> Font { .custom("Paperlogy-6SemiBold",  size: size) }
    static func medium(_ size: CGFloat)    -> Font { .custom("Paperlogy-5Medium",    size: size) }
    static func regular(_ size: CGFloat)   -> Font { .custom("Paperlogy-4Regular",   size: size) }
}

// 레거시 alias
enum BRTypography {
    static let appTitle     = Font.system(size: 32, weight: .black, design: .rounded)
    static let sectionTitle = Font.system(size: 20, weight: .bold, design: .rounded)
    static let cellTitle    = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let caption      = Font.system(size: 12, weight: .regular, design: .rounded)
}
