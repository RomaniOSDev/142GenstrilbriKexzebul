import SwiftUI

struct ContentView: View {
    @StateObject private var data = FinanceDataManager()
    @State private var tabSelection = 0

    private var preferredColorScheme: ColorScheme? {
        switch data.appearanceMode {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var body: some View {
        Group {
            if data.hasSeenOnboarding {
                MainTabView(tabSelection: $tabSelection)
            } else {
                OnboardingFlowView()
            }
        }
        .appChromeBackground()
        .environmentObject(data)
        .preferredColorScheme(preferredColorScheme)
        .dynamicTypeSize(.xSmall ... .accessibility5)
        .onAppear {
            data.refreshNotificationScheduleFromStoredPrefs()
            FinanceNotificationScheduler.requestAuthorizationIfNeeded { _ in }
        }
        .onReceive(NotificationCenter.default.publisher(for: .financeQuickAction)) { output in
            guard let raw = output.object as? String,
                  let kind = FinanceQuickActionKind(rawValue: raw) else { return }
            switch kind {
            case .openBudget:
                tabSelection = 0
            case .openHistoryAdd:
                tabSelection = 1
            case .openGoals:
                tabSelection = 2
            }
        }
    }
}

#Preview {
    ContentView()
}
