import Combine
import Foundation
import UIKit
import UserNotifications

@MainActor
final class FinanceDataManager: ObservableObject {
    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let monthlyBudget = "monthlyBudget"
        static let habitData = "habitData"
        static let goalTimeline = "goalTimeline"
        static let difficulty = "financeDifficulty"
        static let transactions = "financeTransactions"
        static let savingsGoals = "financeSavingsGoals"
        static let starsBudget = "starsBudgetArchitect"
        static let starsHabit = "starsHabitStreak"
        static let starsGoal = "starsGoalTimeframe"
        static let completedBudgetSessions = "completedBudgetSessions"
        static let completedHabitSessions = "completedHabitSessions"
        static let completedGoalSessions = "completedGoalSessions"
        static let achievementUnlocked = "achievementUnlocked"
        static let totalSavingsTracked = "totalSavingsTracked"
        static let habitStreakRecord = "habitStreakRecord"
        static let goalCompletionsTracked = "goalCompletionsTracked"
        static let moduleSavingsProgress = "moduleSavingsProgress"
        static let moduleExpenseProgress = "moduleExpenseProgress"
        static let moduleReportsProgress = "moduleReportsProgress"
        static let userLearningModules = "userLearningModules"
        static let categoryBudgets = "categoryBudgets"
        static let recurringExpenses = "recurringExpenses"
        static let notifyHabitsEnabled = "notifyHabitsEnabled"
        static let notifyBudgetEnabled = "notifyBudgetEnabled"
        static let notifyHour = "notifyHour"
        static let notifyMinute = "notifyMinute"
        static let appearanceMode = "appearanceMode"
        static let didApplyStarterSample = "didApplyStarterSample"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var monthlyBudget: MonthlyBudgetPayload?
    @Published private(set) var habitData: HabitPayload
    @Published private(set) var goalTimeline: GoalTimelinePayload
    @Published private(set) var difficulty: FinanceDifficulty
    @Published private(set) var transactions: [FinanceTransaction]
    @Published private(set) var savingsGoals: [FinanceSavingsGoal]
    @Published private(set) var bestStars: [FinanceActivityKind: Int]
    @Published private(set) var completedBudgetSessions: Int
    @Published private(set) var completedHabitSessions: Int
    @Published private(set) var completedGoalSessions: Int
    @Published private(set) var achievementUnlocked: Bool
    @Published private(set) var totalSavingsTracked: Double
    @Published private(set) var habitStreakRecord: Int
    @Published private(set) var goalCompletionsTracked: Int
    @Published private(set) var moduleSavingsProgress: Double
    @Published private(set) var moduleExpenseProgress: Double
    @Published private(set) var moduleReportsProgress: Double
    @Published private(set) var userLearningModules: [UserLearningModule]
    @Published private(set) var categoryBudgets: [CategoryBudgetLimit]
    @Published private(set) var recurringExpenses: [RecurringExpense]
    @Published private(set) var notificationsHabitsEnabled: Bool
    @Published private(set) var notificationsBudgetEnabled: Bool
    @Published private(set) var notificationHour: Int
    @Published private(set) var notificationMinute: Int
    @Published private(set) var appearanceMode: AppAppearanceMode

