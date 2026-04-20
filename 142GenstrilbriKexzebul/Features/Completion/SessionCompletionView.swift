import SwiftUI

struct SessionCompletionView: View {
    let route: SessionCompletionRoute
    var onNextSession: () -> Void
    var onViewProgress: () -> Void
    var onHome: () -> Void

    @State private var visibleStars = 0
    @State private var bannerOffset: CGFloat = -240

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if route.showAchievementBanner {
                        achievementBanner
                            .offset(y: bannerOffset)
                            .animation(.easeInOut(duration: 2), value: bannerOffset)
                    }

                    Text(route.headline)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)

                    Text(route.detail)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .minimumScaleFactor(0.7)

                    StarRatingDisplay(filled: visibleStars, total: 3, glow: true)
                        .padding(.vertical, 8)

                    statsGrid

                    VStack(spacing: 12) {
                        FinancePrimaryButton(title: "Next Session") {
                            onNextSession()
                        }
                        FinancePrimaryButton(title: "View Progress") {
                            onViewProgress()
                        }
                        Button("Home") {
                            onHome()
                        }
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.appSurface.opacity(0.4))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.appAccent, Color.appPrimary.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(16)
            }
            .appChromeBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            animateStars()
            if route.showAchievementBanner {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    bannerOffset = 0
                }
            }
        }
    }

    private var achievementBanner: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.appAccent)
                .frame(width: 10, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement unlocked")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("You crossed a sustained progress threshold.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextPrimary.opacity(0.85))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appPrimary, Color.appPrimary.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.appPrimary.opacity(0.4), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 4)
    }

    private var statsGrid: some View {
        VStack(spacing: 12) {
            statRow(title: "Tracked savings total", value: route.totalSavings.formatted(.currency(code: "USD")))
            statRow(title: "Goal checkpoints met", value: "\(route.goalCompletions)")
            statRow(title: "Best habit streak", value: "\(route.habitStreak) days")
        }
        .padding(16)
        .appSectionDepth(cornerRadius: 20, elevation: .floating)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func animateStars() {
        visibleStars = 0
        for index in 0..<min(route.stars, 3) {
            let delay = Double(index) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    visibleStars = index + 1
                }
            }
        }
    }
}
