import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @State private var showModules = false
    @State private var showSettings = false
    @State private var showCategoryBudgets = false

    var body: some View {
        ScrollView {
            GeometryReader { proxy in
                let layoutWidth = Self.layoutWidth(from: proxy.size.width)
                VStack(alignment: .leading, spacing: 16) {
                    header

                    summaryRow(width: layoutWidth)

                    dashboardGlanceCard(width: layoutWidth)

                    spendingCanvas
                        .frame(height: min(240, layoutWidth * 0.65))

                    monthComparisonBlock(width: layoutWidth)

                    categoryBudgetAlertsSection

                    Text("Guided sessions")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        activityCard(for: .budgetArchitect)
                        activityCard(for: .habitStreak)
                        activityCard(for: .goalTimeframe)
                    }
                }
                .padding(16)
                .frame(width: layoutWidth, alignment: .leading)
            }
            .frame(minHeight: 560)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Modules") {
                    showModules = true
                }
                .foregroundStyle(Color.appPrimary)
                .frame(minHeight: 44)
                .accessibilityLabel("Open learning modules")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    Button("Caps") {
                        showCategoryBudgets = true
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Category spending caps")

                    Button("Settings") {
                        showSettings = true
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minHeight: 44)
                    .accessibilityLabel("Open settings")
                }
            }
        }
        .navigationDestination(isPresented: $showModules) {
            ModuleSelectionView()
        }
        .navigationDestination(isPresented: $showSettings) {
            SettingsView()
        }
        .navigationDestination(isPresented: $showCategoryBudgets) {
            CategoryBudgetsView()
        }
    }

    private func dashboardGlanceCard(width: CGFloat) -> some View {
        let thisMonth = data.totalSpendThisMonth()
        let lastMonth = data.totalSpendPreviousMonth()
        let stars = data.totalEarnedStars()
        return VStack(alignment: .leading, spacing: 10) {
            Text("At a glance")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This month spend")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(thisMonth.formatted(.currency(code: "USD")))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Stars earned")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(stars)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            Text("Last month: \(lastMonth.formatted(.currency(code: "USD")))")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSectionDepth(cornerRadius: 20, elevation: .hero)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("At a glance. This month spending \(thisMonth.formatted(.currency(code: "USD"))). Last month \(lastMonth.formatted(.currency(code: "USD"))). Total stars \(stars).")
    }

    private func monthComparisonBlock(width: CGFloat) -> some View {
        let thisMonth = data.totalSpendThisMonth()
        let last = data.totalSpendPreviousMonth()
        let maxVal = max(thisMonth, last, 1)
        let chartFrameWidth = max(1, width - 32)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Month comparison")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .accessibilityAddTraits(.isHeader)
            Canvas { context, size in
                guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return }
                let barW = max(4, (size.width - 48) / 2)
                let plotH = max(0, size.height - 28)
                let hLast = max(0, min(plotH, CGFloat(last / maxVal) * plotH))
                let hThis = max(0, min(plotH, CGFloat(thisMonth / maxVal) * plotH))
                let lastRect = CGRect(x: 16, y: size.height - hLast - 16, width: barW, height: hLast)
                let thisRect = CGRect(x: 32 + barW, y: size.height - hThis - 16, width: barW, height: hThis)
                context.fill(RoundedRectangle(cornerRadius: 10).path(in: lastRect), with: .color(Color.appTextSecondary.opacity(0.55)))
                context.fill(RoundedRectangle(cornerRadius: 10).path(in: thisRect), with: .color(Color.appPrimary.opacity(0.9)))
                context.draw(Text("Last").font(.caption2).foregroundColor(Color.appTextSecondary), at: CGPoint(x: lastRect.midX, y: size.height - 6), anchor: .bottom)
                context.draw(Text("This").font(.caption2).foregroundColor(Color.appTextSecondary), at: CGPoint(x: thisRect.midX, y: size.height - 6), anchor: .bottom)
            }
            .frame(width: chartFrameWidth, height: 120)
            .appSectionDepth(cornerRadius: 20, elevation: .card)
            .accessibilityLabel("Bar chart comparing last month spending to this month")
            .accessibilityValue("Last month \(last.formatted(.currency(code: "USD"))), this month \(thisMonth.formatted(.currency(code: "USD")))")
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var categoryBudgetAlertsSection: some View {
        let alerts = data.categoryBudgetAlerts().filter { $0.overBudget || $0.nearLimit }
        if !alerts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Category alerts")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                ForEach(alerts, id: \.category) { row in
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(row.overBudget ? Color.appPrimary : Color.appAccent)
                            .frame(width: 4, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.overBudget ? "Over cap: \(row.category)" : "Near cap: \(row.category)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.appPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                            Text("\(row.spent.formatted(.currency(code: "USD"))) of \(row.limit.formatted(.currency(code: "USD")))")
                                .font(.caption)
                                .foregroundStyle(Color.appTextSecondary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .appSectionDepth(
                        cornerRadius: 16,
                        elevation: .card,
                        accent: row.overBudget ? Color.appPrimary : Color.appAccent
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(row.overBudget ? "Over budget for \(row.category)" : "Near limit for \(row.category). Spent \(row.spent) of \(row.limit) dollars")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dashboard")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Stay close to your plan with live summaries and focused sessions.")
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
        }
    }

    private func summaryRow(width: CGFloat) -> some View {
        HStack(spacing: 12) {
            bubble(title: "Sessions", value: "\(data.completedBudgetSessions + data.completedHabitSessions + data.completedGoalSessions)", width: width)
            bubble(title: "Stars", value: "\(data.totalEarnedStars())", width: width)
        }
    }

    private func bubble(title: String, value: String, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.42), radius: 16, x: 0, y: 10)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
    }

    private var spendingCanvas: some View {
        let totals = Dictionary(grouping: data.transactions, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        let maxAmount = max(totals.values.max() ?? 0, 1)
        return Canvas { context, size in
            guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return }
            guard !totals.isEmpty else {
                let copy = "No spending records yet"
                context.draw(Text(copy).font(.headline).foregroundColor(Color.appTextSecondary), at: CGPoint(x: 16, y: 20), anchor: .topLeading)
                return
            }
            let spacing: CGFloat = 14
            let count = CGFloat(max(totals.count, 1))
            let rawBarWidth = (size.width - 32 - spacing * (count - 1)) / count
            let barWidth = max(2, rawBarWidth.isFinite ? rawBarWidth : 2)
            var cursor: CGFloat = 16
            let plotH = max(0, size.height - 40)
            for (index, key) in totals.keys.sorted().enumerated() {
                let value = totals[key] ?? 0
                let height = max(0, min(plotH, CGFloat(value / maxAmount) * plotH))
                let rect = CGRect(x: cursor, y: size.height - height - 20, width: barWidth, height: height)
                let path = RoundedRectangle(cornerRadius: 10, style: .continuous).path(in: rect)
                let color = index.isMultiple(of: 2) ? Color.appPrimary : Color.appAccent
                context.fill(path, with: .color(color.opacity(0.9)))
                let label = Text(key).font(.caption2).foregroundColor(Color.appTextSecondary)
                context.draw(label, at: CGPoint(x: rect.midX, y: size.height - 8), anchor: .bottom)
                cursor += barWidth + spacing
            }
        }
        .padding(8)
        .appSectionDepth(cornerRadius: 22, elevation: .floating)
    }

    @ViewBuilder
    private func destination(for activity: FinanceActivityKind) -> some View {
        switch activity {
        case .budgetArchitect:
            BudgetArchitectView()
        case .habitStreak:
            HabitStreakView()
        case .goalTimeframe:
            GoalTimeframeView()
        }
    }

    @ViewBuilder
    private func activityCard(for activity: FinanceActivityKind) -> some View {
        let unlocked = data.isActivityUnlocked(activity)
        if unlocked {
            NavigationLink {
                destination(for: activity)
            } label: {
                activityLabel(for: activity, unlocked: unlocked)
            }
            .buttonStyle(.plain)
        } else {
            activityLabel(for: activity, unlocked: unlocked)
                .opacity(0.55)
        }
    }

    private func activityLabel(for activity: FinanceActivityKind, unlocked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(activity.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                if unlocked {
                    StarRatingDisplay(filled: data.stars(for: activity), total: 3)
                } else {
                    Text("Locked")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            Text(activity.subtitle)
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(unlocked ? "Open session" : "Finish the prior session")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .appSectionDepth(cornerRadius: 20, elevation: .card)
    }

    /// GeometryReader inside ScrollView can briefly report 0 or non-finite width; frames must stay positive and finite.
    private static func layoutWidth(from width: CGFloat) -> CGFloat {
        guard width.isFinite, width > 0 else { return 1 }
        return width
    }
}