    init(userDefaults: UserDefaults = .standard) {
        defaults = userDefaults
        hasSeenOnboarding = userDefaults.bool(forKey: Keys.hasSeenOnboarding)
        monthlyBudget = Self.decode(MonthlyBudgetPayload.self, from: userDefaults.data(forKey: Keys.monthlyBudget), decoder: JSONDecoder())
        habitData = Self.decode(HabitPayload.self, from: userDefaults.data(forKey: Keys.habitData), decoder: JSONDecoder())
            ?? HabitPayload(currentStreak: 0, lastCompletedDay: nil, weekSlots: Array(repeating: false, count: 7))
        goalTimeline = Self.decode(GoalTimelinePayload.self, from: userDefaults.data(forKey: Keys.goalTimeline), decoder: JSONDecoder())
            ?? GoalTimelinePayload(markers: [0.25, 0.55, 0.82], pinchScale: 1)
        let diffRaw = userDefaults.string(forKey: Keys.difficulty)
        difficulty = FinanceDifficulty(rawValue: diffRaw ?? "") ?? .medium
        transactions = Self.decode([FinanceTransaction].self, from: userDefaults.data(forKey: Keys.transactions), decoder: JSONDecoder()) ?? []
        savingsGoals = Self.decode([FinanceSavingsGoal].self, from: userDefaults.data(forKey: Keys.savingsGoals), decoder: JSONDecoder()) ?? []
        userLearningModules = Self.decode([UserLearningModule].self, from: userDefaults.data(forKey: Keys.userLearningModules), decoder: JSONDecoder()) ?? []
        categoryBudgets = Self.decode([CategoryBudgetLimit].self, from: userDefaults.data(forKey: Keys.categoryBudgets), decoder: JSONDecoder()) ?? []
        recurringExpenses = Self.decode([RecurringExpense].self, from: userDefaults.data(forKey: Keys.recurringExpenses), decoder: JSONDecoder()) ?? []
        notificationsHabitsEnabled = userDefaults.bool(forKey: Keys.notifyHabitsEnabled)
        notificationsBudgetEnabled = userDefaults.bool(forKey: Keys.notifyBudgetEnabled)
        notificationHour = userDefaults.object(forKey: Keys.notifyHour) as? Int ?? 9
        notificationMinute = userDefaults.object(forKey: Keys.notifyMinute) as? Int ?? 0
        let appearanceRaw = userDefaults.string(forKey: Keys.appearanceMode) ?? AppAppearanceMode.system.rawValue
        appearanceMode = AppAppearanceMode(rawValue: appearanceRaw) ?? .system

        bestStars = [
            .budgetArchitect: userDefaults.integer(forKey: Keys.starsBudget),
            .habitStreak: userDefaults.integer(forKey: Keys.starsHabit),
            .goalTimeframe: userDefaults.integer(forKey: Keys.starsGoal)
        ]
        completedBudgetSessions = userDefaults.integer(forKey: Keys.completedBudgetSessions)
        completedHabitSessions = userDefaults.integer(forKey: Keys.completedHabitSessions)
        completedGoalSessions = userDefaults.integer(forKey: Keys.completedGoalSessions)
        achievementUnlocked = userDefaults.bool(forKey: Keys.achievementUnlocked)
        totalSavingsTracked = userDefaults.double(forKey: Keys.totalSavingsTracked)
        habitStreakRecord = userDefaults.integer(forKey: Keys.habitStreakRecord)
        goalCompletionsTracked = userDefaults.integer(forKey: Keys.goalCompletionsTracked)
        moduleSavingsProgress = userDefaults.double(forKey: Keys.moduleSavingsProgress)
        moduleExpenseProgress = userDefaults.double(forKey: Keys.moduleExpenseProgress)
        moduleReportsProgress = userDefaults.double(forKey: Keys.moduleReportsProgress)
        if moduleSavingsProgress == 0, moduleExpenseProgress == 0, moduleReportsProgress == 0 {
            moduleSavingsProgress = 0.12
            moduleExpenseProgress = 0.12
            moduleReportsProgress = 0.12
        }

        if hasSeenOnboarding {
            applyStarterSampleDataIfNeeded()
        }
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?, decoder: JSONDecoder) -> T? {
        guard let data else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    private func encode<T: Encodable>(_ value: T) -> Data? {
        try? encoder.encode(value)
    }

    var sortedUserLearningModules: [UserLearningModule] {
        userLearningModules.sorted { lhs, rhs in
            if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    func finishOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
        applyStarterSampleDataIfNeeded()
        objectWillChange.send()
    }

    /// One-time sample catalog so Goals, History, and caps are populated on first launch (or after an update if storage was still empty).
    private func applyStarterSampleDataIfNeeded() {
        guard !defaults.bool(forKey: Keys.didApplyStarterSample) else { return }
        guard savingsGoals.isEmpty,
              transactions.isEmpty,
              recurringExpenses.isEmpty,
              categoryBudgets.isEmpty,
              userLearningModules.isEmpty,
              monthlyBudget == nil
        else {
            defaults.set(true, forKey: Keys.didApplyStarterSample)
            return
        }

        let cal = Calendar.current
        let now = Date()
        let noon: (Int) -> Date = { dayOffset in
            let base = cal.date(byAdding: .day, value: -dayOffset, to: now) ?? now
            return cal.date(bySettingHour: 12, minute: 0, second: 0, of: base) ?? base
        }

        let emergencyDeadline = cal.date(byAdding: .month, value: 8, to: now) ?? now
        let vacationDeadline = cal.date(byAdding: .month, value: 14, to: now) ?? now

        let milestoneEmergency1 = GoalMilestone(id: UUID(), title: "Starter buffer", thresholdAmount: 1_200, isComplete: true)
        let milestoneEmergency2 = GoalMilestone(id: UUID(), title: "Mid checkpoint", thresholdAmount: 4_000, isComplete: false)
        let goalEmergency = FinanceSavingsGoal(
            id: UUID(),
            title: "Emergency fund",
            targetAmount: 8_000,
            currentAmount: 2_350,
            deadline: emergencyDeadline,
            milestones: [milestoneEmergency1, milestoneEmergency2]
        )
        let goalVacation = FinanceSavingsGoal(
            id: UUID(),
            title: "Summer trip",
            targetAmount: 3_200,
            currentAmount: 640,
            deadline: vacationDeadline,
            milestones: [
                GoalMilestone(id: UUID(), title: "Flights reserved", thresholdAmount: 1_600, isComplete: false)
            ]
        )
        replaceSavingsGoals([goalEmergency, goalVacation])

        let sampleTx: [FinanceTransaction] = [
            FinanceTransaction(id: UUID(), title: "Weekly groceries", amount: 118.40, category: "Groceries", date: noon(0)),
            FinanceTransaction(id: UUID(), title: "Coffee & bakery", amount: 14.50, category: "Dining", date: noon(0)),
            FinanceTransaction(id: UUID(), title: "Transit pass", amount: 35, category: "Transport", date: noon(1)),
            FinanceTransaction(id: UUID(), title: "Pharmacy", amount: 42.80, category: "Health", date: noon(2)),
            FinanceTransaction(id: UUID(), title: "Dinner out", amount: 68.20, category: "Dining", date: noon(3)),
            FinanceTransaction(id: UUID(), title: "Farmers market", amount: 52.10, category: "Groceries", date: noon(4)),
            FinanceTransaction(id: UUID(), title: "Gas", amount: 48.90, category: "Transport", date: noon(5)),
            FinanceTransaction(id: UUID(), title: "Streaming", amount: 16.99, category: "Subscriptions", date: noon(6)),
            FinanceTransaction(id: UUID(), title: "Electric bill", amount: 92.40, category: "Utilities", date: noon(8)),
            FinanceTransaction(id: UUID(), title: "Yoga class", amount: 22, category: "Health", date: noon(11)),
            FinanceTransaction(id: UUID(), title: "Bookstore", amount: 31.50, category: "Shopping", date: noon(14)),
            FinanceTransaction(id: UUID(), title: "Brunch", amount: 56, category: "Dining", date: noon(18))
        ].sorted { $0.date > $1.date }

        replaceTransactions(sampleTx)

        let nextRent = cal.date(byAdding: .day, value: 18, to: cal.startOfDay(for: now)) ?? now
        let recurringItems: [RecurringExpense] = [
            RecurringExpense(
                id: UUID(),
                title: "Rent",
                amount: 1_450,
                category: "Housing",
                intervalMonths: 1,
                nextDueDate: nextRent
            ),
            RecurringExpense(
                id: UUID(),
                title: "Gym membership",
                amount: 49.99,
                category: "Health",
                intervalMonths: 1,
                nextDueDate: cal.date(byAdding: .day, value: 12, to: now) ?? now
            )
        ]
        replaceRecurringExpenses(recurringItems)

        let caps: [CategoryBudgetLimit] = [
            CategoryBudgetLimit(id: UUID(), categoryName: "Groceries", monthlyLimit: 520),
            CategoryBudgetLimit(id: UUID(), categoryName: "Dining", monthlyLimit: 280),
            CategoryBudgetLimit(id: UUID(), categoryName: "Transport", monthlyLimit: 200)
        ]
        replaceCategoryBudgets(caps)

        persistMonthlyBudget(MonthlyBudgetPayload(income: 5_800, needsPercent: 52, wantsPercent: 23, savingsPercent: 25))

        let streakSlots: [Bool] = [true, true, false, true, true, false, true]
        persistHabitData(
            HabitPayload(
                currentStreak: 4,
                lastCompletedDay: cal.startOfDay(for: now),
                weekSlots: streakSlots,
                habitNames: HabitPayload.defaultHabitNames
            )
        )

        habitStreakRecord = max(habitStreakRecord, 4)
        defaults.set(habitStreakRecord, forKey: Keys.habitStreakRecord)
        totalSavingsTracked = max(totalSavingsTracked, goalEmergency.currentAmount + goalVacation.currentAmount)
        defaults.set(totalSavingsTracked, forKey: Keys.totalSavingsTracked)
        goalCompletionsTracked = max(goalCompletionsTracked, 1)
        defaults.set(goalCompletionsTracked, forKey: Keys.goalCompletionsTracked)

        addUserModule(
            title: "Debt snowball",
            detail: "Tackle balances smallest to largest with steady payments.",
            linkedActivity: .goalTimeframe,
            tag: "Finance"
        )
        addUserModule(
            title: "Weekly money date",
            detail: "Ten minutes every Sunday to review caps and habits.",
            linkedActivity: .habitStreak,
            tag: "Routine"
        )

        defaults.set(true, forKey: Keys.didApplyStarterSample)
        objectWillChange.send()
    }

    func setDifficulty(_ value: FinanceDifficulty) {
        difficulty = value
        defaults.set(value.rawValue, forKey: Keys.difficulty)
        objectWillChange.send()
    }

    func setAppearanceMode(_ value: AppAppearanceMode) {
        appearanceMode = value
        defaults.set(value.rawValue, forKey: Keys.appearanceMode)
        NotificationCenter.default.post(name: .financeAppearanceChanged, object: nil)
        objectWillChange.send()
    }

    func setNotificationPreferences(habits: Bool, budget: Bool, hour: Int, minute: Int) {
        notificationsHabitsEnabled = habits
        notificationsBudgetEnabled = budget
        notificationHour = max(0, min(23, hour))
        notificationMinute = max(0, min(59, minute))
        defaults.set(habits, forKey: Keys.notifyHabitsEnabled)
        defaults.set(budget, forKey: Keys.notifyBudgetEnabled)
        defaults.set(notificationHour, forKey: Keys.notifyHour)
        defaults.set(notificationMinute, forKey: Keys.notifyMinute)
        FinanceNotificationScheduler.reschedule(
            habitsEnabled: habits,
            budgetEnabled: budget,
            hour: notificationHour,
            minute: notificationMinute
        )
        objectWillChange.send()
    }

    func refreshNotificationScheduleFromStoredPrefs() {
        FinanceNotificationScheduler.reschedule(
            habitsEnabled: notificationsHabitsEnabled,
            budgetEnabled: notificationsBudgetEnabled,
            hour: notificationHour,
            minute: notificationMinute
        )
    }

    func spendInMonth(containing date: Date, category: String?) -> Double {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .month, for: date) else { return 0 }
        return transactions
            .filter { tx in
                guard tx.date >= interval.start && tx.date < interval.end else { return false }
                if let category, !category.isEmpty {
                    return tx.category.caseInsensitiveCompare(category) == .orderedSame
                }
                return true
            }
            .reduce(0) { $0 + $1.amount }
    }

    func spendThisMonth(category: String) -> Double {
        spendInMonth(containing: Date(), category: category)
    }

    func totalSpendThisMonth() -> Double {
        spendInMonth(containing: Date(), category: nil)
    }

    func totalSpendPreviousMonth() -> Double {
        let cal = Calendar.current
        let prior = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return spendInMonth(containing: prior, category: nil)
    }

    func categoryBudgetAlerts() -> [(category: String, spent: Double, limit: Double, overBudget: Bool, nearLimit: Bool)] {
        categoryBudgets.map { limit in
            let spent = spendThisMonth(category: limit.categoryName)
            let ratio = limit.monthlyLimit > 0 ? spent / limit.monthlyLimit : 0
            let overBudget = spent > limit.monthlyLimit
            let nearLimit = !overBudget && ratio >= 0.85
            return (limit.categoryName, spent, limit.monthlyLimit, overBudget, nearLimit)
        }
    }

    func replaceCategoryBudgets(_ items: [CategoryBudgetLimit]) {
        categoryBudgets = items
        if let data = encode(categoryBudgets) {
            defaults.set(data, forKey: Keys.categoryBudgets)
        }
        objectWillChange.send()
    }

    func addCategoryBudget(categoryName: String, monthlyLimit: Double) {
        let trimmed = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, monthlyLimit > 0 else { return }
        var next = categoryBudgets
        next.append(CategoryBudgetLimit(id: UUID(), categoryName: trimmed, monthlyLimit: monthlyLimit))
        replaceCategoryBudgets(next)
    }

    func removeCategoryBudget(id: UUID) {
        replaceCategoryBudgets(categoryBudgets.filter { $0.id != id })
    }

    func replaceRecurringExpenses(_ items: [RecurringExpense]) {
        recurringExpenses = items
        if let data = encode(recurringExpenses) {
            defaults.set(data, forKey: Keys.recurringExpenses)
        }
        objectWillChange.send()
    }

    func addRecurringExpense(title: String, amount: Double, category: String, intervalMonths: Int, nextDue: Date) {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, amount > 0, intervalMonths > 0 else { return }
        var next = recurringExpenses
        next.append(RecurringExpense(id: UUID(), title: t, amount: amount, category: category, intervalMonths: intervalMonths, nextDueDate: nextDue))
        replaceRecurringExpenses(next)
    }

    func removeRecurringExpense(id: UUID) {
        replaceRecurringExpenses(recurringExpenses.filter { $0.id != id })
    }

    func recordRecurringPayment(id: UUID) {
        guard let index = recurringExpenses.firstIndex(where: { $0.id == id }) else { return }
        var item = recurringExpenses[index]
        let tx = FinanceTransaction(
            id: UUID(),
            title: item.title,
            amount: item.amount,
            category: item.category,
            date: Date()
        )
        addTransaction(tx)
        let cal = Calendar.current
        if let advanced = cal.date(byAdding: .month, value: item.intervalMonths, to: item.nextDueDate) {
            item.nextDueDate = advanced
        }
        recurringExpenses[index] = item
        replaceRecurringExpenses(recurringExpenses)
    }

    func updateHabitNames(_ names: [String]) {
        let trimmed = names.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let valid = trimmed.allSatisfy({ !$0.isEmpty }) && trimmed.count == 3
        let nextNames = valid ? trimmed : HabitPayload.defaultHabitNames
        habitData = HabitPayload(
            currentStreak: habitData.currentStreak,
            lastCompletedDay: habitData.lastCompletedDay,
            weekSlots: habitData.weekSlots,
            habitNames: nextNames
        )
        persistHabitData(habitData)
    }

    func replaceGoal(_ goal: FinanceSavingsGoal) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        var next = savingsGoals
        next[index] = goal
        replaceSavingsGoals(next)
    }

