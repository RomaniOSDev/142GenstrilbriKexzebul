import Foundation

enum FinanceDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }

    var budgetDeviationTolerance: Double {
        switch self {
        case .easy: return 15
        case .medium: return 10
        case .hard: return 5
        }
    }

    var budgetStartingLives: Int {
        switch self {
        case .easy: return 5
        case .medium: return 3
        case .hard: return 2
        }
    }

    var habitStreakForThreeStars: Int {
        switch self {
        case .easy: return 3
        case .medium: return 5
        case .hard: return 7
        }
    }

    var goalMarkerTolerance: Double {
        switch self {
        case .easy: return 0.12
        case .medium: return 0.08
        case .hard: return 0.05
        }
    }
}

struct MonthlyBudgetPayload: Codable, Equatable {
    var income: Double
    var needsPercent: Double
    var wantsPercent: Double
    var savingsPercent: Double
}

struct HabitPayload: Codable, Equatable {
    var currentStreak: Int
    var lastCompletedDay: Date?
    var weekSlots: [Bool]
    var habitNames: [String]

    static let defaultHabitNames = ["Review spending", "Plan transfers", "Scan subscriptions"]

    enum CodingKeys: String, CodingKey {
        case currentStreak, lastCompletedDay, weekSlots, habitNames
    }

    init(currentStreak: Int, lastCompletedDay: Date?, weekSlots: [Bool], habitNames: [String] = HabitPayload.defaultHabitNames) {
        self.currentStreak = currentStreak
        self.lastCompletedDay = lastCompletedDay
        self.weekSlots = weekSlots
        self.habitNames = habitNames.count == 3 ? habitNames : HabitPayload.defaultHabitNames
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentStreak = try c.decode(Int.self, forKey: .currentStreak)
        lastCompletedDay = try c.decodeIfPresent(Date.self, forKey: .lastCompletedDay)
        weekSlots = try c.decodeIfPresent([Bool].self, forKey: .weekSlots) ?? Array(repeating: false, count: 7)
        let names = try c.decodeIfPresent([String].self, forKey: .habitNames) ?? HabitPayload.defaultHabitNames
        habitNames = names.count == 3 ? names : HabitPayload.defaultHabitNames
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(currentStreak, forKey: .currentStreak)
        try c.encodeIfPresent(lastCompletedDay, forKey: .lastCompletedDay)
        try c.encode(weekSlots, forKey: .weekSlots)
        try c.encode(habitNames, forKey: .habitNames)
    }
}

struct GoalTimelinePayload: Codable, Equatable {
    var markers: [Double]
    var pinchScale: Double
}

struct FinanceTransaction: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var category: String
    var date: Date
}

struct GoalMilestone: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var thresholdAmount: Double
    var isComplete: Bool
}

struct FinanceSavingsGoal: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date
    var milestones: [GoalMilestone]

    enum CodingKeys: String, CodingKey {
        case id, title, targetAmount, currentAmount, deadline, milestones
    }

    init(id: UUID, title: String, targetAmount: Double, currentAmount: Double, deadline: Date, milestones: [GoalMilestone] = []) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.milestones = milestones
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        targetAmount = try c.decode(Double.self, forKey: .targetAmount)
        currentAmount = try c.decode(Double.self, forKey: .currentAmount)
        deadline = try c.decode(Date.self, forKey: .deadline)
        milestones = try c.decodeIfPresent([GoalMilestone].self, forKey: .milestones) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(targetAmount, forKey: .targetAmount)
        try c.encode(currentAmount, forKey: .currentAmount)
        try c.encode(deadline, forKey: .deadline)
        try c.encode(milestones, forKey: .milestones)
    }
}

struct CategoryBudgetLimit: Codable, Identifiable, Equatable {
    var id: UUID
    var categoryName: String
    var monthlyLimit: Double
}

struct RecurringExpense: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var amount: Double
    var category: String
    var intervalMonths: Int
    var nextDueDate: Date
}

enum FinanceActivityKind: String, CaseIterable, Identifiable, Hashable, Codable {
    case budgetArchitect
    case habitStreak
    case goalTimeframe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .budgetArchitect: return "Budget Architect"
        case .habitStreak: return "Financial Habits"
        case .goalTimeframe: return "Financial Milestones"
        }
    }

    var subtitle: String {
        switch self {
        case .budgetArchitect: return "Balance monthly allocations"
        case .habitStreak: return "Build consistency with daily actions"
        case .goalTimeframe: return "Align targets along a clear timeline"
        }
    }
}

struct UserLearningModule: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var detail: String
    var linkedActivity: FinanceActivityKind
    var independentProgress: Double
    var tag: String
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, title, detail, linkedActivity, independentProgress, tag, sortOrder
    }

    init(
        id: UUID,
        title: String,
        detail: String,
        linkedActivity: FinanceActivityKind,
        independentProgress: Double = 0,
        tag: String = "General",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.linkedActivity = linkedActivity
        self.independentProgress = independentProgress
        self.tag = tag
        self.sortOrder = sortOrder
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        detail = try c.decode(String.self, forKey: .detail)
        linkedActivity = try c.decode(FinanceActivityKind.self, forKey: .linkedActivity)
        independentProgress = try c.decodeIfPresent(Double.self, forKey: .independentProgress) ?? 0
        tag = try c.decodeIfPresent(String.self, forKey: .tag) ?? "General"
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(detail, forKey: .detail)
        try c.encode(linkedActivity, forKey: .linkedActivity)
        try c.encode(independentProgress, forKey: .independentProgress)
        try c.encode(tag, forKey: .tag)
        try c.encode(sortOrder, forKey: .sortOrder)
    }
}

extension UserLearningModule: Hashable {}

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
