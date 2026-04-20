import Combine
import Foundation

@MainActor
final class BudgetArchitectViewModel: ObservableObject {
    @Published var incomeText: String = ""
    @Published var needsText: String = "50"
    @Published var wantsText: String = "30"
    @Published var savingsText: String = "20"
    @Published var needsWarning: String?
    @Published var wantsWarning: String?
    @Published var savingsWarning: String?
    @Published var incomeWarning: String?
    @Published var livesRemaining: Int
    @Published var advancedUnlocked: Bool = false

    private var difficulty: FinanceDifficulty

    init(difficulty: FinanceDifficulty) {
        self.difficulty = difficulty
        livesRemaining = difficulty.budgetStartingLives
    }

    func reload(using difficulty: FinanceDifficulty) {
        self.difficulty = difficulty
        incomeText = ""
        needsText = "50"
        wantsText = "30"
        savingsText = "20"
        needsWarning = nil
        wantsWarning = nil
        savingsWarning = nil
        incomeWarning = nil
        livesRemaining = difficulty.budgetStartingLives
        advancedUnlocked = false
    }

    var allocationTotal: Double {
        (Double(needsText) ?? 0) + (Double(wantsText) ?? 0) + (Double(savingsText) ?? 0)
    }

    func handleIncomeEditingChanged(_ isEditing: Bool) {
        guard !isEditing else { return }
        validateIncome()
    }

    func handleNeedsEditingChanged(_ isEditing: Bool) {
        guard !isEditing else { return }
        validatePercent(text: needsText) { needsWarning = $0 }
        refreshAdvancedUnlock()
    }

    func handleWantsEditingChanged(_ isEditing: Bool) {
        guard !isEditing else { return }
        validatePercent(text: wantsText) { wantsWarning = $0 }
        refreshAdvancedUnlock()
    }

    func handleSavingsEditingChanged(_ isEditing: Bool) {
        guard !isEditing else { return }
        validatePercent(text: savingsText) { savingsWarning = $0 }
        refreshAdvancedUnlock()
    }

    private func validateIncome() {
        guard let value = Double(incomeText), value > 0 else {
            incomeWarning = "Enter a positive income amount"
            return
        }
        incomeWarning = nil
    }

    private func validatePercent(text: String, setWarning: (String?) -> Void) {
        guard let value = Double(text) else {
            setWarning("Use numbers only")
            return
        }
        if value < 0 || value > 100 {
            setWarning("Keep between 0 and 100")
        } else {
            setWarning(nil)
        }
    }

    private func refreshAdvancedUnlock() {
        let totalDeviation = abs(allocationTotal - 100)
        advancedUnlocked = totalDeviation <= difficulty.budgetDeviationTolerance
    }

    func submitAttempt() -> BudgetSubmitResult {
        validateIncome()
        validatePercent(text: needsText) { needsWarning = $0 }
        validatePercent(text: wantsText) { wantsWarning = $0 }
        validatePercent(text: savingsText) { savingsWarning = $0 }

        let income = Double(incomeText) ?? 0
        let needs = Double(needsText) ?? 0
        let wants = Double(wantsText) ?? 0
        let savings = Double(savingsText) ?? 0

        if incomeWarning != nil || needsWarning != nil || wantsWarning != nil || savingsWarning != nil {
            return loseLife(reason: "Fix highlighted fields before continuing")
        }

        if abs(allocationTotal - 100) > 0.01 {
            return loseLife(reason: "Allocations must total 100%")
        }

        let deviation = abs(needs - 50) + abs(wants - 30) + abs(savings - 20)
        let tolerance = difficulty.budgetDeviationTolerance
        let stars: Int
        if deviation <= tolerance {
            stars = 3
        } else if deviation <= tolerance * 2 {
            stars = 2
        } else if deviation <= tolerance * 3 {
            stars = 1
        } else {
            stars = 0
        }

        let payload = MonthlyBudgetPayload(income: income, needsPercent: needs, wantsPercent: wants, savingsPercent: savings)
        let savingsPortion = income * (savings / 100)
        return .success(stars: stars, payload: payload, savingsPortion: savingsPortion)
    }

    private func loseLife(reason: String) -> BudgetSubmitResult {
        if livesRemaining > 0 {
            livesRemaining -= 1
        }
        return .failure(message: reason)
    }
}

enum BudgetSubmitResult {
    case success(stars: Int, payload: MonthlyBudgetPayload, savingsPortion: Double)
    case failure(message: String)
}