    func toggleGoalMilestone(goalId: UUID, milestoneId: UUID) {
        guard let gIndex = savingsGoals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = savingsGoals[gIndex]
        guard let mIndex = goal.milestones.firstIndex(where: { $0.id == milestoneId }) else { return }
        goal.milestones[mIndex].isComplete.toggle()
        replaceGoal(goal)
    }

    func setGoalMilestoneComplete(goalId: UUID, milestoneId: UUID, isComplete: Bool) {
        guard let gIndex = savingsGoals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = savingsGoals[gIndex]
        guard let mIndex = goal.milestones.firstIndex(where: { $0.id == milestoneId }) else { return }
        goal.milestones[mIndex].isComplete = isComplete
        replaceGoal(goal)
    }

    func addGoalMilestone(goalId: UUID, title: String, thresholdAmount: Double) {
        guard let gIndex = savingsGoals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = savingsGoals[gIndex]
        let capped = min(goal.targetAmount, max(0, thresholdAmount))
        let milestone = GoalMilestone(id: UUID(), title: title.isEmpty ? "Checkpoint" : title, thresholdAmount: capped, isComplete: false)
        goal.milestones.append(milestone)
        replaceGoal(goal)
    }

    func removeGoalMilestone(goalId: UUID, milestoneId: UUID) {
        guard let gIndex = savingsGoals.firstIndex(where: { $0.id == goalId }) else { return }
        var goal = savingsGoals[gIndex]
        goal.milestones.removeAll { $0.id == milestoneId }
        replaceGoal(goal)
    }

