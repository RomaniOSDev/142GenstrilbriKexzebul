import Combine
import Foundation
import SwiftUI

struct HabitDaySlot: Identifiable, Hashable {
    var id: String { label }
    var label: String
    var habits: [Bool]
}

@MainActor
final class HabitStreakViewModel: ObservableObject {
    @Published var days: [HabitDaySlot]
    @Published var selectedIndex: Int = 0
    @Published var streak: Int
    private(set) var habitNames: [String]

    private var difficulty: FinanceDifficulty

    init(difficulty: FinanceDifficulty, seed: HabitPayload) {
        self.difficulty = difficulty
        habitNames = seed.habitNames
        streak = seed.currentStreak
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        days = zip(labels, 0..<7).map { label, index in
            let completed = index < seed.weekSlots.count ? seed.weekSlots[index] : false
            let habits = Array(repeating: completed, count: 3)
            return HabitDaySlot(label: label, habits: habits)
        }
    }

    func reload(difficulty: FinanceDifficulty, seed: HabitPayload) {
        self.difficulty = difficulty
        habitNames = seed.habitNames
        streak = seed.currentStreak
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        days = zip(labels, 0..<7).map { label, index in
            let completed = index < seed.weekSlots.count ? seed.weekSlots[index] : false
            let habits = Array(repeating: completed, count: 3)
            return HabitDaySlot(label: label, habits: habits)
        }
        selectedIndex = 0
    }

    func binding(for day: Int, habit: Int) -> Binding<Bool> {
        Binding(
            get: { self.days[day].habits[habit] },
            set: { newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    var slot = self.days[day]
                    slot.habits[habit] = newValue
                    self.days[day] = slot
                    self.recomputeStreak()
                }
            }
        )
    }

    func swipeSelection(delta: Int) {
        let next = min(max(0, selectedIndex + delta), days.count - 1)
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedIndex = next
        }
    }

    private func recomputeStreak() {
        var run = 0
        for slot in days {
            if slot.habits.allSatisfy({ $0 }) {
                run += 1
            } else {
                break
            }
        }
        streak = run
    }

    func finalizeSession() -> HabitSessionOutcome {
        recomputeStreak()
        let threshold = difficulty.habitStreakForThreeStars
        let stars: Int
        if streak >= threshold {
            stars = 3
        } else if streak >= max(1, threshold - 2) {
            stars = 2
        } else if streak >= 1 {
            stars = 1
        } else {
            stars = 0
        }
        let payload = HabitPayload(
            currentStreak: streak,
            lastCompletedDay: Date(),
            weekSlots: days.map { $0.habits.allSatisfy { $0 } },
            habitNames: habitNames
        )
        return HabitSessionOutcome(stars: stars, payload: payload)
    }
}

struct HabitSessionOutcome {
    let stars: Int
    let payload: HabitPayload
}
