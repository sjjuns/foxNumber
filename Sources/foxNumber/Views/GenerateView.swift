import SwiftUI
import SwiftData

struct GenerateView: View {
    @Environment(\.modelContext) private var context
    @State private var vm = GenerateViewModel()
    @State private var showSavedToast = false

    var body: some View {
        ZStack {
            DesignSystem.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    roundInfoCard
                    ballsSection
                    gameCountSection
                    buttonSection
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.md)
                .padding(.bottom, 32)
            }

            if showSavedToast {
                VStack {
                    Spacer()
                    toastView.padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - 회차 정보 카드
    private var roundInfoCard: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("제 \(vm.currentRound)회")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.textPrimary)
                Text("\(vm.nextDrawDate) 추첨")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                Text("D-\(vm.daysUntilDraw)")
                    .font(DesignSystem.Typography.title)
                    .foregroundStyle(DesignSystem.accent)
                Text("추첨까지")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(DesignSystem.divider, lineWidth: 1)
        )
    }

    // MARK: - 번호 볼 영역
    private var ballsSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            if vm.generatedSets.isEmpty {
                emptyBallsPlaceholder
            } else {
                ForEach(Array(vm.generatedSets.enumerated()), id: \.offset) { setIndex, numbers in
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Text("\(setIndex + 1)")
                            .font(DesignSystem.Typography.micro)
                            .foregroundStyle(DesignSystem.textTertiary)
                            .frame(width: 14)

                        ForEach(numbers, id: \.self) { number in
                            if vm.isBallVisible(setIndex: setIndex, number: number) {
                                LottoBallView(number: number, size: 44)
                                    .transition(.scale(scale: 0.1).combined(with: .opacity))
                            } else {
                                EmptyBallView(size: 44)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(DesignSystem.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(DesignSystem.divider, lineWidth: 1)
        )
    }

    private var emptyBallsPlaceholder: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Text("1")
                .font(DesignSystem.Typography.micro)
                .foregroundStyle(DesignSystem.textTertiary)
                .frame(width: 14)
            ForEach(0..<6, id: \.self) { _ in
                EmptyBallView(size: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 게임 수 선택
    private var gameCountSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("게임 수")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)

            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(1...5, id: \.self) { count in
                    Button {
                        withAnimation(.spring(response: 0.2)) { vm.gameCount = count }
                    } label: {
                        Text("\(count)")
                            .font(DesignSystem.Typography.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                vm.gameCount == count
                                ? DesignSystem.accent
                                : DesignSystem.cardBackground
                            )
                            .foregroundStyle(
                                vm.gameCount == count
                                ? Color.white
                                : DesignSystem.textSecondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                                    .stroke(
                                        vm.gameCount == count ? Color.clear : DesignSystem.divider,
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            }
        }
    }

    // MARK: - 버튼
    private var buttonSection: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Button {
                Task { await vm.generate() }
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if vm.isAnimating {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text(vm.isAnimating ? "생성 중..." : "생성하기")
                        .font(DesignSystem.Typography.headline)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(vm.isAnimating ? DesignSystem.accent.opacity(0.7) : DesignSystem.accent)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
            }
            .disabled(vm.isAnimating)

            Button {
                vm.save(context: context)
                withAnimation(.spring()) { showSavedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showSavedToast = false }
                }
            } label: {
                Text("저장하기")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(
                        vm.generatedSets.isEmpty
                        ? DesignSystem.textTertiary
                        : DesignSystem.accent
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        vm.generatedSets.isEmpty
                        ? DesignSystem.cardBackground
                        : DesignSystem.accent.opacity(0.1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .stroke(
                                vm.generatedSets.isEmpty ? DesignSystem.divider : DesignSystem.accent.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            }
            .disabled(vm.generatedSets.isEmpty || vm.isAnimating)
        }
    }

    // MARK: - 저장 토스트
    private var toastView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(DesignSystem.accent)
            Text("번호가 저장되었습니다")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textPrimary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm + 2)
        .background(DesignSystem.cardBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(DesignSystem.divider, lineWidth: 1))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }
}

#Preview {
    NavigationStack {
        GenerateView()
    }
    .modelContainer(for: LottoNumber.self, inMemory: true)
}