    func exportCSVString() -> String {
        FinanceExportBuilder.csvString(transactions: transactions, recurring: recurringExpenses, categoryBudgets: categoryBudgets)
    }

    func exportPDFData() -> Data? {
        FinanceExportBuilder.pdfReportData(
            transactions: transactions,
            thisMonthSpend: totalSpendThisMonth(),
            lastMonthSpend: totalSpendPreviousMonth(),
            habitStreak: habitStreakRecord,
            totalStars: totalEarnedStars()
        )
    }

    func persistMonthlyBudget(_ payload: MonthlyBudgetPayload) {
        monthlyBudget = payload
        if let data = encode(payload) {
            defaults.set(data, forKey: Keys.monthlyBudget)
        }
        objectWillChange.send()
    }

    func persistHabitData(_ payload: HabitPayload) {
        habitData = payload
        if let data = encode(payload) {
            defaults.set(data, forKey: Keys.habitData)
        }
        objectWillChange.send()
    }

    func persistGoalTimeline(_ payload: GoalTimelinePayload) {
        goalTimeline = payload
        if let data = encode(payload) {
            defaults.set(data, forKey: Keys.goalTimeline)
        }
        objectWillChange.send()
    }

    func addTransaction(_ item: FinanceTransaction) {
        transactions.insert(item, at: 0)
        persistTransactions()
    }

