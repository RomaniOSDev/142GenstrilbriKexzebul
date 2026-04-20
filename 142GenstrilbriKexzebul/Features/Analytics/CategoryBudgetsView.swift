import SwiftUI

struct CategoryBudgetsView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @State private var categoryName = ""
    @State private var limitText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Category limits")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)

                Text("Set a monthly cap per category. The dashboard warns near 85% and when you exceed the cap.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Category name")
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    TextField("e.g. Dining", text: $categoryName)
                        .padding(12)
                        .appInsetWell(cornerRadius: 12)
                        .accessibilityLabel("Category name")

                    Text("Monthly limit (USD)")
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    TextField("0", text: $limitText)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .appInsetWell(cornerRadius: 12)
                        .accessibilityLabel("Monthly limit in dollars")

                    FinancePrimaryButton(title: "Add limit") {
                        let limit = Double(limitText) ?? 0
                        data.addCategoryBudget(categoryName: categoryName, monthlyLimit: limit)
                        categoryName = ""
                        limitText = ""
                    }
                    .accessibilityHint("Adds a spending cap for the category you entered")
                }
                .padding(16)
                .appSectionDepth(cornerRadius: 20, elevation: .floating)

                ForEach(data.categoryBudgets) { cap in
                    budgetRow(cap: cap)
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func budgetRow(cap: CategoryBudgetLimit) -> some View {
        let spent = data.spendThisMonth(category: cap.categoryName)
        let ratio = cap.monthlyLimit > 0 ? spent / cap.monthlyLimit : 0
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(cap.categoryName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Button("Remove") {
                    data.removeCategoryBudget(id: cap.id)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appAccent)
                .frame(minHeight: 44)
                .accessibilityLabel("Remove limit for \(cap.categoryName)")
            }
            Text("Spent \(spent.formatted(.currency(code: "USD"))) of \(cap.monthlyLimit.formatted(.currency(code: "USD")))")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            ProgressView(value: min(1, ratio))
                .tint(ratio >= 1 ? Color.appPrimary : Color.appAccent)
                .accessibilityValue("\(Int(min(100, ratio * 100))) percent of monthly cap used")
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 18, elevation: .card)
    }
}
