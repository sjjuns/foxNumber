import Foundation

/// 동행복권 API 응답을 로컬에 캐싱 — 불필요한 네트워크 요청 방지
final class WinningNumberCache {

    static let shared = WinningNumberCache()
    private init() {}

    private var cache: [Int: WinningNumber] = [:]

    func get(round: Int) -> WinningNumber? {
        cache[round]
    }

    func set(_ winning: WinningNumber) {
        cache[winning.round] = winning
    }

    func clear() {
        cache.removeAll()
    }
}
