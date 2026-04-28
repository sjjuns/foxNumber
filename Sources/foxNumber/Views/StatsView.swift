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
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        rangeSelector
                            .padding(.horizontal, DesignSystem.Spacing.md)

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
                    .padding(.top, DesignSystem.Spacing.md)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("번호 통계")
            .navigationBarTitleDisplayMode(.large)
            .onChange(of: selectedRange) { _, _ in
                Task { await vm.load(range: selectedRange.count) }
            }
        }
    }

    // MARK: - 범위 선택 (커스텀 캡슐 탭)
    private var rangeSelector: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(StatRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.25)) { selectedRange = range }
                } label: {
                    Text(range.rawValue)
                        .font(DesignSystem.Typography.caption)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(
                            selectedRange == range
                            ? DesignSystem.accent
                            : DesignSystem.cardBackground
                        )
                        .foregroundStyle(
                            selectedRange == range
                            ? Color.white
                            : DesignSystem.textSecondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.sm)
                                .stroke(
                                    selectedRange == range ? Color.clear : DesignSystem.divider,
                                    lineWidth: 1
                                )
                        )
                }
            }
        }
    }

    // MARK: - 로딩
    private func loadingView(progress: Double) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer().frame(height: 40)
            ZStack {
                Circle()
                    .stroke(DesignSystem.divider, lineWidth: 6)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(DesignSystem.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.2), value: progress)
                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.accent)
            }
            Text("회차 데이터 불러오는 중...")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 에러
    private func errorView(_ msg: String) -> some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.textTertiary)
            Text(msg)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
            Button("다시 시도") {
                Task { await vm.load(range: selectedRange.count) }
            }
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.accent)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, 10)
            .overlay(Capsule().stroke(DesignSystem.accent, lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - 통계 콘텐츠
    private var statsContent: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(DesignSystem.accent)
                    .font(DesignSystem.Typography.micro)
                Text("동행복권 실제 데이터 \(vm.fetchedRounds)회차 기준")
                    .font(DesignSystem.Typography.micro)
                    .foregroundStyle(DesignSystem.textTertiary)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            frequencyChartSection
            hotColdSection
            distributionSection
        }
    }

    // MARK: - 빈도 차트
    private var frequencyChartSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("번호별 출현 빈도")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.textPrimary)

            Chart(vm.stats) { stat in
                BarMark(
                    x: .value("번호", stat.number),
                    y: .value("횟수", stat.count)
                )
                .foregroundStyle(
                    vm.hotNumbers.contains(stat.number)
                    ? DesignSystem.accent
                    : vm.coldNumbers.contains(stat.number)
                      ? DesignSystem.textTertiary
                      : DesignSystem.ballColor(for: stat.number).opacity(0.75)
                )
                .cornerRadius(2)
            }
            .frame(height: 180)
            .chartYScale(domain: 0...Int(Double(vm.maxCount) * 1.2))
            .chartXAxis {
                AxisMarks(values: [1, 10, 20, 30, 40, 45]) { value in
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.textTertiary)
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(value.as(Int.self) ?? 0)")
                            .font(.system(size: 10))
                            .foregroundStyle(DesignSystem.textTertiary)
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(DesignSystem.divider)
                }
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                legendDot(color: DesignSystem.accent, label: "핫 번호")
                legendDot(color: DesignSystem.textTertiary, label: "콜드 번호")
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(DesignSystem.divider, lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).font(DesignSystem.Typography.micro).foregroundStyle(DesignSystem.textTertiary)
        }
    }

    // MARK: - 핫/콜드 (가로 스크롤)
    private var hotColdSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Text("핫 / 콜드 번호")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(DesignSystem.textPrimary)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    statCard(title: "🔥 핫", subtitle: "자주 나온 번호", numbers: vm.hotNumbers)
                    statCard(title: "🧊 콜드", subtitle: "안 나온 번호", numbers: vm.coldNumbers)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    private func statCard(title: String, subtitle: String, numbers: [Int]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textPrimary)
                Text(subtitle)
                    .font(DesignSystem.Typography.micro)
                    .foregroundStyle(DesignSystem.textTertiary)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(38), spacing: DesignSystem.Spacing.sm), count: 3),
                spacing: DesignSystem.Spacing.sm
            ) {
                ForEach(numbers, id: \.self) { LottoBallView(number: $0, size: 34) }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(width: 160)
        .background(DesignSystem.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(DesignSystem.divider, lineWidth: 1)
        )
    }

    // MARK: - 분포
    private var distributionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("분포 요약")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.textPrimary)

            distributionBar(
                left: ("홀수", vm.oddRatio, DesignSystem.accent),
                right: ("짝수", 100 - vm.oddRatio, DesignSystem.textTertiary)
            )

            HStack(spacing: 2) {
                rangeBar(label: "저\n1-15",  ratio: vm.lowRatio,  color: Color(hex: "#F5C518"))
                rangeBar(label: "중\n16-30", ratio: vm.midRatio,  color: Color(hex: "#3B82F6"))
                rangeBar(label: "고\n31-45", ratio: vm.highRatio, color: Color(hex: "#E63946"))
            }
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                .stroke(DesignSystem.divider, lineWidth: 1)
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private func distributionBar(
        left: (String, Int, Color),
        right: (String, Int, Color)
    ) -> some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(left.2)
                        .frame(width: geo.size.width * CGFloat(left.1) / 100)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(right.2.opacity(0.4))
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(left.0) \(left.1)%")
                    .font(DesignSystem.Typography.micro).foregroundStyle(left.2)
                Spacer()
                Text("\(right.0) \(right.1)%")
                    .font(DesignSystem.Typography.micro).foregroundStyle(DesignSystem.textTertiary)
            }
        }
    }

    private func rangeBar(label: String, ratio: Int, color: Color) -> some View {
        ZStack {
            color.opacity(0.85)
            VStack(spacing: 2) {
                Text("\(ratio)%").font(DesignSystem.Typography.micro).bold().foregroundStyle(.white)
                Text(label).font(.system(size: 9)).foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(width: UIScreen.main.bounds.width * 0.8 * CGFloat(ratio) / 100)
    }
}

#Preview {
    StatsView()
}
