import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @Binding var tabSelection: Int

    var body: some View {
        TabView(selection: $tabSelection) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            .accessibilityLabel("Home tab")

            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("History", systemImage: "clock.fill")
            }
            .tag(1)
            .accessibilityLabel("History tab")

            NavigationStack {
                GoalsTabView()
            }
            .tabItem {
                Label("Goals", systemImage: "target")
            }
            .tag(2)
            .accessibilityLabel("Goals tab")
        }
        .tint(Color.appAccent)
    }
}
