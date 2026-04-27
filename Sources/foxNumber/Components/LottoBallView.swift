import SwiftUI

struct LottoBallView: View {
    let number: Int
    var size: CGFloat = 48
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            ballColor.opacity(0.9),
                            ballColor
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .frame(width: size, height: size)
                .shadow(
                    color: isHighlighted ? DesignSystem.gold.opacity(0.8) : ballColor.opacity(0.4),
                    radius: isHighlighted ? 12 : 6
                )
                .overlay(
                    Circle()
                        .stroke(
                            isHighlighted ? DesignSystem.gold : Color.white.opacity(0.2),
                            lineWidth: isHighlighted ? 2 : 1
                        )
                )

            Text("\(number)")
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var ballColor: Color {
        DesignSystem.ballColor(for: number)
    }
}

// MARK: - Empty Ball (생성 전 자리 표시)
struct EmptyBallView: View {
    var size: CGFloat = 48

    var body: some View {
        Circle()
            .fill(DesignSystem.cardBackground)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(DesignSystem.textSecondary.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    HStack(spacing: 8) {
        ForEach([3, 15, 27, 31, 38, 45], id: \.self) { n in
            LottoBallView(number: n)
        }
    }
    .padding()
    .background(DesignSystem.background)
}