    func removeTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }
        persistTransactions()
    }

    func replaceTransactions(_ items: [FinanceTransaction]) {
        transactions = items
        persistTransactions()
    }

    private func persistTransactions() {
        if let data = encode(transactions) {
            defaults.set(data, forKey: Keys.transactions)
        }
        objectWillChange.send()
    }

    func replaceSavingsGoals(_ items: [FinanceSavingsGoal]) {
        savingsGoals = items
        if let data = encode(savingsGoals) {
            defaults.set(data, forKey: Keys.savingsGoals)
        }
        objectWillChange.send()
    }

    func appendSavingsGoal(_ goal: FinanceSavingsGoal) {
        savingsGoals.append(goal)
        if let data = encode(savingsGoals) {
            defaults.set(data, forKey: Keys.savingsGoals)
        }
        objectWillChange.send()
    }

    func updateSavingsGoal(id: UUID, currentAmount: Double) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == id }) else { return }
        savingsGoals[index].currentAmount = min(savingsGoals[index].targetAmount, max(0, currentAmount))
        replaceSavingsGoals(savingsGoals)
    }

    func registerBudgetSession(stars: Int, payload: MonthlyBudgetPayload, savingsPortion: Double) {
        persistMonthlyBudget(payload)
        completedBudgetSessions += 1
        defaults.set(completedBudgetSessions, forKey: Keys.completedBudgetSessions)
        mergeStars(activity: .budgetArchitect, stars: stars)
        totalSavingsTracked += max(0, savingsPortion)
        defaults.set(totalSavingsTracked, forKey: Keys.totalSavingsTracked)
        moduleExpenseProgress = min(1, moduleExpenseProgress + Double(stars) * 0.08)
        defaults.set(moduleExpenseProgress, forKey: Keys.moduleExpenseProgress)
        refreshAchievementState()
        objectWillChange.send()
    }

    func registerHabitSession(stars: Int, streak: Int, payload: HabitPayload) {
        persistHabitData(payload)
        completedHabitSessions += 1
        defaults.set(completedHabitSessions, forKey: Keys.completedHabitSessions)
        mergeStars(activity: .habitStreak, stars: stars)
        habitStreakRecord = max(habitStreakRecord, streak)
        defaults.set(habitStreakRecord, forKey: Keys.habitStreakRecord)
        moduleReportsProgress = min(1, moduleReportsProgress + Double(stars) * 0.07)
        defaults.set(moduleReportsProgress, forKey: Keys.moduleReportsProgress)
        refreshAchievementState()
        objectWillChange.send()
    }

    func registerGoalSession(stars: Int, payload: GoalTimelinePayload, metTargets: Int) {
        persistGoalTimeline(payload)
        completedGoalSessions += 1
        defaults.set(completedGoalSessions, forKey: Keys.completedGoalSessions)
        mergeStars(activity: .goalTimeframe, stars: stars)
        goalCompletionsTracked += metTargets
        defaults.set(goalCompletionsTracked, forKey: Keys.goalCompletionsTracked)
        moduleSavingsProgress = min(1, moduleSavingsProgress + Double(stars) * 0.09)
        defaults.set(moduleSavingsProgress, forKey: Keys.moduleSavingsProgress)
        refreshAchievementState()
        objectWillChange.send()
    }

    private func mergeStars(activity: FinanceActivityKind, stars: Int) {
        let capped = min(3, max(0, stars))
        let previous = bestStars[activity] ?? 0
        let merged = max(previous, capped)
        var next = bestStars
        next[activity] = merged
        bestStars = next
        switch activity {
        case .budgetArchitect:
            defaults.set(merged, forKey: Keys.starsBudget)
        case .habitStreak:
            defaults.set(merged, forKey: Keys.starsHabit)
        case .goalTimeframe:
            defaults.set(merged, forKey: Keys.starsGoal)
        }
    }

    private func refreshAchievementState() {
        let total = (bestStars[.budgetArchitect] ?? 0) + (bestStars[.habitStreak] ?? 0) + (bestStars[.goalTimeframe] ?? 0)
        let sessions = completedBudgetSessions + completedHabitSessions + completedGoalSessions
        let shouldUnlock = total >= 6 || sessions >= 6
        if shouldUnlock {
            achievementUnlocked = true
            defaults.set(true, forKey: Keys.achievementUnlocked)
        }
    }

    func isActivityUnlocked(_ activity: FinanceActivityKind) -> Bool {
        switch activity {
        case .budgetArchitect:
            return true
        case .habitStreak:
            return completedBudgetSessions > 0
        case .goalTimeframe:
            return completedHabitSessions > 0
        }
    }

    func totalEarnedStars() -> Int {
        (bestStars[.budgetArchitect] ?? 0) + (bestStars[.habitStreak] ?? 0) + (bestStars[.goalTimeframe] ?? 0)
    }

    func stars(for activity: FinanceActivityKind) -> Int {
        bestStars[activity] ?? 0
    }

    func moduleProgress(for activity: FinanceActivityKind) -> Double {
        switch activity {
        case .goalTimeframe:
            return moduleSavingsProgress
        case .budgetArchitect:
            return moduleExpenseProgress
        case .habitStreak:
            return moduleReportsProgress
        }
    }

    func combinedModuleProgress(_ module: UserLearningModule) -> Double {
        min(1, max(moduleProgress(for: module.linkedActivity), module.independentProgress))
    }

    func addUserModule(title: String, detail: String, linkedActivity: FinanceActivityKind, tag: String = "General") {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetail = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let nextOrder = (userLearningModules.map(\.sortOrder).max() ?? -1) + 1
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "General" : tag.trimmingCharacters(in: .whitespacesAndNewlines)
        let module = UserLearningModule(
            id: UUID(),
            title: trimmedTitle,
            detail: trimmedDetail.isEmpty ? "Custom learning path" : trimmedDetail,
            linkedActivity: linkedActivity,
            independentProgress: 0,
            tag: trimmedTag,
            sortOrder: nextOrder
        )
        userLearningModules.append(module)
        persistUserLearningModules()
    }

    func removeUserModule(id: UUID) {
        userLearningModules.removeAll { $0.id == id }
        renumberUserModuleSortOrders()
        persistUserLearningModules()
    }

    func updateUserModule(_ module: UserLearningModule) {
        guard let index = userLearningModules.firstIndex(where: { $0.id == module.id }) else { return }
        userLearningModules[index] = module
        persistUserLearningModules()
    }

    func moveUserModules(from source: IndexSet, to destination: Int) {
        var sorted = sortedUserLearningModules
        Self.financeMoveElements(in: &sorted, fromOffsets: source, toOffset: destination)
        userLearningModules = sorted.enumerated().map { index, module in
            var m = module
            m.sortOrder = index
            return m
        }
        persistUserLearningModules()
    }

    /// Same semantics as SwiftUI `move(fromOffsets:toOffset:)` without importing SwiftUI.
    private static func financeMoveElements(in array: inout [UserLearningModule], fromOffsets source: IndexSet, toOffset destination: Int) {
        guard !source.isEmpty, destination >= 0, destination <= array.count else { return }
        let ascending = source.sorted()
        var moved: [UserLearningModule] = []
        moved.reserveCapacity(ascending.count)
        for index in ascending {
            moved.append(array[index])
        }
        for index in ascending.reversed() {
            array.remove(at: index)
        }
        var insertAt = destination
        for index in ascending where index < destination {
            insertAt -= 1
        }
        insertAt = max(0, min(insertAt, array.count))
        array.insert(contentsOf: moved, at: insertAt)
    }

    private func renumberUserModuleSortOrders() {
        userLearningModules = userLearningModules.enumerated().map { index, m in
            var x = m
            x.sortOrder = index
            return x
        }
    }

    private func persistUserLearningModules() {
        if let data = encode(userLearningModules) {
            defaults.set(data, forKey: Keys.userLearningModules)
        }
        objectWillChange.send()
    }

    func resetAll() {
        let domain = Bundle.main.bundleIdentifier
        if let domain {
            defaults.removePersistentDomain(forName: domain)
        }
        FinanceNotificationScheduler.cancelAll()
        hasSeenOnboarding = false
        monthlyBudget = nil
        habitData = HabitPayload(currentStreak: 0, lastCompletedDay: nil, weekSlots: Array(repeating: false, count: 7))
        goalTimeline = GoalTimelinePayload(markers: [0.25, 0.55, 0.82], pinchScale: 1)
        difficulty = .medium
        transactions = []
        savingsGoals = []
        bestStars = [.budgetArchitect: 0, .habitStreak: 0, .goalTimeframe: 0]
        completedBudgetSessions = 0
        completedHabitSessions = 0
        completedGoalSessions = 0
        achievementUnlocked = false
        totalSavingsTracked = 0
        habitStreakRecord = 0
        goalCompletionsTracked = 0
        moduleSavingsProgress = 0.12
        moduleExpenseProgress = 0.12
        moduleReportsProgress = 0.12
        userLearningModules = []
        categoryBudgets = []
        recurringExpenses = []
        notificationsHabitsEnabled = false
        notificationsBudgetEnabled = false
        notificationHour = 9
        notificationMinute = 0
        appearanceMode = .system
        defaults.set(false, forKey: Keys.hasSeenOnboarding)
        defaults.set(FinanceDifficulty.medium.rawValue, forKey: Keys.difficulty)
        defaults.set(0, forKey: Keys.starsBudget)
        defaults.set(0, forKey: Keys.starsHabit)
        defaults.set(0, forKey: Keys.starsGoal)
        defaults.set(0, forKey: Keys.completedBudgetSessions)
        defaults.set(0, forKey: Keys.completedHabitSessions)
        defaults.set(0, forKey: Keys.completedGoalSessions)
        defaults.set(false, forKey: Keys.achievementUnlocked)
        defaults.set(0, forKey: Keys.totalSavingsTracked)
        defaults.set(0, forKey: Keys.habitStreakRecord)
        defaults.set(0, forKey: Keys.goalCompletionsTracked)
        defaults.set(moduleSavingsProgress, forKey: Keys.moduleSavingsProgress)
        defaults.set(moduleExpenseProgress, forKey: Keys.moduleExpenseProgress)
        defaults.set(moduleReportsProgress, forKey: Keys.moduleReportsProgress)
        defaults.removeObject(forKey: Keys.monthlyBudget)
        defaults.removeObject(forKey: Keys.habitData)
        defaults.removeObject(forKey: Keys.goalTimeline)
        defaults.removeObject(forKey: Keys.transactions)
        defaults.removeObject(forKey: Keys.savingsGoals)
        defaults.removeObject(forKey: Keys.userLearningModules)
        defaults.removeObject(forKey: Keys.categoryBudgets)
        defaults.removeObject(forKey: Keys.recurringExpenses)
        defaults.removeObject(forKey: Keys.notifyHabitsEnabled)
        defaults.removeObject(forKey: Keys.notifyBudgetEnabled)
        defaults.removeObject(forKey: Keys.notifyHour)
        defaults.removeObject(forKey: Keys.notifyMinute)
        defaults.removeObject(forKey: Keys.appearanceMode)
        NotificationCenter.default.post(name: .financeDataDidReset, object: nil)
        objectWillChange.send()
    }
}

