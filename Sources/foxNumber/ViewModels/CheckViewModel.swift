import SwiftUI
import SwiftData

@Observable
final class CheckViewModel {

    // MARK: - State
    enum State: Equatable {
        case idle
        case loading
        case success(WinningNumber)
        case failure(String)
    }

    var state: State = .idle
    var results: [(item: LottoNumber, winning: WinningNumber, result: CheckResult)] = []

    private let service = LottoService.shared
    private let cache   = WinningNumberCache.shared

    // MARK: - 단일 번호 확인
    @MainActor
    func check(item: LottoNumber) async {
        state = .loading

        do {
            let winning = try await fetchWinning(round: item.round)
            let result  = service.checkResult(myNumbers: item.numbers, winning: winning)
            state = .success(winning)
            results = [(item: item, winning: winning, result: result)]
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    // MARK: - 전체 번호 일괄 확인
    @MainActor
    func checkAll(items: [LottoNumber], context: ModelContext) async {
        state = .loading
        results = []

        // 회차별로 그룹화해서 API 요청 최소화
        let rounds = Set(items.map(\.round))

        var winningMap: [Int: WinningNumber] = [:]
        for round in rounds {
            do {
                winningMap[round] = try await fetchWinning(round: round)
            } catch {
                // 특정 회차 실패해도 계속 진행
                continue
            }
        }

        var newResults: [(item: LottoNumber, winning: WinningNumber, result: CheckResult)] = []

        for item in items {
            guard let winning = winningMap[item.round] else { continue }
            let result = service.checkResult(myNumbers: item.numbers, winning: winning)

            // SwiftData 업데이트
            item.checkResult = result
            newResults.append((item: item, winning: winning, result: result))
        }

        try? context.save()
        results = newResults
        state = results.isEmpty ? .failure("확인할 번호가 없습니다") : .success(winningMap.values.first!)
    }

    // MARK: - 캐시 우선 패치
    private func fetchWinning(round: Int) async throws -> WinningNumber {
        if let cached = cache.get(round: round) { return cached }
        let winning = try await service.fetchWinningNumber(round: round)
        cache.set(winning)
        return winning
    }

    func reset() {
        state = .idle
        results = []
    }
}
