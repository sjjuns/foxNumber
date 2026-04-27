import SwiftUI

struct WinningResultView: View {
    let item: LottoNumber
    let winning: WinningNumber
    let result: CheckResult

    @Environment(\.dismiss) private var dismiss
    @State private var animatedMatches: Set<Int> = []
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            DesignSystem.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // 상단 핸들
                Capsule()
                    .fill(DesignSystem.textSecondary.opacity(0.4))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 24) {
                        // 회차 헤더
                        roundHeader

                        Divider().background(DesignSystem.textSecondary.opacity(0.2))

                        // 당첨 번호
                        winningNumberSection

                        Divider().background(DesignSystem.textSecondary.opacity(0.2))

                        // 내 번호 + 결과
                        myNumberSection

                        // 등수 결과 카드
                        resultCard

                        // 확인 버튼
                        Button {
                            dismiss()
                        } label: {
                            Text("확인")
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(DesignSystem.gold)
                                .foregroundColor(DesignSystem.background)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }

            // 당첨 시 파티클 효과
            if showConfetti && result.rank != .none {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            animateMatches()
        }
    }

    // MARK: - 회차 헤더
    private var roundHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("제 \(winning.round)회 당첨 결과")
                    .font(.title3.bold())
                    .foregroundColor(DesignSystem.textPrimary)
                Text(winning.drawDate)
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            Spacer()
            Text(result.rank.emoji)
                .font(.system(size: 36))
        }
    }

    // MARK: - 당첨 번호 섹션
    private var winningNumberSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("당첨 번호")
                .font(.subheadline.bold())
                .foregroundColor(DesignSystem.textSecondary)

            HStack(spacing: 8) {
                ForEach(winning.numbers, id: \.self) { n in
                    LottoBallView(number: n, size: 44)
                }
                Text("+")
                    .font(.title3.bold())
                    .foregroundColor(DesignSystem.textSecondary)
                // 보너스 번호
                LottoBallView(number: winning.bonusNumber, size: 44)
                    .overlay(
                        Circle()
                            .stroke(DesignSystem.gold, lineWidth: 2)
                    )
            }

            // 보너스 안내
            HStack(spacing: 4) {
                Circle()
                    .stroke(DesignSystem.gold, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                Text("보너스 번호")
                    .font(.caption2)
                    .foregroundColor(DesignSystem.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 내 번호 섹션
    private var myNumberSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("내 번호")
                .font(.subheadline.bold())
                .foregroundColor(DesignSystem.textSecondary)

            HStack(spacing: 8) {
                ForEach(item.numbers, id: \.self) { n in
                    let isMatch = winning.numbers.contains(n)
                    let isBonus = n == winning.bonusNumber

                    ZStack {
                        LottoBallView(
                            number: n,
                            size: 44,
                            isHighlighted: animatedMatches.contains(n) && (isMatch || isBonus)
                        )

                        // 일치 표시 — 애니메이션 후 나타남
                        if animatedMatches.contains(n) && isMatch {
                            Circle()
                                .stroke(DesignSystem.gold, lineWidth: 2.5)
                                .frame(width: 48, height: 48)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
            }

            // 일치 개수 텍스트
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.gold)
                    .font(.caption)
                Text("\(result.matchCount)개 일치")
                    .font(.caption.bold())
                    .foregroundColor(DesignSystem.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 결과 카드
    private var resultCard: some View {
        VStack(spacing: 16) {
            // 등수
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.rank == .none ? "아쉽게도 낙첨입니다" : "축하합니다!")
                        .font(.headline.bold())
                        .foregroundColor(result.rank == .none ? DesignSystem.textSecondary : DesignSystem.gold)
                    Text(result.rank == .none ? "다음 회차를 노려보세요 💪" : "\(result.rank.title) 당첨!")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.textPrimary)
                }
                Spacer()
                Text(result.rank.emoji)
                    .font(.system(size: 44))
            }

            if result.rank != .none {
                Divider().background(DesignSystem.textSecondary.opacity(0.2))

                // 당첨금 (1등만 실제 금액, 나머지는 고정)
                HStack {
                    Text("당첨금")
                        .font(.subheadline)
                        .foregroundColor(DesignSystem.textSecondary)
                    Spacer()
                    Text(prizeText)
                        .font(.headline.bold())
                        .foregroundColor(DesignSystem.gold)
                }
            }
        }
        .padding(20)
        .background {
            if result.rank == LottoRank.none {
                DesignSystem.cardBackground
            } else {
                DesignSystem.cardBackground.overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignSystem.gold.opacity(0.4), lineWidth: 1)
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: result.rank == .none ? .clear : DesignSystem.gold.opacity(0.15),
            radius: 12
        )
    }

    // MARK: - 당첨금 텍스트
    private var prizeText: String {
        switch result.rank {
        case .first:  return "\(winning.firstPrize.formatted())원"
        case .second: return "약 6천만원"
        case .third:  return "약 150만원"
        case .fourth: return "50,000원"
        case .fifth:  return "5,000원"
        case .none:   return "-"
        }
    }

    // MARK: - 애니메이션
    private func animateMatches() {
        let matchNumbers = item.numbers.filter { winning.numbers.contains($0) }
        for (i, n) in matchNumbers.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15 + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    _ = animatedMatches.insert(n)
                }
            }
        }
        // 당첨 시 컨페티
        if result.rank != .none {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showConfetti = true
            }
        }
    }
}

// MARK: - 간단한 컨페티 효과
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = (0..<30).map { _ in ConfettiParticle() }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                for i in particles.indices {
                    particles[i].y += CGFloat.random(in: 200...500)
                    particles[i].opacity = 0
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat = CGFloat.random(in: 40...340)
    var y: CGFloat = CGFloat.random(in: 100...300)
    let size: CGFloat = CGFloat.random(in: 6...12)
    var opacity: Double = Double.random(in: 0.6...1.0)
    let color: Color = [
        Color(hex: "#F5C518"),
        Color(hex: "#E63946"),
        Color(hex: "#3B82F6"),
        Color(hex: "#10B981"),
        Color.white
    ].randomElement()!
}

#Preview {
    WinningResultView(
        item: {
            let item = LottoNumber(numbers: [3, 15, 27, 31, 38, 45], round: 1174)
            return item
        }(),
        winning: WinningNumber(
            round: 1174,
            drawDate: "2026-04-25",
            numbers: [3, 15, 27, 33, 42, 45],
            bonusNumber: 22,
            firstPrize: 2_345_678_900,
            firstWinnerCount: 3
        ),
        result: CheckResult(matchCount: 3, rank: .fifth, prizeAmount: 5000)
    )
    .preferredColorScheme(.dark)
}
