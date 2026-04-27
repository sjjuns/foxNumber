import SwiftUI
import SwiftData

@Observable
final class GenerateViewModel {

    var generatedSets: [[Int]] = []
    var gameCount: Int = 1
    var isAnimating: Bool = false
    var visibleBalls: [Int: Set<Int>] = [:]   // [setIndex: visibleNumbers]

    private let service = LottoService.shared

    var currentRound: Int { service.currentRound() }
    var daysUntilDraw: Int { service.daysUntilDraw() }
    var nextDrawDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter.string(from: service.nextDrawDate())
    }

    // MARK: - 번호 생성 + 애니메이션
    @MainActor
    func generate() async {
        guard !isAnimating else { return }
        isAnimating = true
        visibleBalls = [:]

        let newSets = service.generateNumbers(count: gameCount)
        generatedSets = newSets

        // 볼이 하나씩 등장하는 애니메이션
        for setIndex in 0..<newSets.count {
            for (ballIndex, number) in newSets[setIndex].enumerated() {
                try? await Task.sleep(nanoseconds: 120_000_000) // 0.12초
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if visibleBalls[setIndex] == nil {
                        visibleBalls[setIndex] = []
                    }
                    visibleBalls[setIndex]?.insert(number)
                }
                _ = ballIndex
            }
        }

        isAnimating = false
    }

    func isBallVisible(setIndex: Int, number: Int) -> Bool {
        visibleBalls[setIndex]?.contains(number) ?? false
    }

    // MARK: - 저장
    func save(context: ModelContext) {
        guard !generatedSets.isEmpty else { return }
        for numbers in generatedSets {
            let item = LottoNumber(numbers: numbers, round: currentRound)
            context.insert(item)
        }
        try? context.save()
    }
}
