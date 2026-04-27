import SwiftUI

enum DesignSystem {
    // MARK: - Colors
    static let background     = Color(hex: "#0D0F1A")
    static let cardBackground = Color(hex: "#1A1D2E")
    static let gold           = Color(hex: "#F5C518")
    static let red            = Color(hex: "#E63946")
    static let textPrimary    = Color.white
    static let textSecondary  = Color(hex: "#8B8FA8")

    // MARK: - Ball Colors (실제 로또 색상)
    static func ballColor(for number: Int) -> Color {
        switch number {
        case 1...10:  return Color(hex: "#F5C518") // 노랑
        case 11...20: return Color(hex: "#3B82F6") // 파랑
        case 21...30: return Color(hex: "#E63946") // 빨강
        case 31...40: return Color(hex: "#6B7280") // 회색
        default:      return Color(hex: "#10B981") // 초록
        }
    }
}

// MARK: - Color Hex Extension
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
