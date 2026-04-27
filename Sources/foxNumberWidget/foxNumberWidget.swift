import WidgetKit
import SwiftUI

// MARK: - 위젯 엔트리
struct LottoEntry: TimelineEntry {
    let date: Date
    let numbers: [Int]
    let round: Int
    let daysUntilDraw: Int
    let nextDrawDate: String
}

// MARK: - Provider
struct LottoProvider: TimelineProvider {

    func placeholder(in context: Context) -> LottoEntry {
        LottoEntry(
            date: Date(),
            numbers: [3, 15, 27, 31, 38, 45],
            round: 1175,
            daysUntilDraw: 3,
            nextDrawDate: "5월 3일"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LottoEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LottoEntry>) -> Void) {
        let entry = makeEntry()
        // 매일 자정 갱신
        let midnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        let timeline = Timeline(entries: [entry], policy: .after(midnight))
        completion(timeline)
    }

    private func makeEntry() -> LottoEntry {
        let numbers = Array((1...45).shuffled().prefix(6)).sorted()
        let round = currentRound()
        let days  = daysUntilDraw()
        let dateStr = nextDrawDateString()
        return LottoEntry(
            date: Date(),
            numbers: numbers,
            round: round,
            daysUntilDraw: days,
            nextDrawDate: dateStr
        )
    }

    // MARK: - 헬퍼 (위젯은 앱 코드 공유 불가 → 인라인)
    private func currentRound() -> Int {
        let base = Calendar.current.date(from: DateComponents(year: 2002, month: 11, day: 30))!
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: base, to: Date()).weekOfYear ?? 0
        return weeks + 1
    }

    private func daysUntilDraw() -> Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextDrawDate()).day ?? 0
    }

    private func nextDrawDate() -> Date {
        var cal = Calendar.current
        cal.locale = Locale(identifier: "ko_KR")
        var c = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        c.weekday = 7; c.hour = 20; c.minute = 35
        let sat = cal.date(from: c)!
        return sat > Date() ? sat : cal.date(byAdding: .weekOfYear, value: 1, to: sat)!
    }

    private func nextDrawDateString() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: nextDrawDate())
    }
}

// MARK: - Small 위젯 뷰
struct SmallWidgetView: View {
    let entry: LottoEntry

    var body: some View {
        ZStack {
            Color(red: 13/255, green: 15/255, blue: 26/255)

            VStack(spacing: 6) {
                // 상단: 회차 + D-day
                HStack {
                    Text("제 \(entry.round)회")
                        .font(.caption2.bold())
                        .foregroundColor(Color(red: 245/255, green: 197/255, blue: 24/255))
                    Spacer()
                    Text("D-\(entry.daysUntilDraw)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                }

                Spacer()

                // 번호 볼 3x2
                VStack(spacing: 5) {
                    HStack(spacing: 5) {
                        ForEach(entry.numbers.prefix(3), id: \.self) { WidgetBall(number: $0, size: 28) }
                    }
                    HStack(spacing: 5) {
                        ForEach(entry.numbers.suffix(3), id: \.self) { WidgetBall(number: $0, size: 28) }
                    }
                }

                Spacer()

                // 하단: 추첨일
                Text(entry.nextDrawDate + " 추첨")
                    .font(.system(size: 9))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(12)
        }
    }
}

// MARK: - Medium 위젯 뷰
struct MediumWidgetView: View {
    let entry: LottoEntry

    var body: some View {
        ZStack {
            Color(red: 13/255, green: 15/255, blue: 26/255)

            HStack(spacing: 16) {
                // 좌: 정보
                VStack(alignment: .leading, spacing: 6) {
                    Text("제 \(entry.round)회")
                        .font(.caption.bold())
                        .foregroundColor(Color(red: 245/255, green: 197/255, blue: 24/255))
                    Text("오늘의 추천 번호")
                        .font(.caption2)
                        .foregroundColor(Color(white: 0.5))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                            .foregroundColor(Color(white: 0.5))
                        Text(entry.nextDrawDate)
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.5))
                    }
                    Text("D-\(entry.daysUntilDraw)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .frame(width: 90)

                Divider()
                    .background(Color.white.opacity(0.1))

                // 우: 번호 볼
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        ForEach(entry.numbers.prefix(3), id: \.self) { WidgetBall(number: $0, size: 34) }
                    }
                    HStack(spacing: 6) {
                        ForEach(entry.numbers.suffix(3), id: \.self) { WidgetBall(number: $0, size: 34) }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(14)
        }
    }
}

// MARK: - 위젯 볼 (경량 버전)
struct WidgetBall: View {
    let number: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(ballColor)
                .frame(width: size, height: size)
            Text("\(number)")
                .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var ballColor: Color {
        switch number {
        case 1...10:  return Color(red: 245/255, green: 197/255, blue: 24/255)
        case 11...20: return Color(red: 59/255,  green: 130/255, blue: 246/255)
        case 21...30: return Color(red: 230/255, green: 57/255,  blue: 70/255)
        case 31...40: return Color(red: 107/255, green: 114/255, blue: 128/255)
        default:      return Color(red: 16/255,  green: 185/255, blue: 129/255)
        }
    }
}

// MARK: - Widget 정의
struct foxNumberWidget: Widget {
    let kind = "foxNumberWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LottoProvider()) { entry in
            foxNumberWidgetEntryView(entry: entry)
                .containerBackground(
                    Color(red: 13/255, green: 15/255, blue: 26/255),
                    for: .widget
                )
        }
        .configurationDisplayName("오늘의 로또 번호")
        .description("매일 새로운 행운의 번호를 확인하세요")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct foxNumberWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LottoEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Bundle
@main
struct foxNumberWidgetBundle: WidgetBundle {
    var body: some Widget {
        foxNumberWidget()
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    foxNumberWidget()
} timeline: {
    LottoEntry(date: .now, numbers: [3,15,27,31,38,45], round: 1175, daysUntilDraw: 3, nextDrawDate: "5월 3일")
}

#Preview(as: .systemMedium) {
    foxNumberWidget()
} timeline: {
    LottoEntry(date: .now, numbers: [3,15,27,31,38,45], round: 1175, daysUntilDraw: 3, nextDrawDate: "5월 3일")
}
