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
                VStack(spacing: 28) {
                    // MARK: 회차 정보
                    roundInfoSection

                    Divider().background(DesignSystem.textSecondary.opacity(0.2))

                    // MARK: 번호 볼
                    ballsSection

                    Divider().background(DesignSystem.textSecondary.opacity(0.2))

                    // MARK: 게임 수 선택
                    gameCountSection

                    // MARK: 버튼
                    buttonSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // MARK: 저장 토스트
            if showSavedToast {
                VStack {
                    Spacer()
                    toastView
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("")
    }

    // MARK: - 회차 정보
    private var roundInfoSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("제 \(vm.currentRound)회")
                    .font(.title2.bold())
                    .foregroundColor(DesignSystem.gold)
                Text("\(vm.nextDrawDate) 추첨")
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("D-\(vm.daysUntilDraw)")
                    .font(.title2.bold())
                    .foregroundColor(DesignSystem.textPrimary)
                Text("추첨까지")
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 번호 볼 영역
    private var ballsSection: some View {
        VStack(spacing: 16) {
            if vm.generatedSets.isEmpty {
                // 생성 전 빈 볼
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { _ in
                        EmptyBallView(size: 48)
                    }
                }
                .frame(height: 56)
            } else {
                ForEach(Array(vm.generatedSets.enumerated()), id: \.offset) { setIndex, numbers in
                    HStack(spacing: 8) {
                        Text("\(setIndex + 1)")
                            .font(.caption.bold())
                            .foregroundColor(DesignSystem.textSecondary)
                            .frame(width: 16)

                        ForEach(numbers, id: \.self) { number in
                            if vm.isBallVisible(setIndex: setIndex, number: number) {
                                LottoBallView(number: number, size: 44)
                                    .transition(.scale(scale: 0.1).combined(with: .opacity))
                            } else {
                                EmptyBallView(size: 44)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - 게임 수 선택
    private var gameCountSection: some View {
        HStack(spacing: 0) {
            Text("게임 수")
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)

            Spacer()

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { count in
                    Button {
                        withAnimation(.spring(response: 0.2)) {
                            vm.gameCount = count
                        }
                    } label: {
                        Text("\(count)")
                            .font(.subheadline.bold())
                            .frame(width: 36, height: 36)
                            .background(
                                vm.gameCount == count
                                ? DesignSystem.gold
                                : DesignSystem.cardBackground
                            )
                            .foregroundColor(
                                vm.gameCount == count
                                ? DesignSystem.background
                                : DesignSystem.textSecondary
                            )
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - 버튼
    private var buttonSection: some View {
        VStack(spacing: 12) {
            // 생성하기
            Button {
                Task { await vm.generate() }
            } label: {
                HStack {
                    if vm.isAnimating {
                        ProgressView()
                            .tint(DesignSystem.background)
                            .scaleEffect(0.8)
                    }
                    Text(vm.isAnimating ? "생성 중..." : "생성하기")
                        .font(.headline.bold())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    vm.isAnimating
                    ? DesignSystem.gold.opacity(0.6)
                    : DesignSystem.gold
                )
                .foregroundColor(DesignSystem.background)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: DesignSystem.gold.opacity(0.4), radius: 12, y: 4)
            }
            .disabled(vm.isAnimating)

            // 저장하기
            Button {
                vm.save(context: context)
                withAnimation(.spring()) { showSavedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { showSavedToast = false }
                }
            } label: {
                Text("💾 저장하기")
                    .font(.subheadline.bold())
                    .foregroundColor(vm.generatedSets.isEmpty ? DesignSystem.textSecondary : DesignSystem.gold)
            }
            .disabled(vm.generatedSets.isEmpty || vm.isAnimating)
        }
    }

    // MARK: - 저장 토스트
    private var toastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(DesignSystem.gold)
            Text("번호가 저장되었습니다")
                .font(.subheadline.bold())
                .foregroundColor(DesignSystem.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DesignSystem.cardBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 8)
    }
}

#Preview {
    NavigationStack {
        GenerateView()
    }
    .modelContainer(for: LottoNumber.self, inMemory: true)
    .preferredColorScheme(.dark)
}