// MARK: - Local notification scheduling

@MainActor
enum FinanceNotificationScheduler {
    private static let habitId = "finance.habit.reminder"
    private static let budgetId = "finance.budget.reminder"

    static func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                DispatchQueue.main.async { completion(settings.authorizationStatus == .authorized) }
                return
            }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                DispatchQueue.main.async { completion(granted) }
            }
        }
    }

    static func reschedule(habitsEnabled: Bool, budgetEnabled: Bool, hour: Int, minute: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [habitId, budgetId])

        if habitsEnabled {
            var daily = DateComponents()
            daily.hour = hour
            daily.minute = minute
            let content = UNMutableNotificationContent()
            content.title = "Habit check-in"
            content.body = "Log today’s financial habits to keep your streak."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: daily, repeats: true)
            let request = UNNotificationRequest(identifier: habitId, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }

        if budgetEnabled {
            var monthly = DateComponents()
            monthly.day = 1
            monthly.hour = hour
            monthly.minute = min(59, minute + 5)
            let content = UNMutableNotificationContent()
            content.title = "Budget review"
            content.body = "Review spending against your category limits."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: monthly, repeats: true)
            let request = UNNotificationRequest(identifier: budgetId, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}

// MARK: - CSV / PDF export

enum FinanceExportBuilder {
    static func csvString(transactions: [FinanceTransaction], recurring: [RecurringExpense], categoryBudgets: [CategoryBudgetLimit]) -> String {
        var lines: [String] = ["Transactions", "date,title,amount,category"]
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        for t in transactions.sorted(by: { $0.date > $1.date }) {
            let row = "\(formatter.string(from: t.date)),\"\(t.title.replacingOccurrences(of: "\"", with: "'"))\",\(t.amount),\(t.category)"
            lines.append(row)
        }
        lines.append("")
        lines.append("Recurring")
        lines.append("title,amount,category,intervalMonths,nextDueDate")
        for r in recurring {
            lines.append("\"\(r.title)\",\(r.amount),\(r.category),\(r.intervalMonths),\(formatter.string(from: r.nextDueDate))")
        }
        lines.append("")
        lines.append("Category limits")
        lines.append("category,monthlyLimit")
        for c in categoryBudgets {
            lines.append("\(c.categoryName),\(c.monthlyLimit)")
        }
        return lines.joined(separator: "\n")
    }

    static func pdfReportData(
        transactions: [FinanceTransaction],
        thisMonthSpend: Double,
        lastMonthSpend: Double,
        habitStreak: Int,
        totalStars: Int
    ) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            context.beginPage()
            let title = "Finance summary"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .title1),
                .foregroundColor: UIColor.label
            ]
            (title as NSString).draw(at: CGPoint(x: 40, y: 40), withAttributes: attrs)

            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label
            ]
            let lines = [
                "This month spending: \(Self.currency(thisMonthSpend))",
                "Last month spending: \(Self.currency(lastMonthSpend))",
                "Best habit streak: \(habitStreak) days",
                "Total stars: \(totalStars)",
                "Transaction count: \(transactions.count)"
            ]
            var y: CGFloat = 100
            for line in lines {
                (line as NSString).draw(at: CGPoint(x: 40, y: y), withAttributes: bodyAttrs)
                y += 28
            }
        }
    }

    private static func currency(_ value: Double) -> String {
        value.formatted(.currency(code: "USD"))
    }
}
