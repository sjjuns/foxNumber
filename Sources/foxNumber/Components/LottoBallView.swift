import SwiftUI

struct LottoBallView: View {
    let number: Int
    var size: CGFloat = 48
    var isHighlighted: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .fill(ballColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: isHighlighted
                        ? DesignSystem.gold.opacity(0.6)
                        : (colorScheme == .dark ? ballColor.opacity(0.35) : Color.black.opacity(0.15)),
                    radius: isHighlighted ? 10 : 4,
                    y: isHighlighted ? 0 : 2
                )
                .overlay(
                    Circle()
                        .stroke(
                            isHighlighted ? DesignSystem.gold : Color.white.opacity(0.15),
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

// MARK: - Empty Ball
struct EmptyBallView: View {
    var size: CGFloat = 48

    var body: some View {
        Circle()
            .fill(DesignSystem.groupBackground)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(DesignSystem.divider, lineWidth: 1)
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
