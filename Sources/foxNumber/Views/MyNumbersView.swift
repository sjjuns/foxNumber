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

                // 로딩 오버레이
                if case .loading = checkVM.state {
                    loadingOverlay
                }
            }
            .navigationTitle("내 번호")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            // 단일 결과 시트
            .sheet(isPresented: $showResultSheet) {
                if let first = checkVM.results.first {
                    WinningResultView(
                        item: first.item,
                        winning: first.winning,
                        result: first.result
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(.dark)
                }
            }
            // 에러 알럿
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
        List {
            ForEach(groupedByRound, id: \.key) { round, items in
                Section {
                    ForEach(items) { item in
                        NumberRowView(item: item) {
                            // 행 탭 → 단일 당첨 확인
                            Task { await checkVM.check(item: item) }
                        }
                        .listRowBackground(DesignSystem.cardBackground)
                        .listRowSeparatorTint(DesignSystem.textSecondary.opacity(0.15))
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                context.delete(item)
                            } label: {
                                Label("삭제", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                Task { await checkVM.check(item: item) }
                            } label: {
                                Label("확인", systemImage: "checkmark.circle")
                            }
                            .tint(DesignSystem.gold)
                        }
                    }
                } header: {
                    HStack {
                        Text("제 \(round)회")
                            .font(.caption.bold())
                            .foregroundColor(DesignSystem.gold)
                        Spacer()
                        Text("\(items.count)게임")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                }
            }

            // 일괄 당첨 확인
            Section {
                Button {
                    Task { await checkVM.checkAll(items: uncheckedNumbers, context: context) }
                } label: {
                    HStack {
                        Spacer()
                        if uncheckedNumbers.isEmpty {
                            Text("모든 번호 확인 완료")
                                .font(.subheadline)
                                .foregroundColor(DesignSystem.textSecondary)
                        } else {
                            Text("미확인 \(uncheckedNumbers.count)개 당첨 확인")
                                .font(.subheadline.bold())
                                .foregroundColor(DesignSystem.background)
                        }
                        Spacer()
                    }
                    .frame(height: 44)
                    .background(uncheckedNumbers.isEmpty ? DesignSystem.cardBackground : DesignSystem.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(uncheckedNumbers.isEmpty)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - 빈 상태
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(DesignSystem.textSecondary)
            Text("저장된 번호가 없어요")
                .font(.headline)
                .foregroundColor(DesignSystem.textSecondary)
            Text("생성 탭에서 번호를 만들고 저장해보세요")
                .font(.caption)
                .foregroundColor(DesignSystem.textSecondary.opacity(0.6))
        }
    }

    // MARK: - 로딩 오버레이
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(DesignSystem.gold)
                    .scaleEffect(1.4)
                Text("당첨 번호 확인 중...")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.textPrimary)
            }
            .padding(32)
            .background(DesignSystem.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
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
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    ForEach(item.numbers, id: \.self) { number in
                        LottoBallView(
                            number: number,
                            size: 36,
                            isHighlighted: item.checkResult != nil && item.checkResult?.rank != LottoRank.none
                        )
                    }
                    Spacer()
                    resultBadge
                }
                Text(item.savedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(DesignSystem.textSecondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var resultBadge: some View {
        if let result = item.checkResult {
            Text("\(result.rank.emoji) \(result.rank.title)")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(result.rank == LottoRank.none
                    ? DesignSystem.textSecondary.opacity(0.2)
                    : DesignSystem.gold.opacity(0.2))
                .foregroundColor(result.rank == LottoRank.none
                    ? DesignSystem.textSecondary
                    : DesignSystem.gold)
                .clipShape(Capsule())
        } else {
            Text("탭하여 확인")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DesignSystem.textSecondary.opacity(0.15))
                .foregroundColor(DesignSystem.textSecondary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    MyNumbersView()
        .modelContainer(for: LottoNumber.self, inMemory: true)
        .preferredColorScheme(.dark)
}
