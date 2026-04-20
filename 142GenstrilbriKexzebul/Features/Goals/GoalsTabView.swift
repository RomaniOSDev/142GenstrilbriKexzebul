import SwiftUI

struct GoalsTabView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @State private var showComposer = false
    @State private var titleText = ""
    @State private var targetText = ""
    @State private var currentText = ""
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var milestoneGoalId: UUID?
    @State private var milestoneTitle = ""
    @State private var milestoneAmountText = ""

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(data.savingsGoals) { goal in
                    goalCard(goal: goal)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showComposer = true
                }
                .foregroundStyle(Color.appPrimary)
                .frame(minHeight: 44)
                .accessibilityLabel("Add savings goal")
            }
        }
        .overlay(alignment: .center) {
            if data.savingsGoals.isEmpty {
                VStack(spacing: 12) {
                    Text("No goals yet")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("Tap Add to define a target amount, deadline, and optional checkpoints.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(4)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 40)
            }
        }
        .sheet(isPresented: $showComposer) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New goal")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        labeledField(title: "Title", text: $titleText)
                        labeledField(title: "Target amount", text: $targetText, keyboard: .decimalPad)
                        labeledField(title: "Starting progress", text: $currentText, keyboard: .decimalPad)

                        DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                            .tint(Color.appAccent)

                        FinancePrimaryButton(title: "Save goal") {
                            let target = Double(targetText) ?? 0
                            let current = Double(currentText) ?? 0
                            let goal = FinanceSavingsGoal(
                                id: UUID(),
                                title: titleText.isEmpty ? "Goal" : titleText,
                                targetAmount: max(1, target),
                                currentAmount: min(max(0, current), max(1, target)),
                                deadline: deadline,
                                milestones: []
                            )
                            data.appendSavingsGoal(goal)
                            titleText = ""
                            targetText = ""
                            currentText = ""
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
        .sheet(isPresented: Binding(
            get: { milestoneGoalId != nil },
            set: { if !$0 { milestoneGoalId = nil } }
        )) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("New checkpoint")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.appPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        labeledField(title: "Title", text: $milestoneTitle)
                        labeledField(title: "Amount reached (USD)", text: $milestoneAmountText, keyboard: .decimalPad)

                        FinancePrimaryButton(title: "Save checkpoint") {
                            if let id = milestoneGoalId {
                                let amt = Double(milestoneAmountText) ?? 0
                                data.addGoalMilestone(goalId: id, title: milestoneTitle, thresholdAmount: amt)
                            }
                            milestoneTitle = ""
                            milestoneAmountText = ""
                            milestoneGoalId = nil
                        }
                    }
                    .padding(16)
                }
                .appChromeBackground()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            milestoneGoalId = nil
                        }
                        .foregroundStyle(Color.appPrimary)
                        .frame(minHeight: 44)
                    }
                }
            }
        }
    }

    private func goalCard(goal: FinanceSavingsGoal) -> some View {
        let live = data.savingsGoals.first(where: { $0.id == goal.id }) ?? goal
        let progress = live.targetAmount == 0 ? 0 : live.currentAmount / live.targetAmount
        return VStack(alignment: .leading, spacing: 12) {
            Text(live.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            ProgressView(value: min(1, progress)) {
                Text("Progress")
                    .foregroundStyle(Color.appTextSecondary)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .tint(Color.appAccent)
            .progressViewStyle(.linear)
            .accessibilityValue("\(Int(min(100, progress * 100))) percent toward goal")

            Slider(
                value: Binding(
                    get: { data.savingsGoals.first(where: { $0.id == goal.id })?.currentAmount ?? 0 },
                    set: { data.updateSavingsGoal(id: goal.id, currentAmount: $0) }
                ),
                in: 0...max(live.targetAmount, 1)
            )
            .tint(Color.appAccent)

            if !live.milestones.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Checkpoints")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    ForEach(live.milestones.sorted(by: { $0.thresholdAmount < $1.thresholdAmount })) { ms in
                        HStack {
                            Toggle(isOn: Binding(
                                get: {
                                    data.savingsGoals.first(where: { $0.id == goal.id })?.milestones.first(where: { $0.id == ms.id })?.isComplete ?? false
                                },
                                set: { newValue in
                                    data.setGoalMilestoneComplete(goalId: goal.id, milestoneId: ms.id, isComplete: newValue)
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(ms.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.appPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Text(ms.thresholdAmount.formatted(.currency(code: "USD")))
                                        .font(.caption2)
                                        .foregroundStyle(Color.appTextSecondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            .tint(Color.appAccent)
                            Spacer()
                            Button(role: .destructive) {
                                data.removeGoalMilestone(goalId: goal.id, milestoneId: ms.id)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.appPrimary)
                            }
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel("Remove checkpoint")
                        }
                    }
                }
            }

            Button("Add checkpoint") {
                milestoneGoalId = goal.id
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.appAccent)
            .frame(minHeight: 44)
            .accessibilityHint("Adds a sub-target amount for this goal")

            Text(live.deadline.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .appSectionDepth(cornerRadius: 20, elevation: .floating)
    }

    private func labeledField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            TextField("", text: text)
                .keyboardType(keyboard)
                .padding(12)
                .appInsetWell(cornerRadius: 12)
        }
    }
}
