import Foundation

struct SessionCompletionRoute: Identifiable, Hashable {
    let id = UUID()
    let stars: Int
    let headline: String
    let detail: String
    let totalSavings: Double
    let goalCompletions: Int
    let habitStreak: Int
    let showAchievementBanner: Bool
}
