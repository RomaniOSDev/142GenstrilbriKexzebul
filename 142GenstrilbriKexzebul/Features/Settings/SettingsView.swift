import StoreKit
import SwiftUI
import UIKit

private enum TempExport {
    static func csvURL(from data: FinanceDataManager) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("finance-export-\(UUID().uuidString).csv")
        try data.exportCSVString().write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func pdfURL(from data: FinanceDataManager) throws -> URL {
        let payload = data.exportPDFData() ?? Data()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("finance-report-\(UUID().uuidString).pdf")
        try payload.write(to: url)
        return url
    }
}

struct SettingsView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @State private var confirmReset = false
    @State private var refreshToken = UUID()
    @State private var habitName0 = ""
    @State private var habitName1 = ""
    @State private var habitName2 = ""
    @State private var csvURL: URL?
    @State private var pdfURL: URL?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                appearanceSection

                notificationsSection

                habitNamesSection

                exportSection

                ratePrivacyTermsSection

                NavigationLink {
                    CategoryBudgetsView()
                } label: {
                    HStack {
                        Text("Category spending caps")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.appPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Color.appTextSecondary)
                            .accessibilityHidden(true)
                    }
                    .padding(16)
                    .appSectionDepth(cornerRadius: 20, elevation: .floating)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens screen to set monthly limits per category")

                difficultySection

                statisticsSection

                FinancePrimaryButton(title: "Reset All Progress") {
                    confirmReset = true
                }
                .accessibilityHint("Clears all stored progress on this device")
            }
            .padding(16)
            .id(refreshToken)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            syncHabitFields()
            prepareExportURLs()
        }
        .onChange(of: data.habitData.habitNames) { _ in
            syncHabitFields()
        }
        .alert("Reset everything?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                data.resetAll()
                refreshToken = UUID()
            }
        } message: {
            Text("This clears onboarding, sessions, stars, goals, history, modules, limits, and reminders on this device.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .financeDataDidReset)) { _ in
            refreshToken = UUID()
            prepareExportURLs()
        }
    }

    private var ratePrivacyTermsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Support & legal")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            VStack(spacing: 0) {
                legalActionRow(
                    title: "Rate us",
                    subtitle: "Share feedback in the App Store",
                    systemImage: "star.fill",
                    accessibilityHint: "Requests the system rating prompt"
                ) {
                    Self.rateApp()
                }
                legalDivider
                legalActionRow(
                    title: AppExternalLink.privacyPolicy.title,
                    subtitle: "How we handle your data",
                    systemImage: "hand.raised.fill",
                    accessibilityHint: "Opens privacy policy in Safari"
                ) {
                    Self.openPolicy(.privacyPolicy)
                }
                legalDivider
                legalActionRow(
                    title: AppExternalLink.termsOfUse.title,
                    subtitle: "Rules for using the app",
                    systemImage: "doc.text.fill",
                    accessibilityHint: "Opens terms of use in Safari"
                ) {
                    Self.openPolicy(.termsOfUse)
                }
            }
            .appSectionDepth(cornerRadius: 20, elevation: .card)
        }
    }

    private var legalDivider: some View {
        Divider()
            .padding(.leading, 52)
    }

    private func legalActionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
                    .frame(width: 28, alignment: .center)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(minHeight: 48)
        .accessibilityHint(accessibilityHint)
    }

    private static func openPolicy(_ link: AppExternalLink) {
        if let url = link.url {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private static func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Appearance")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Picker("Appearance", selection: Binding(
                get: { data.appearanceMode },
                set: { data.setAppearanceMode($0) }
            )) {
                ForEach(AppAppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Color appearance")
            Text("Light and dark styles use colors from the asset catalog.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 20, elevation: .card)
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reminders")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Toggle("Daily habit reminder", isOn: Binding(
                get: { data.notificationsHabitsEnabled },
                set: { data.setNotificationPreferences(habits: $0, budget: data.notificationsBudgetEnabled, hour: data.notificationHour, minute: data.notificationMinute) }
            ))
            .tint(Color.appAccent)
            .accessibilityHint("Schedules a daily notification to log habits")

            Toggle("Monthly budget reminder", isOn: Binding(
                get: { data.notificationsBudgetEnabled },
                set: { data.setNotificationPreferences(habits: data.notificationsHabitsEnabled, budget: $0, hour: data.notificationHour, minute: data.notificationMinute) }
            ))
            .tint(Color.appAccent)
            .accessibilityHint("Schedules a monthly notification on the first day of each month")

            DatePicker(
                "Preferred time",
                selection: Binding(
                    get: {
                        Calendar.current.date(bySettingHour: data.notificationHour, minute: data.notificationMinute, second: 0, of: Date()) ?? Date()
                    },
                    set: { newDate in
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        data.setNotificationPreferences(
                            habits: data.notificationsHabitsEnabled,
                            budget: data.notificationsBudgetEnabled,
                            hour: parts.hour ?? 9,
                            minute: parts.minute ?? 0
                        )
                    }
                ),
                displayedComponents: [.hourAndMinute]
            )
            .tint(Color.appAccent)
            .accessibilityLabel("Preferred reminder time")

            Button("Request notification permission") {
                FinanceNotificationScheduler.requestAuthorizationIfNeeded { granted in
                    if granted {
                        data.refreshNotificationScheduleFromStoredPrefs()
                    }
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.appPrimary)
            .frame(minHeight: 44)
            .accessibilityHint("Asks the system to allow scheduled reminders")
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 20, elevation: .card)
    }

    private var habitNamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Habit labels")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Three short labels used in the Financial Habits session.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            habitField(title: "Habit 1", text: $habitName0)
            habitField(title: "Habit 2", text: $habitName1)
            habitField(title: "Habit 3", text: $habitName2)
            FinancePrimaryButton(title: "Save habit labels") {
                data.updateHabitNames([habitName0, habitName1, habitName2])
            }
            .accessibilityHint("Saves the three habit titles used in the habits activity")
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 20, elevation: .card)
    }

    private func habitField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            TextField("", text: text)
                .padding(12)
                .appInsetWell(cornerRadius: 12)
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Share CSV with transactions, recurring items, and category limits, or a short PDF summary.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(4)
                .minimumScaleFactor(0.7)

            if let csvURL {
                ShareLink(item: csvURL, subject: Text("Finance export"), message: Text("CSV export")) {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.78)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.appPrimary.opacity(0.35), radius: 10, x: 0, y: 6)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the share sheet with a comma separated file")
            }

            if let pdfURL {
                ShareLink(item: pdfURL, subject: Text("Finance summary"), message: Text("PDF summary")) {
                    Label("Share PDF summary", systemImage: "doc.richtext")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appAccent.opacity(0.75)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.appAccent.opacity(0.38), radius: 10, x: 0, y: 6)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the share sheet with a short PDF report")
            }
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 20, elevation: .card)
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Difficulty")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Picker("Difficulty", selection: Binding(
                get: { data.difficulty },
                set: { data.setDifficulty($0) }
            )) {
                ForEach(FinanceDifficulty.allCases) { level in
                    Text(level.title).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Text("Higher difficulty tightens tolerances, reduces lives in budgeting, and expects longer habit streaks for top marks.")
                .font(.footnote)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(4)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 20, elevation: .card)
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            statLine("Budget sessions", value: "\(data.completedBudgetSessions)")
            statLine("Habit sessions", value: "\(data.completedHabitSessions)")
            statLine("Timeline sessions", value: "\(data.completedGoalSessions)")
            statLine("Total stars earned", value: "\(data.totalEarnedStars())")
            statLine("Tracked savings total", value: data.totalSavingsTracked.formatted(.currency(code: "USD")))
            statLine("Goal checkpoints met", value: "\(data.goalCompletionsTracked)")
            statLine("Best habit streak", value: "\(data.habitStreakRecord) days")
            statLine("This month spending", value: data.totalSpendThisMonth().formatted(.currency(code: "USD")))
            statLine("Last month spending", value: data.totalSpendPreviousMonth().formatted(.currency(code: "USD")))
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 20, elevation: .card)
    }

    private func statLine(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func syncHabitFields() {
        let names = data.habitData.habitNames
        if names.count == 3 {
            habitName0 = names[0]
            habitName1 = names[1]
            habitName2 = names[2]
        }
    }

    private func prepareExportURLs() {
        csvURL = try? TempExport.csvURL(from: data)
        pdfURL = try? TempExport.pdfURL(from: data)
    }
}
