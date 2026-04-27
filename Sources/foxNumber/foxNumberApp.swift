import SwiftUI
import SwiftData

@main
struct foxNumberApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: LottoNumber.self)
    }
}
