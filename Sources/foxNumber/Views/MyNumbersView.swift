import SwiftUI
import SwiftData

struct MyNumbersView: View {
    @Query(sort: \LottoNumber.savedAt, order: .reverse) private var numbers: [LottoNumber]
    @Environment(\.modelContext) private var context

    @State private var checkVM = CheckViewModel()
    @State private var selectedItem: LottoNumber?
    @State private var showResultSheet = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                if numbers.isEmpty {
                    emptyView
                } else {
                    listView
                }

                if case .loading = checkVM.state {
                    loadingOverlay
                }
            }
            .navigationTitle("내 번호")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showResultSheet) {
                if let first = checkVM.results.first {
                    WinningResultView(
                        item: first.item,
                        winning: first.winning,
                        result: first.result
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .alert("확인 실패", isPresented: $showErrorAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onChange(of: checkVM.state) { _, newState in
                switch newState {
                case .success:
                    showResultSheet = true
                case .failure(let msg):
                    errorMessage = msg
                    showErrorAlert = true
                default:
                    break
                }
            }
        }
    }

    // MARK: - 목록
    private var listView: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // 일괄 확인 버튼
                if !uncheckedNumbers.isEmpty {
                    batchCheckButton
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.sm)
                }

                ForEach(groupedByRound, id: \.key) { round, items in
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        // 섹션 헤더
                        HStack {
                            Text("제 \(round)회")
                                .font(DesignSystem.Typography.micro)
                                .foregroundStyle(DesignSystem.textTertiary)
                            Spacer()
                            Text("\(items.count)게임")
                                .font(DesignSystem.Typography.micro)
                                .foregroundStyle(DesignSystem.textTertiary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)

                        VStack(spacing: 1) {
                            ForEach(items) { item in
                                NumberRowView(item: item) {
                                    Task { await checkVM.check(item: item) }
                                }
                                .background(DesignSystem.cardBackground)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        context.delete(item)
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                .stroke(DesignSystem.divider, lineWidth: 1)
                        )
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                }
            }
            .padding(.bottom, 32)
        }
    }

    private var batchCheckButton: some View {
        Button {
            Task { await checkVM.checkAll(items: uncheckedNumbers, context: context) }
        } label: {
            HStack {
                Image(systemName: "checkmark.circle")
                Text("미확인 \(uncheckedNumbers.count)개 당첨 확인")
                    .font(DesignSystem.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DesignSystem.accent)
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        }
    }

    // MARK: - 빈 상태
    private var emptyView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(DesignSystem.textTertiary)
            Text("저장된 번호가 없어요")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.textSecondary)
            Text("생성 탭에서 번호를 만들고 저장해보세요")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textTertiary)
        }
    }

    // MARK: - 로딩 오버레이
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: DesignSystem.Spacing.md) {
                ProgressView()
                    .tint(DesignSystem.accent)
                    .scaleEffect(1.4)
                Text("당첨 번호 확인 중...")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .stroke(DesignSystem.divider, lineWidth: 1)
            )
        }
    }

    // MARK: - 헬퍼
    private var groupedByRound: [(key: Int, value: [LottoNumber])] {
        Dictionary(grouping: numbers, by: \.round)
            .sorted { $0.key > $1.key }
    }

    private var uncheckedNumbers: [LottoNumber] {
        numbers.filter { $0.checkResult == nil }
    }
}

// MARK: - 번호 행
struct NumberRowView: View {
    let item: LottoNumber
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: 5) {
                    ForEach(item.numbers, id: \.self) { number in
                        LottoBallView(
                            number: number,
                            size: 34,
                            isHighlighted: item.checkResult?.rank != nil && item.checkResult?.rank != LottoRank.none
                        )
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    resultBadge
                    Text(item.savedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(DesignSystem.Typography.micro)
                        .foregroundStyle(DesignSystem.textTertiary)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var resultBadge: some View {
        if let result = item.checkResult {
            Text(result.rank == LottoRank.none ? "낙첨" : "\(result.rank.emoji) \(result.rank.title)")
                .font(DesignSystem.Typography.micro)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(result.rank == LottoRank.none
                    ? DesignSystem.groupBackground
                    : DesignSystem.accent.opacity(0.15))
                .foregroundStyle(result.rank == LottoRank.none
                    ? DesignSystem.textTertiary
                    : DesignSystem.accent)
                .clipShape(Capsule())
        } else {
            Text("확인하기")
                .font(DesignSystem.Typography.micro)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(DesignSystem.groupBackground)
                .foregroundStyle(DesignSystem.textTertiary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    MyNumbersView()
        .modelContainer(for: LottoNumber.self, inMemory: true)
}
