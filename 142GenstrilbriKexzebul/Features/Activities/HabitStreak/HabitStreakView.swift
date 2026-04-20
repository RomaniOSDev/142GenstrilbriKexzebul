import SwiftUI

struct HabitStreakView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = HabitStreakViewModel(
        difficulty: .medium,
        seed: HabitPayload(currentStreak: 0, lastCompletedDay: nil, weekSlots: Array(repeating: false, count: 7))
    )
    @State private var completionRoute: SessionCompletionRoute?

    var body: some View {
        ScrollView {
            GeometryReader { proxy in
                VStack(alignment: .leading, spacing: 16) {
                    header

                    streakPanel(width: proxy.size.width)

                    horizontalWeek(width: proxy.size.width)
                        .frame(height: min(360, proxy.size.height))

                    FinancePrimaryButton(title: "Complete session") {
                        let outcome = viewModel.finalizeSession()
                        data.registerHabitSession(stars: outcome.stars, streak: outcome.payload.currentStreak, payload: outcome.payload)
                        completionRoute = SessionCompletionRoute(
                            stars: outcome.stars,
                            headline: "Habits recorded",
                            detail: "Your streak reflects consecutive fully completed days from the start of the week.",
                            totalSavings: data.totalSavingsTracked,
                            goalCompletions: data.goalCompletionsTracked,
                            habitStreak: data.habitStreakRecord,
                            showAchievementBanner: data.achievementUnlocked
                        )
                    }
                }
                .padding(16)
                .frame(minHeight: proxy.size.height, alignment: .top)
            }
            .frame(minHeight: 520)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.reload(difficulty: data.difficulty, seed: data.habitData)
        }
        .sheet(item: $completionRoute) { route in
            SessionCompletionView(route: route) {
                completionRoute = nil
                dismiss()
            } onViewProgress: {
                completionRoute = nil
                dismiss()
            } onHome: {
                completionRoute = nil
                dismiss()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Financial Habits")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Swipe across the week, toggle each action, and keep the streak alive.")
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
        }
    }

    private func streakPanel(width: CGFloat) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current streak")
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(viewModel.streak) days")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            Capsule()
                .fill(Color.appAccent.opacity(0.2))
                .frame(width: min(160, width * 0.35), height: 44)
                .overlay(
                    Text("Live")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                )
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 18, elevation: .card)
    }

    private func horizontalWeek(width: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.days.indices, id: \.self) { index in
                    let slot = viewModel.days[index]
                    dayCard(slot: slot, index: index, cardWidth: max(260, width * 0.78))
                }
            }
            .padding(.vertical, 8)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width < -40 {
                        viewModel.swipeSelection(delta: 1)
                    } else if value.translation.width > 40 {
                        viewModel.swipeSelection(delta: -1)
                    }
                }
        )
    }

    private func dayCard(slot: HabitDaySlot, index: Int, cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(slot.label)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text(index == viewModel.selectedIndex ? "Focused" : "Swipe")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            ForEach(viewModel.habitNames.indices, id: \.self) { habitIndex in
                Toggle(isOn: viewModel.binding(for: index, habit: habitIndex)) {
                    Text(viewModel.habitNames[habitIndex])
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.appAccent))
            }
        }
        .padding(16)
        .frame(width: cardWidth, alignment: .leading)
        .appSectionDepth(
            cornerRadius: 20,
            elevation: index == viewModel.selectedIndex ? .floating : .card,
            accent: index == viewModel.selectedIndex ? Color.appAccent : Color.appAccent.opacity(0.35)
        )
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.selectedIndex = index
            }
        }
    }
}
