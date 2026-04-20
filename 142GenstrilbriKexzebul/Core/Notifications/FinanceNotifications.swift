import Foundation

extension Notification.Name {
    static let financeDataDidReset = Notification.Name("financeDataDidReset")
    static let financeQuickAction = Notification.Name("financeQuickAction")
    static let financeAppearanceChanged = Notification.Name("financeAppearanceChanged")
}

enum FinanceQuickActionKind: String {
    case openBudget = "com.finance.quick.openBudget"
    case openHistoryAdd = "com.finance.quick.openHistory"
    case openGoals = "com.finance.quick.openGoals"
}
