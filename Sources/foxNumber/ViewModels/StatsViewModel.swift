import SwiftUI

@Observable
final class StatsViewModel {

    // MARK: - State
    enum State {
        case idle
        case loading(progress: Double)   // 0.0 ~ 1.0
        case loaded
        case failure(String)
    }

    var state: State = .idle
    var stats: [NumberStat] = []
    var fetchedRounds: Int = 0

    private let service = LottoService.shared
    private let cache   = WinningNumberCache.shared

    // MARK: - 불러오기
    @MainActor
    func load(range: Int) async {
        state = .loading(progress: 0)
        stats = []
        fetchedRounds = 0

        let latestRound = service.currentRound() - 1   // 마지막 확정 회차
        let startRound  = max(1, latestRound - range + 1)
        let rounds      = Array(startRound...latestRound)

        var countMap: [Int: Int] = Dictionary(uniqueKeysWithValues: (1...45).map { ($0, 0) })
        var success = 0

        // 5개씩 병렬 패치 (API 부하 방지)
        let chunks = rounds.chunked(into: 5)

        for (chunkIndex, chunk) in chunks.enumerated() {
            await withTaskGroup(of: WinningNumber?.self) { group in
                for round in chunk {
                    group.addTask { [weak self] in
                        guard let self else { return nil }
                        if let cached = self.cache.get(round: round) { return cached }
                        return try? await self.service.fetchWinningNumber(round: round)
                    }
                }
                for await result in group {
                    guard let winning = result else { continue }
                    cache.set(winning)
                    winning.numbers.forEach { countMap[$0, default: 0] += 1 }
                    success += 1
                }
            }

            let progress = Double(chunkIndex + 1) / Double(chunks.count)
            state = .loading(progress: progress)
        }

        if success == 0 {
            state = .failure("네트워크 연결을 확인해주세요")
            return
        }

        stats = countMap.map { NumberStat(number: $0.key, count: $0.value) }
            .sorted { $0.number < $1.number }
        fetchedRounds = success
        state = .loaded
    }

    // MARK: - 파생 통계
    var hotNumbers: [Int] {
        stats.sorted { $0.count > $1.count }.prefix(6).map(\.number).sorted()
    }

    var coldNumbers: [Int] {
        stats.filter { $0.count > 0 }.sorted { $0.count < $1.count }.prefix(6).map(\.number).sorted()
    }

    var oddRatio: Int {
        let odd   = stats.filter { $0.number % 2 != 0 }.map(\.count).reduce(0, +)
        let total = stats.map(\.count).reduce(0, +)
        guard total > 0 else { return 50 }
        return Int(Double(odd) / Double(total) * 100)
    }

    var lowRatio: Int {
        let v = stats.filter { $0.number <= 15 }.map(\.count).reduce(0, +)
        let t = stats.map(\.count).reduce(0, +)
        guard t > 0 else { return 33 }
        return Int(Double(v) / Double(t) * 100)
    }

    var midRatio: Int {
        let v = stats.filter { $0.number >= 16 && $0.number <= 30 }.map(\.count).reduce(0, +)
        let t = stats.map(\.count).reduce(0, +)
        guard t > 0 else { return 33 }
        return Int(Double(v) / Double(t) * 100)
    }

    var highRatio: Int { 100 - lowRatio - midRatio }

    var maxCount: Int { stats.map(\.count).max() ?? 1 }
}

// MARK: - Array chunked helper
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
