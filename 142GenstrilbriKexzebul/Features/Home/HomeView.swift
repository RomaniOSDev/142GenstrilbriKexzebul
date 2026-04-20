import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @State private var showModules = false
    @State private var showCategoryBudgets = false
    @State private var showDashboard = false

    private static let gridSpacing: CGFloat = 14
    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Self.gridSpacing),
            GridItem(.flexible(), spacing: Self.gridSpacing)
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerBlock

                heroSpendWidget

                LazyVGrid(columns: columns, spacing: Self.gridSpacing) {
                    streakWidget
                    starsWidget
                    alertsWidget
                    transactionsWidget
                }

                quickSessionsWidget

                goalsWidget

                modulesWidget
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Home")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showModules = true
                } label: {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(Color.appPrimary)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Learning modules")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        showCategoryBudgets = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Category spending caps")

                    Button {
                        showDashboard = true
                    } label: {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Full dashboard and charts")
                }
            }
        }
        .navigationDestination(isPresented: $showModules) {
            ModuleSelectionView()
        }
        .navigationDestination(isPresented: $showCategoryBudgets) {
            CategoryBudgetsView()
        }
        .navigationDestination(isPresented: $showDashboard) {
            DashboardView()
        }
    }

    // MARK: - Header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greetingLine)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(greetingLine), \(Date.now.formatted(date: .complete, time: .omitted))")
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let tail: String
        switch hour {
        case 5 ..< 12: tail = "Good morning"
        case 12 ..< 17: tail = "Good afternoon"
        case 17 ..< 22: tail = "Good evening"
        default: tail = "Good night"
        }
        return "\(tail) · overview"
    }

    // MARK: - Hero

    private var heroSpendWidget: some View {
        let thisMonth = data.totalSpendThisMonth()
        let lastMonth = data.totalSpendPreviousMonth()
        let delta = lastMonth > 0 ? (thisMonth - lastMonth) / lastMonth : nil

        return NavigationLink {
            HistoryView()
        } label: {
            HomeWidgetShell(accent: Color.appAccent) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("This month", systemImage: "calendar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appAccent.opacity(0.8))
                    }
                    Text(thisMonth.formatted(.currency(code: "USD")))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    HStack(spacing: 10) {
                        Text("Last month \(lastMonth.formatted(.currency(code: "USD")))")
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if let delta {
                            Text(deltaLabel(delta))
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(deltaChipColor(delta).opacity(0.2))
                                )
                                .foregroundStyle(deltaChipColor(delta))
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens history to review transactions")
    }

    private func deltaLabel(_ delta: Double) -> String {
        let pct = abs(delta * 100)
        let sign = delta > 0 ? "+" : delta < 0 ? "−" : ""
        return "\(sign)\(pct.formatted(.number.precision(.fractionLength(0))))% vs last"
    }

    private func deltaChipColor(_ delta: Double) -> Color {
        if delta > 0.02 { return Color.appPrimary }
        if delta < -0.02 { return Color.green }
        return Color.appTextSecondary
    }

    // MARK: - Grid widgets

    private var streakWidget: some View {
        HomeWidgetShell(accent: Color.orange) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    )
                    .accessibilityHidden(true)
                Text("Habit streak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text("\(data.habitData.currentStreak) days")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Habit streak \(data.habitData.currentStreak) days")
    }

    private var starsWidget: some View {
        HomeWidgetShell(accent: Color.appAccent) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(Color.appAccent)
                    .accessibilityHidden(true)
                Text("Stars earned")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text("\(data.totalEarnedStars())")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                Text("Across all sessions")
                    .font(.caption2)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total stars earned \(data.totalEarnedStars())")
    }

    private var alertsWidget: some View {
        let alerts = data.categoryBudgetAlerts().filter { $0.overBudget || $0.nearLimit }
        return Button {
            showCategoryBudgets = true
        } label: {
            HomeWidgetShell(accent: alerts.isEmpty ? Color.appTextSecondary : Color.appPrimary) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: alerts.isEmpty ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(alerts.isEmpty ? Color.green.opacity(0.85) : Color.appPrimary)
                    Text("Budget caps")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text(alerts.isEmpty ? "All clear" : "\(alerts.count) alert\(alerts.count == 1 ? "" : "s")")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(alerts.isEmpty ? "Budget caps, all clear" : "Budget caps, \(alerts.count) alerts")
    }

    private var transactionsWidget: some View {
        let count = data.transactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }.count
        return NavigationLink {
            HistoryView()
        } label: {
            HomeWidgetShell(accent: Color.appPrimary) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "list.bullet.rectangle.portrait.fill")
                        .font(.title2)
                        .foregroundStyle(Color.appPrimary.opacity(0.85))
                    Text("This month")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("\(count) entries")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("This month \(count) transaction entries")
    }

    // MARK: - Quick sessions

    private var quickSessionsWidget: some View {
        HomeWidgetShell(accent: Color.appAccent) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sessions")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                HStack(spacing: 10) {
                    sessionChip(title: "Budget", icon: "chart.pie.fill", destination: BudgetArchitectView(), tint: Color.appPrimary)
                    sessionChip(title: "Habits", icon: "leaf.fill", destination: HabitStreakView(), tint: Color.green.opacity(0.85))
                    sessionChip(title: "Goals", icon: "flag.fill", destination: GoalTimeframeView(), tint: Color.appAccent)
                }
            }
        }
    }

    private func sessionChip<D: View>(title: String, icon: String, destination: D, tint: Color) -> some View {
        NavigationLink {
            destination
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .appSectionDepth(cornerRadius: 16, elevation: .card, accent: tint)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) session")
    }

    // MARK: - Goals

    @ViewBuilder
    private var goalsWidget: some View {
        if let goal = data.savingsGoals.first {
            let progress = min(1, max(0, goal.currentAmount / max(goal.targetAmount, 1)))
            NavigationLink {
                GoalsTabView()
            } label: {
                HomeWidgetShell(accent: Color.appAccent) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Primary goal")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appTextSecondary)
                            Spacer()
                            Image(systemName: "target")
                                .foregroundStyle(Color.appAccent)
                        }
                        Text(goal.title)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                        ProgressView(value: progress)
                            .tint(Color.appAccent)
                        HStack {
                            Text(goal.currentAmount.formatted(.currency(code: "USD")))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.appPrimary)
                            Spacer()
                            Text(goal.targetAmount.formatted(.currency(code: "USD")))
                                .font(.caption)
                                .foregroundStyle(Color.appTextSecondary)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Primary savings goal \(goal.title), \(Int(progress * 100)) percent complete")
        } else {
            NavigationLink {
                GoalsTabView()
            } label: {
                HomeWidgetShell(accent: Color.appTextSecondary) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Goals")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("Add a savings goal")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                        Text("Track milestones and celebrate progress.")
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(3)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Modules

    private var modulesWidget: some View {
        Button {
            showModules = true
        } label: {
            HomeWidgetShell(accent: Color.appPrimary) {
                HStack(spacing: 16) {
                    ModuleCircularProgressView(progress: averageModuleProgress)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Learning paths")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("Modules & progress")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                        Text("\(data.userLearningModules.count) custom · tap to manage")
                            .font(.footnote)
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.appAccent.opacity(0.9))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Learning modules and progress, \(data.userLearningModules.count) custom modules")
    }

    private var averageModuleProgress: Double {
        let p1 = data.moduleProgress(for: .budgetArchitect)
        let p2 = data.moduleProgress(for: .habitStreak)
        let p3 = data.moduleProgress(for: .goalTimeframe)
        return (p1 + p2 + p3) / 3
    }
}

// MARK: - Shell

private struct HomeWidgetShell<Content: View>: View {
    var accent: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSectionDepth(cornerRadius: 22, elevation: .floating, accent: accent)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(FinanceDataManager())
    }
}
