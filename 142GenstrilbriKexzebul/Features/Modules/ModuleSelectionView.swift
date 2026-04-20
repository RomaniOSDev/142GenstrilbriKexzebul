import SwiftUI

struct ModuleSelectionView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @State private var showAddModule = false
    @State private var editingModule: UserLearningModule?
    @State private var selectedTagFilter = "All"
    @State private var editMode = EditMode.inactive

    private var tagFilters: [String] {
        let tags = Set(data.userLearningModules.map(\.tag)).sorted()
        return ["All"] + tags
    }

    private var displayedUserModules: [UserLearningModule] {
        data.sortedUserLearningModules.filter { selectedTagFilter == "All" || $0.tag == selectedTagFilter }
    }

    var body: some View {
        List {
            Section {
                builtInRow(
                    title: "Savings Goals",
                    detail: "Shape timelines and checkpoints",
                    activity: .goalTimeframe
                )
                builtInRow(
                    title: "Expense Management",
                    detail: "Architect a disciplined monthly split",
                    activity: .budgetArchitect
                )
                builtInRow(
                    title: "Financial Reports",
                    detail: "Log daily signals that reinforce habits",
                    activity: .habitStreak
                )
            } header: {
                sectionHeader(
                    title: "Learning modules",
                    subtitle: "Each track blends guidance with measurable progress."
                )
            }

            Section {
                Picker("Filter by tag", selection: $selectedTagFilter) {
                    ForEach(tagFilters, id: \.self) { tag in
                        Text(tag).tag(tag)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Filter custom modules by tag")

                if selectedTagFilter != "All" {
                    Text("Reordering is available when the tag filter is set to All.")
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                }

                if data.userLearningModules.isEmpty {
                    Text("No custom modules yet. Tap Add to create one.")
                        .font(.footnote)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .listRowBackground(Color.clear)
                }

                if selectedTagFilter == "All" {
                    ForEach(data.sortedUserLearningModules) { module in
                        userModuleRow(module: module)
                    }
                    .onMove { source, destination in
                        data.moveUserModules(from: source, to: destination)
                    }
                } else {
                    ForEach(displayedUserModules) { module in
                        userModuleRow(module: module)
                    }
                }
            } header: {
                sectionHeader(
                    title: "My modules",
                    subtitle: "Independent progress blends with the linked session track. Swipe left on a row to delete."
                )
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if selectedTagFilter == "All" {
                    EditButton()
                        .foregroundStyle(Color.appPrimary)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Reorder custom modules")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    showAddModule = true
                }
                .foregroundStyle(Color.appPrimary)
                .frame(minHeight: 44)
                .accessibilityLabel("Add custom module")
            }
        }
        .sheet(isPresented: $showAddModule) {
            AddUserModuleSheet(onDismiss: { showAddModule = false })
                .environmentObject(data)
        }
        .sheet(item: $editingModule) { module in
            EditUserModuleSheet(module: module, onDismiss: { editingModule = nil })
                .environmentObject(data)
        }
        .onChange(of: selectedTagFilter) { newTag in
            if newTag != "All" {
                editMode = .inactive
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(5)
                .minimumScaleFactor(0.7)
        }
        .textCase(nil)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func builtInRow(title: String, detail: String, activity: FinanceActivityKind) -> some View {
        let unlocked = data.isActivityUnlocked(activity)
        let progress = data.moduleProgress(for: activity)
        if unlocked {
            NavigationLink {
                destinationView(for: activity)
            } label: {
                moduleLabel(title: title, detail: detail, progress: progress, unlocked: true, tagLine: nil)
            }
        } else {
            moduleLabel(title: title, detail: detail, progress: progress, unlocked: false, tagLine: nil)
                .opacity(0.55)
        }
    }

    @ViewBuilder
    private func userModuleRow(module: UserLearningModule) -> some View {
        let unlocked = data.isActivityUnlocked(module.linkedActivity)
        let progress = data.combinedModuleProgress(module)
        Group {
            if unlocked {
                NavigationLink {
                    destinationView(for: module.linkedActivity)
                } label: {
                    moduleLabel(
                        title: module.title,
                        detail: module.detail,
                        progress: progress,
                        unlocked: true,
                        tagLine: "Tag: \(module.tag)"
                    )
                }
            } else {
                moduleLabel(
                    title: module.title,
                    detail: module.detail,
                    progress: progress,
                    unlocked: false,
                    tagLine: "Tag: \(module.tag)"
                )
                .opacity(0.55)
            }
        }
        .contextMenu {
            Button("Edit module") {
                if let fresh = data.userLearningModules.first(where: { $0.id == module.id }) {
                    editingModule = fresh
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                data.removeUserModule(id: module.id)
            } label: {
                Text("Delete")
            }
        }
    }

    @ViewBuilder
    private func destinationView(for activity: FinanceActivityKind) -> some View {
        switch activity {
        case .budgetArchitect:
            BudgetArchitectView()
        case .habitStreak:
            HabitStreakView()
        case .goalTimeframe:
            GoalTimeframeView()
        }
    }

    private func moduleLabel(title: String, detail: String, progress: Double, unlocked: Bool, tagLine: String?) -> some View {
        HStack(spacing: 16) {
            ModuleCircularProgressView(progress: progress)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                if let tagLine {
                    Text(tagLine)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text(unlocked ? "Continue" : "Locked until prerequisites complete")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct AddUserModuleSheet: View {
    @EnvironmentObject private var data: FinanceDataManager
    @Environment(\.dismiss) private var dismiss
    var onDismiss: () -> Void

    @State private var titleText = ""
    @State private var detailText = ""
    @State private var linkedActivity: FinanceActivityKind = .budgetArchitect
    @State private var tagSelection = "General"

    private let presetTags = ["General", "Work", "Family", "Health", "Other"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("New module")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        TextField("Short name", text: $titleText)
                            .padding(12)
                            .appInsetWell(cornerRadius: 12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        TextField("What this module covers", text: $detailText, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .appInsetWell(cornerRadius: 12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linked session")
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Picker("Linked session", selection: $linkedActivity) {
                            ForEach(FinanceActivityKind.allCases) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .appInsetWell(cornerRadius: 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tag")
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Picker("Tag", selection: $tagSelection) {
                            ForEach(presetTags, id: \.self) { tag in
                                Text(tag).tag(tag)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .appInsetWell(cornerRadius: 12)

                    FinancePrimaryButton(title: "Save module") {
                        data.addUserModule(title: titleText, detail: detailText, linkedActivity: linkedActivity, tag: tagSelection)
                        titleText = ""
                        detailText = ""
                        onDismiss()
                        dismiss()
                    }
                    .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                }
                .padding(16)
            }
            .appChromeBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minHeight: 44)
                }
            }
        }
    }
}

private struct EditUserModuleSheet: View {
    @EnvironmentObject private var data: FinanceDataManager
    @Environment(\.dismiss) private var dismiss
    let module: UserLearningModule
    var onDismiss: () -> Void

    @State private var titleText: String
    @State private var detailText: String
    @State private var progress: Double
    @State private var tagSelection: String

    private let presetTags = ["General", "Work", "Family", "Health", "Other"]

    init(module: UserLearningModule, onDismiss: @escaping () -> Void) {
        self.module = module
        self.onDismiss = onDismiss
        _titleText = State(initialValue: module.title)
        _detailText = State(initialValue: module.detail)
        _progress = State(initialValue: module.independentProgress)
        _tagSelection = State(initialValue: module.tag)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Edit module")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        TextField("Title", text: $titleText)
                            .padding(12)
                            .appInsetWell(cornerRadius: 12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        TextField("Description", text: $detailText, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .appInsetWell(cornerRadius: 12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Independent progress")
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Slider(value: $progress, in: 0...1)
                            .tint(Color.appAccent)
                        Text("Combined ring uses the higher of this value and the linked session track.")
                            .font(.caption)
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(4)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(12)
                    .appInsetWell(cornerRadius: 12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tag")
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Picker("Tag", selection: $tagSelection) {
                            ForEach(presetTags, id: \.self) { tag in
                                Text(tag).tag(tag)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(12)
                    .appInsetWell(cornerRadius: 12)

                    Text("Linked session: \(module.linkedActivity.title)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    FinancePrimaryButton(title: "Save changes") {
                        var updated = module
                        updated.title = titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? module.title : titleText.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.detail = detailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? module.detail : detailText.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.independentProgress = progress
                        updated.tag = tagSelection
                        data.updateUserModule(updated)
                        onDismiss()
                        dismiss()
                    }
                }
                .padding(16)
            }
            .appChromeBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                        dismiss()
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(minHeight: 44)
                }
            }
        }
    }
}
