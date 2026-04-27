import Foundation
import SwiftData

@Model
final class LottoNumber {
    var id: UUID
    var numbers: [Int]
    var savedAt: Date
    var round: Int
    var checkResult: CheckResult?

    init(numbers: [Int], round: Int = 0) {
        self.id = UUID()
        self.numbers = numbers.sorted()
        self.savedAt = Date()
        self.round = round
        self.checkResult = nil
    }
}

// MARK: - 당첨 결과
struct CheckResult: Codable {
    let matchCount: Int
    let rank: LottoRank
    let prizeAmount: Int
}

enum LottoRank: Int, Codable, CaseIterable {
    case first  = 1
    case second = 2
    case third  = 3
    case fourth = 4
    case fifth  = 5
    case none   = 0

    var title: String {
        switch self {
        case .first:  return "1등"
        case .second: return "2등"
        case .third:  return "3등"
        case .fourth: return "4등"
        case .fifth:  return "5등"
        case .none:   return "낙첨"
        }
    }

    var emoji: String {
        switch self {
        case .first:  return "🏆"
        case .second: return "🥈"
        case .third:  return "🥉"
        case .fourth: return "🎖️"
        case .fifth:  return "🎗️"
        case .none:   return "😢"
        }
    }
}

// MARK: - 당첨 번호 (API 응답)
struct WinningNumber: Codable, Equatable {
    let round: Int
    let drawDate: String
    let numbers: [Int]
    let bonusNumber: Int
    let firstPrize: Int
    let firstWinnerCount: Int
}
