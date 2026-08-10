import SwiftUI

enum RoostFont {
    static func regular(_ size: CGFloat) -> Font { .custom("Mirza-Regular", size: size) }
    static func medium(_ size: CGFloat) -> Font { .custom("Mirza-Medium", size: size) }
    static func semibold(_ size: CGFloat) -> Font { .custom("Mirza-SemiBold", size: size) }
    static func bold(_ size: CGFloat) -> Font { .custom("Mirza-Bold", size: size) }
}

enum RoostPalette {
    static let cream = Color(red: 0.99, green: 0.95, blue: 0.84)
    static let parchment = Color(red: 0.96, green: 0.89, blue: 0.72)
    static let barkDark = Color(red: 0.31, green: 0.19, blue: 0.10)
    static let bark = Color(red: 0.45, green: 0.28, blue: 0.14)
    static let leafGreen = Color(red: 0.36, green: 0.62, blue: 0.20)
    static let sunAmber = Color(red: 0.96, green: 0.70, blue: 0.24)
    static let skyBlue = Color(red: 0.42, green: 0.70, blue: 0.92)
    static let dusk = Color(red: 0.20, green: 0.13, blue: 0.08)
    static let ember = Color(red: 0.82, green: 0.24, blue: 0.16)
}

struct RoostShadowText: ViewModifier {
    var color: Color = RoostPalette.barkDark
    func body(content: Content) -> some View {
        content.shadow(color: color.opacity(0.55), radius: 1, x: 0, y: 1.5)
    }
}

extension View {
    func roostTextShadow(_ color: Color = RoostPalette.barkDark) -> some View {
        modifier(RoostShadowText(color: color))
    }
}
