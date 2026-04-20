import SwiftUI

struct BudgetArchitectView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BudgetArchitectViewModel(difficulty: .medium)
    @State private var completionRoute: SessionCompletionRoute?
    @State private var feedbackMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Budget Architect")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Shape a monthly plan that stays close to a balanced 50 / 30 / 20 guideline.")
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                Group {
                    fieldBlock(
                        title: "Monthly income",
                        text: $viewModel.incomeText,
                        warning: viewModel.incomeWarning,
                        onEditingChanged: viewModel.handleIncomeEditingChanged
                    )

                    fieldBlock(
                        title: "Needs %",
                        text: $viewModel.needsText,
                        warning: viewModel.needsWarning,
                        onEditingChanged: viewModel.handleNeedsEditingChanged
                    )

                    fieldBlock(
                        title: "Wants %",
                        text: $viewModel.wantsText,
                        warning: viewModel.wantsWarning,
                        onEditingChanged: viewModel.handleWantsEditingChanged
                    )

                    fieldBlock(
                        title: "Savings %",
                        text: $viewModel.savingsText,
                        warning: viewModel.savingsWarning,
                        onEditingChanged: viewModel.handleSavingsEditingChanged
                    )
                }

                allocationCanvas
                    .frame(height: 180)
                    .padding(10)
                    .appSectionDepth(cornerRadius: 20, elevation: .floating)
                    .padding(.vertical, 4)

                HStack {
                    Label("Lives", systemImage: "heart.fill")
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Text("\(viewModel.livesRemaining)")
                        .font(.title3.monospacedDigit().weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(16)
                .appSectionDepth(cornerRadius: 18, elevation: .card)

                if viewModel.advancedUnlocked {
                    Text("Advanced assist unlocked: tighter checks are active for this session.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appSectionDepth(cornerRadius: 14, elevation: .card, accent: Color.appAccent)
                }

                if let feedbackMessage {
                    Text(feedbackMessage)
                        .foregroundStyle(Color.appPrimary)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                }

                FinancePrimaryButton(title: "Process budget") {
                    let result = viewModel.submitAttempt()
                    switch result {
                    case let .success(stars, payload, savingsPortion):
                        data.registerBudgetSession(stars: stars, payload: payload, savingsPortion: savingsPortion)
                        let tx = FinanceTransaction(
                            id: UUID(),
                            title: "Budget alignment session",
                            amount: payload.income,
                            category: "Planning",
                            date: Date()
                        )
                        data.addTransaction(tx)
                        completionRoute = SessionCompletionRoute(
                            stars: stars,
                            headline: "Budget captured",
                            detail: "Your allocations were evaluated against the reference mix.",
                            totalSavings: data.totalSavingsTracked,
                            goalCompletions: data.goalCompletionsTracked,
                            habitStreak: data.habitStreakRecord,
                            showAchievementBanner: data.achievementUnlocked
                        )
                    case let .failure(message):
                        feedbackMessage = message
                        if viewModel.livesRemaining == 0 {
                            completionRoute = SessionCompletionRoute(
                                stars: 0,
                                headline: "Session paused",
                                detail: "No lives remaining. Adjust inputs and try another session.",
                                totalSavings: data.totalSavingsTracked,
                                goalCompletions: data.goalCompletionsTracked,
                                habitStreak: data.habitStreakRecord,
                                showAchievementBanner: false
                            )
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.reload(using: data.difficulty)
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

    private var allocationCanvas: some View {
        let needs = Double(viewModel.needsText) ?? 0
        let wants = Double(viewModel.wantsText) ?? 0
        let savings = Double(viewModel.savingsText) ?? 0
        return Canvas { context, size in
            let total = max(needs + wants + savings, 1)
            let barWidth = size.width - 32
            let barHeight = size.height - 40
            let origin = CGPoint(x: 16, y: 20)
            var cursor = origin.x
            let segments: [(Double, Color)] = [
                (needs / total, Color.appPrimary),
                (wants / total, Color.appAccent),
                (savings / total, Color.appTextSecondary.opacity(0.65))
            ]
            for (ratio, color) in segments {
                let width = barWidth * CGFloat(ratio)
                let rect = CGRect(x: cursor, y: origin.y, width: width, height: barHeight)
                let rounded = RoundedRectangle(cornerRadius: 10, style: .continuous).path(in: rect)
                context.fill(rounded, with: .color(color))
                cursor += width
            }
        }
        .background(RoundedRectangle(cornerRadius: 18).stroke(Color.appAccent.opacity(0.25)))
    }

    private func fieldBlock(
        title: String,
        text: Binding<String>,
        warning: String?,
        onEditingChanged: @escaping (Bool) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(Color.appPrimary)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            TextField("0", text: text, onEditingChanged: onEditingChanged, onCommit: {})
                .keyboardType(.decimalPad)
                .padding(12)
                .appInsetWell(cornerRadius: 12)
            if let warning {
                Text(warning)
                    .font(.caption)
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
    }
}
