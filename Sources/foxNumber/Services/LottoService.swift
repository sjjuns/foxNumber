import Foundation

final class LottoService {

    static let shared = LottoService()
    private init() {}

    // MARK: - 번호 생성
    func generateNumbers(count: Int = 1) -> [[Int]] {
        (0..<count).map { _ in
            Array((1...45).shuffled().prefix(6)).sorted()
        }
    }

    // MARK: - 당첨 확인
    func checkResult(myNumbers: [Int], winning: WinningNumber) -> CheckResult {
        let matchCount = Set(myNumbers).intersection(Set(winning.numbers)).count
        let bonusMatch = myNumbers.contains(winning.bonusNumber)

        let rank: LottoRank
        switch (matchCount, bonusMatch) {
        case (6, _): rank = .first
        case (5, true): rank = .second
        case (5, false): rank = .third
        case (4, _): rank = .fourth
        case (3, _): rank = .fifth
        default: rank = .none
        }

        return CheckResult(matchCount: matchCount, rank: rank, prizeAmount: 0)
    }

    // MARK: - 동행복권 API
    func fetchWinningNumber(round: Int) async throws -> WinningNumber {
        let urlString = "https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo=\(round)"
        guard let url = URL(string: urlString) else {
            throw LottoError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let json,
              let returnValue = json["returnValue"] as? String,
              returnValue == "success" else {
            throw LottoError.fetchFailed
        }

        let numbers = (1...6).compactMap { json["drwtNo\($0)"] as? Int }
        let bonus = json["bnusNo"] as? Int ?? 0
        let round = json["drwNo"] as? Int ?? 0
        let date = json["drwNoDate"] as? String ?? ""
        let prize = json["firstWinamnt"] as? Int ?? 0
        let winnerCount = json["firstPrzwnerCo"] as? Int ?? 0

        return WinningNumber(
            round: round,
            drawDate: date,
            numbers: numbers,
            bonusNumber: bonus,
            firstPrize: prize,
            firstWinnerCount: winnerCount
        )
    }

    // MARK: - 현재 회차 계산
    func currentRound() -> Int {
        let baseDate = Calendar.current.date(from: DateComponents(year: 2002, month: 11, day: 30))!
        let now = Date()
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: baseDate, to: now).weekOfYear ?? 0
        return weeks + 1
    }

    // MARK: - 다음 추첨일 계산
    func nextDrawDate() -> Date {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "ko_KR")
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 7 // 토요일
        components.hour = 20
        components.minute = 35
        let thisSaturday = calendar.date(from: components)!
        return thisSaturday > now ? thisSaturday : calendar.date(byAdding: .weekOfYear, value: 1, to: thisSaturday)!
    }

    func daysUntilDraw() -> Int {
        let next = nextDrawDate()
        return Calendar.current.dateComponents([.day], from: Date(), to: next).day ?? 0
    }
}

enum LottoError: LocalizedError {
    case invalidURL
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "잘못된 URL입니다"
        case .fetchFailed: return "당첨번호를 불러오지 못했습니다"
        }
    }
}
