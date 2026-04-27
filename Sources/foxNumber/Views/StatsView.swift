import SwiftUI
import Charts

struct StatsView: View {

    enum StatRange: String, CaseIterable {
        case recent10  = "10회"
        case recent50  = "50회"
        case recent100 = "100회"
        var count: Int {
            switch self { case .recent10: 10; case .recent50: 50; case .recent100: 100 }
        }
    }

    @State private var vm = StatsViewModel()
    @State private var selectedRange: StatRange = .recent50

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 범위 선택
                        Picker("범위", selection: $selectedRange) {
                            ForEach(StatRange.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)

                        // 상태별 콘텐츠
                        switch vm.state {
                        case .idle:
                            Color.clear.onAppear { Task { await vm.load(range: selectedRange.count) } }

                        case .loading(let progress):
                            loadingView(progress: progress)

                        case .loaded:
                            statsContent

                        case .failure(let msg):
                            errorView(msg)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("번호 통계")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedRange) { _, _ in
                Task { await vm.load(range: selectedRange.count) }
            }
        }
    }

    // MARK: - 로딩
    private func loadingView(progress: Double) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            ZStack {
                Circle()
                    .stroke(DesignSystem.cardBackground, lineWidth: 6)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(DesignSystem.gold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: progress)
                Text("\(Int(progress * 100))%")
                    .font(.caption.bold())
                    .foregroundColor(DesignSystem.gold)
            }

            Text("회차 데이터 불러오는 중...")
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 에러
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(DesignSystem.textSecondary)
            Text(msg)
                .font(.subheadline)
                .foregroundColor(DesignSystem.textSecondary)
            Button("다시 시도") {
                Task { await vm.load(range: selectedRange.count) }
            }
            .font(.subheadline.bold())
            .foregroundColor(DesignSystem.gold)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .overlay(Capsule().stroke(DesignSystem.gold, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - 통계 콘텐츠
    private var statsContent: some View {
        VStack(spacing: 20) {
            // 데이터 출처 안내
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(DesignSystem.gold)
                    .font(.caption)
                Text("동행복권 실제 데이터 \(vm.fetchedRounds)회차 기준")
                    .font(.caption)
                    .foregroundColor(DesignSystem.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 20)

            // 빈도 차트
            frequencyChartSection

            // 핫/콜드
            hotColdSection

            // 분포
            distributionSection
        }
    }

    // MARK: - 빈도 차트
    private var frequencyChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("번호별 출현 빈도")
                .font(.headline.bold())
                .foregroundColor(DesignSystem.textPrimary)
                .padding(.horizontal, 20)

            Chart(vm.stats) { stat in
                BarMark(
                    x: .value("번호", stat.number),
                    y: .value("횟수", stat.count)
                )
                .foregroundStyle(
                    vm.hotNumbers.contains(stat.number)
                    ? DesignSystem.gold
                    : vm.coldNumbers.contains(stat.number)
                      ? DesignSystem.textSecondary.opacity(0.6)
                      : DesignSystem.ballColor(for: stat.number).opacity(0.8)
                )
                .cornerRadius(2)
            }
            .frame(height: 180)
            .chartYScale(domain: 0...Int(Double(vm.maxCount) * 1.2))
            .chartXAxis {
                AxisMarks(values: [1, 10, 20, 30, 40, 45]) { value in
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.caption2)
                            .foregroundColor(DesignSystem.textSecondary)
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(DesignSystem.textSecondary.opacity(0.2))
                }
            }
            .padding(.horizontal, 20)

            // 범례
            HStack(spacing: 16) {
                legendDot(color: DesignSystem.gold, label: "핫 번호")
                legendDot(color: DesignSystem.textSecondary.opacity(0.6), label: "콜드 번호")
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
        .background(DesignSystem.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2).foregroundColor(DesignSystem.textSecondary)
        }
    }

    // MARK: - 핫/콜드
    private var hotColdSection: some View {
        HStack(spacing: 12) {
            statCard(title: "🔥 핫 번호", subtitle: "자주 나온 번호", numbers: vm.hotNumbers)
            statCard(title: "🧊 콜드 번호", subtitle: "안 나온 번호", numbers: vm.coldNumbers)
        }
        .padding(.horizontal, 20)
    }

    private func statCard(title: String, subtitle: String, numbers: [Int]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundColor(DesignSystem.textPrimary)
                Text(subtitle).font(.caption2).foregroundColor(DesignSystem.textSecondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(numbers, id: \.self) { LottoBallView(number: $0, size: 34) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(DesignSystem.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 분포
    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("분포 요약")
                .font(.headline.bold())
                .foregroundColor(DesignSystem.textPrimary)

            // 홀/짝 바
            distributionBar(
                left: ("홀수", vm.oddRatio, DesignSystem.gold),
                right: ("짝수", 100 - vm.oddRatio, DesignSystem.textSecondary)
            )

            // 구간 바
            HStack(spacing: 0) {
                rangeBar(label: "저\n1-15", ratio: vm.lowRatio,  color: Color(hex: "#F5C518"))
                rangeBar(label: "중\n16-30", ratio: vm.midRatio,  color: Color(hex: "#3B82F6"))
                rangeBar(label: "고\n31-45", ratio: vm.highRatio, color: Color(hex: "#E63946"))
            }
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(DesignSystem.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 20)
    }

    private func distributionBar(
        left: (String, Int, Color),
        right: (String, Int, Color)
    ) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(left.2)
                        .frame(width: geo.size.width * CGFloat(left.1) / 100)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(right.2.opacity(0.5))
                }
            }
            .frame(height: 10)

            HStack {
                Text("\(left.0) \(left.1)%")
                    .font(.caption2).foregroundColor(left.2)
                Spacer()
                Text("\(right.0) \(right.1)%")
                    .font(.caption2).foregroundColor(DesignSystem.textSecondary)
            }
        }
    }

    private func rangeBar(label: String, ratio: Int, color: Color) -> some View {
        ZStack {
            color.opacity(0.8)
            VStack(spacing: 2) {
                Text("\(ratio)%").font(.caption.bold()).foregroundColor(.white)
                Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(width: UIScreen.main.bounds.width * 0.8 * CGFloat(ratio) / 100)
    }
}

#Preview {
    StatsView().preferredColorScheme(.dark)
}
