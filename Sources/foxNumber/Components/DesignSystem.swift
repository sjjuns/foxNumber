import SwiftUI

enum DesignSystem {
    // MARK: - Semantic Colors (Assets.xcassets ColorSet — light/dark adaptive)
    static let background      = Color("AppBackground")
    static let cardBackground  = Color("CardBackground")
    static let groupBackground = Color("GroupBackground")

    static let textPrimary     = Color("TextPrimary")
    static let textSecondary   = Color("TextSecondary")
    static let textTertiary    = Color("TextTertiary")

    static let accent          = Color("Accent")
    static let gold            = Color("Gold")
    static let divider         = Color("Divider")

    // MARK: - Lotto Ball Colors (fixed — matches real lotto)
    static func ballColor(for number: Int) -> Color {
        switch number {
        case 1...10:  return Color(hex: "#F5C518")
        case 11...20: return Color(hex: "#3B82F6")
        case 21...30: return Color(hex: "#E63946")
        case 31...40: return Color(hex: "#6B7280")
        default:      return Color(hex: "#10B981")
        }
    }

    // MARK: - Typography
    enum Typography {
        static let largeTitle: Font = .system(size: 34, weight: .bold,    design: .rounded)
        static let title: Font      = .system(size: 22, weight: .semibold, design: .rounded)
        static let headline: Font   = .system(size: 17, weight: .semibold)
        static let body: Font       = .system(size: 15, weight: .regular)
        static let caption: Font    = .system(size: 13, weight: .regular)
        static let micro: Font      = .system(size: 11, weight: .medium)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat =  4
        static let sm: CGFloat =  8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
