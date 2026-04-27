import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            GenerateView()
                .tabItem {
                    Image(systemName: "circle.hexagongrid.fill")
                    Text("생성")
                }

            MyNumbersView()
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("내 번호")
                }

            StatsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("통계")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
        }
        .tint(DesignSystem.gold)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
