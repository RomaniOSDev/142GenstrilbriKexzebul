import SwiftUI

private enum HistorySpendFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case thisMonth = "This month"
    case last30 = "30 days"

    var id: String { rawValue }
}

struct HistoryView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @State private var showComposer = false
    @State private var showRecurringComposer = false
    @State private var titleText = ""
    @State private var amountText = ""
    @State private var categoryText = "General"
    @State private var recurringTitle = ""
    @State private var recurringAmount = ""
    @State private var recurringCategory = "General"
    @State private var recurringInterval = 1
    @State private var recurringNext = Date()
    @State private var spendFilter: HistorySpendFilter = .all
    @State private var searchText = ""

    private var hasAnyContent: Bool {
        !data.transactions.isEmpty || !data.recurringExpenses.isEmpty
    }

    private var filteredTransactions: [FinanceTransaction] {
        let cal = Calendar.current
        var list = data.transactions
        switch spendFilter {
        case .all:
            break
        case .thisMonth:
            list = list.filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        case .last30:
            if let start = cal.date(byAdding: .day, value: -30, to: cal.startOfDay(for: Date())) {
                list = list.filter { $0.date >= start }
            }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter {
                $0.title.localizedCaseInsensitiveContains(q) || $0.category.localizedCaseInsensitiveContains(q)
            }
        }
        return list.sorted { $0.date > $1.date }
    }

    private var thisMonthTotal: Double {
        data.totalSpendThisMonth()
    }

    private var lastMonthTotal: Double {
        data.totalSpendPreviousMonth()
    }

    private var categoryTotals: [(name: String, amount: Double)] {
        Dictionary(grouping: filteredTransactions, by: { $0.category })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }

    /// Calendar last 7 days from all data (sparkline is not tied to text search).
    private var lastSevenDayTotals: [Double] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return Array((0 ..< 7).compactMap { offset -> Double? in
            guard let day = cal.date(byAdding: .day, value: -offset, to: start) else { return nil }
            let next = cal.date(byAdding: .day, value: 1, to: day) ?? day
            let sum = data.transactions.filter { $0.date >= day && $0.date < next }.reduce(0) { $0 + $1.amount }
            return sum
        }.reversed())
    }

    private var isDefaultHeroScope: Bool {
        spendFilter == .all && searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var heroMainAmount: Double {
        if isDefaultHeroScope { return thisMonthTotal }
        return filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    private var heroScopeTitle: String {
        if isDefaultHeroScope { return "This month" }
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Matches search" }
        return spendFilter.rawValue
    }

    private var transactionsByDay: [(label: String, dayStart: Date, items: [FinanceTransaction])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: filteredTransactions) { cal.startOfDay(for: $0.date) }
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return grouped.keys.sorted(by: >).map { day in
            let label: String
            if cal.isDateInToday(day) {
                label = "Today"
            } else if cal.isDateInYesterday(day) {
                label = "Yesterday"
            } else {
                label = formatter.string(from: day)
            }
            return (label, day, grouped[day]?.sorted { $0.date > $1.date } ?? [])
        }
    }

    var body: some View {
        Group {
            if hasAnyContent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        summaryHero

                        if !data.recurringExpenses.isEmpty {
                            recurringSection
                        }

                        if !data.transactions.isEmpty {
                            weekSparkSection
                            if !categoryTotals.isEmpty {
                                categoryStrip
                            }
                        }

                        filterAndSearch

                        if filteredTransactions.isEmpty {
                            filterEmptyPlaceholder
                        } else {
                            timelineSection
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
                }
            } else {
                emptyStateFull
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showRecurringComposer = true
                } label: {
                    Image(systemName: "repeat.circle.fill")
                        .font(.body.weight(.semibold))
                }
                .foregroundStyle(Color.appPrimary)
                .frame(minHeight: 44)
                .accessibilityLabel("Add recurring expense")

                Button {
                    showComposer = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3.weight(.semibold))
                }
                .foregroundStyle(Color.appAccent)
                .frame(minHeight: 44)
                .accessibilityLabel("Add one-time entry")
            }
        }
        .sheet(isPresented: $showComposer) {
            composerSheet
        }
        .sheet(isPresented: $showRecurringComposer) {
            recurringSheet
        }
    }

    // MARK: - Background

    // MARK: - Summary hero

    private var summaryHero: some View {
        let delta = isDefaultHeroScope && lastMonthTotal > 0 ? (thisMonthTotal - lastMonthTotal) / lastMonthTotal : nil
        return VStack(alignment: .leading, spacing: 12) {
            Text("Spending pulse")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.6)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(heroMainAmount.formatted(.currency(code: "USD")))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(heroScopeTitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.trailing)
                    if let delta {
                        Text(monthDeltaLabel(delta))
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(monthDeltaTint(delta).opacity(0.18)))
                            .foregroundStyle(monthDeltaTint(delta))
                    }
                }
            }

            HStack(spacing: 16) {
                statChip(icon: "list.bullet", title: "Entries", value: "\(filteredTransactions.count)")
                statChip(icon: "square.grid.2x2", title: "Categories", value: "\(Set(filteredTransactions.map(\.category)).count)")
                statChip(icon: "calendar", title: "Last month", value: lastMonthTotal.formatted(.currency(code: "USD").precision(.fractionLength(0))))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSectionDepth(cornerRadius: 24, elevation: .hero)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(heroScopeTitle) total \(heroMainAmount.formatted(.currency(code: "USD"))), \(filteredTransactions.count) entries in scope")
    }

    private func statChip(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appAccent)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .appSectionDepth(cornerRadius: 14, elevation: .card)
    }

    private func monthDeltaLabel(_ delta: Double) -> String {
        let pct = abs(delta * 100)
        let arrow = delta > 0 ? "↑" : delta < 0 ? "↓" : "→"
        return "\(arrow) \(pct.formatted(.number.precision(.fractionLength(0))))%"
    }

    private func monthDeltaTint(_ delta: Double) -> Color {
        if delta > 0.02 { return Color.appPrimary }
        if delta < -0.02 { return .green }
        return Color.appTextSecondary
    }

    // MARK: - Recurring

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recurring", systemImage: "repeat")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                Spacer()
                Button {
                    showRecurringComposer = true
                } label: {
                    Text("Add")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.appAccent)
                }
                .accessibilityLabel("Add new recurring expense")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(data.recurringExpenses) { item in
                        recurringCard(item)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func recurringCard(_ item: RecurringExpense) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(item.amount.formatted(.currency(code: "USD")))
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color.appAccent)
            Text(item.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Button {
                data.recordRecurringPayment(id: item.id)
            } label: {
                Text("Log payment")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.appPrimary.opacity(0.12)))
                    .foregroundStyle(Color.appPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 168, alignment: .leading)
        .appSectionDepth(cornerRadius: 20, elevation: .floating)
        .overlay(alignment: .topTrailing) {
            Menu {
                Button(role: .destructive) {
                    data.removeRecurringExpense(id: item.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(8)
            }
            .accessibilityLabel("Options for \(item.title)")
        }
    }

    // MARK: - Week spark

    private var weekSparkSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 days")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appPrimary)
            Canvas { context, size in
                guard size.width.isFinite, size.height.isFinite, size.width > 8, size.height > 8 else { return }
                let values = Array(lastSevenDayTotals)
                let maxV = max(values.max() ?? 0, 1)
                let barW = max(4, (size.width - 24 - CGFloat(max(values.count - 1, 0)) * 6) / CGFloat(max(values.count, 1)))
                var x: CGFloat = 12
                let cal = Calendar.current
                for (i, v) in values.enumerated() {
                    let h = max(2, CGFloat(v / maxV) * (size.height - 28))
                    let rect = CGRect(x: x, y: size.height - h - 10, width: barW, height: h)
                    context.fill(RoundedRectangle(cornerRadius: 5, style: .continuous).path(in: rect), with: .color(Color.appAccent.opacity(0.85)))
                    if let day = cal.date(byAdding: .day, value: -(values.count - 1 - i), to: cal.startOfDay(for: Date())) {
                        let wd = day.formatted(.dateTime.weekday(.narrow))
                        context.draw(
                            Text(wd).font(.caption2.weight(.bold)).foregroundColor(Color.appTextSecondary),
                            at: CGPoint(x: rect.midX, y: size.height - 4),
                            anchor: .bottom
                        )
                    }
                    x += barW + 6
                }
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .appSectionDepth(cornerRadius: 20, elevation: .card)
        }
        .accessibilityLabel("Spending trend for the last seven days")
    }

    // MARK: - Categories

    private var categoryStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top categories")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appPrimary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categoryTotals.prefix(8), id: \.name) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(categoryTint(row.name))
                                    .frame(width: 8, height: 8)
                                Text(row.name)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.appPrimary)
                                    .lineLimit(1)
                            }
                            Text(row.amount.formatted(.currency(code: "USD")))
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(Color.appAccent)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.appSurface)
                                .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
                        )
                        .overlay(
                            Capsule()
                                .stroke(categoryTint(row.name).opacity(0.35), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private func categoryTint(_ name: String) -> Color {
        let palette: [Color] = [
            Color.appAccent, Color.appPrimary, .mint, .orange, .cyan, .purple, .pink, .indigo
        ]
        let idx = abs(name.hashValue) % palette.count
        return palette[idx]
    }

    // MARK: - Filter & search

    private var filterAndSearch: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Range", selection: $spendFilter) {
                ForEach(HistorySpendFilter.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .pickerStyle(.segmented)
            .tint(Color.appAccent)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.appTextSecondary)
                TextField("Search title or category", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Color.appPrimary)
            }
            .padding(12)
            .appInsetWell(cornerRadius: 14)
        }
    }

    private var filterEmptyPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 44))
                .foregroundStyle(Color.appAccent.opacity(0.65))
            Text("Nothing in this range")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
            Text("Try another filter or clear the search.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .appSectionDepth(cornerRadius: 20, elevation: .card)
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Timeline")
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appPrimary)

            ForEach(transactionsByDay, id: \.dayStart) { group in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(group.label)
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(Color.appAccent)
                        Spacer()
                        Text(dayTotal(group.items).formatted(.currency(code: "USD")))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(group.label), total \(dayTotal(group.items).formatted(.currency(code: "USD")))")

                    ForEach(group.items) { item in
                        transactionRow(item)
                    }
                }
            }
        }
    }

    private func dayTotal(_ items: [FinanceTransaction]) -> Double {
        items.reduce(0) { $0 + $1.amount }
    }

    private func transactionRow(_ item: FinanceTransaction) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(categoryTint(item.category).opacity(0.2))
                    .frame(width: 48, height: 48)
                Image(systemName: categoryIcon(for: item.category))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(categoryTint(item.category))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("·")
                        .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                    Text(item.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }
                .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(item.amount.formatted(.currency(code: "USD")))
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.appAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .appSectionDepth(cornerRadius: 18, elevation: .card, accent: categoryTint(item.category))
        .contextMenu {
            Button(role: .destructive) {
                data.removeTransaction(id: item.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.category), \(item.amount.formatted(.currency(code: "USD")))")
    }

    private func categoryIcon(for name: String) -> String {
        let icons = ["cart.fill", "fork.knife", "car.fill", "house.fill", "bolt.fill", "heart.fill", "gift.fill", "airplane", "bag.fill", "creditcard.fill"]
        return icons[abs(name.hashValue) % icons.count]
    }

    // MARK: - Empty

    private var emptyStateFull: some View {
        ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    ForEach(0 ..< 3, id: \.self) { i in
                        Circle()
                            .stroke(Color.appAccent.opacity(0.12 - Double(i) * 0.03), lineWidth: 2)
                            .frame(width: CGFloat(100 + i * 36), height: CGFloat(100 + i * 36))
                    }
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.appAccent, Color.appPrimary], startPoint: .top, endPoint: .bottom)
                        )
                }
                .padding(.top, 32)

                VStack(spacing: 10) {
                    Text("Your history starts here")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .multilineTextAlignment(.center)
                    Text("Log spending, watch patterns emerge, and keep recurring bills on autopilot.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                VStack(spacing: 12) {
                    Button {
                        showComposer = true
                    } label: {
                        Label("Add first entry", systemImage: "plus.circle.fill")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.appAccent))
                            .foregroundStyle(Color.white)
                    }
                    Button {
                        showRecurringComposer = true
                    } label: {
                        Label("Set up recurring", systemImage: "repeat.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.appPrimary.opacity(0.35), lineWidth: 1.5))
                            .foregroundStyle(Color.appPrimary)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Sheets (unchanged structure)

    private var composerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New record")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appPrimary)

                    labeledField(title: "Title", text: $titleText)
                    labeledField(title: "Amount", text: $amountText, keyboard: .decimalPad)
                    labeledField(title: "Category", text: $categoryText)

                    FinancePrimaryButton(title: "Save entry") {
                        let amount = Double(amountText) ?? 0
                        let item = FinanceTransaction(
                            id: UUID(),
                            title: titleText.isEmpty ? "Entry" : titleText,
                            amount: amount,
                            category: categoryText.isEmpty ? "General" : categoryText,
                            date: Date()
                        )
                        data.addTransaction(item)
                        titleText = ""
                        amountText = ""
                        categoryText = "General"
                        showComposer = false
                    }
                }
                .padding(16)
            }
            .appChromeBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showComposer = false
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var recurringSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New recurring item")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appPrimary)

                    labeledField(title: "Title", text: $recurringTitle)
                    labeledField(title: "Amount", text: $recurringAmount, keyboard: .decimalPad)
                    labeledField(title: "Category", text: $recurringCategory)

                    Stepper("Every \(recurringInterval) month(s)", value: $recurringInterval, in: 1...12)
                        .foregroundStyle(Color.appPrimary)

                    DatePicker("Next due", selection: $recurringNext, displayedComponents: .date)
                        .tint(Color.appAccent)

                    FinancePrimaryButton(title: "Save recurring") {
                        let amount = Double(recurringAmount) ?? 0
                        data.addRecurringExpense(
                            title: recurringTitle,
                            amount: amount,
                            category: recurringCategory.isEmpty ? "General" : recurringCategory,
                            intervalMonths: recurringInterval,
                            nextDue: recurringNext
                        )
                        recurringTitle = ""
                        recurringAmount = ""
                        recurringCategory = "General"
                        recurringInterval = 1
                        showRecurringComposer = false
                    }
                }
                .padding(16)
            }
            .appChromeBackground()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        showRecurringComposer = false
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private func labeledField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            TextField("", text: text)
                .keyboardType(keyboard)
                .padding(12)
                .appInsetWell(cornerRadius: 12)
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .environmentObject(FinanceDataManager())
    }
}
