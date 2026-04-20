import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @State private var page = 0

    private var ctaTitle: String {
        page < 2 ? "Continue" : "Get started"
    }

    var body: some View {
        VStack(spacing: 0) {
            topProgress

            TabView(selection: $page) {
                OnboardingIllustrationIncome(isActive: page == 0)
                    .tag(0)
                OnboardingIllustrationBalance(isActive: page == 1)
                    .tag(1)
                OnboardingIllustrationPathway(isActive: page == 2)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            bottomPanel
        }
    }

    private var topProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Welcome")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer()
                Text("Step \(page + 1) of 3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }
            .padding(.horizontal, 24)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appTextSecondary.opacity(0.15))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent, Color.appPrimary.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(page + 1) / 3))
                        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: page)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 24)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var bottomPanel: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                ForEach(0 ..< 3, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Color.appAccent : Color.appTextSecondary.opacity(0.22))
                        .frame(width: index == page ? 28 : 9, height: 9)
                        .animation(.spring(response: 0.4, dampingFraction: 0.78), value: page)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Onboarding step \(page + 1) of 3")

            FinancePrimaryButton(title: ctaTitle) {
                if page < 2 {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                        page += 1
                    }
                } else {
                    data.finishOnboarding()
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.14), radius: 24, x: 0, y: -8)
            .shadow(color: Color.appAccent.opacity(0.12), radius: 18, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }
}

// MARK: - Shared step chrome

private struct OnboardingStepFrame<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @ViewBuilder var illustration: () -> Content

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(systemName: systemImage)
                    .font(.system(size: 36, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.appPrimary, Color.appAccent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .appSectionDepth(cornerRadius: 22, elevation: .floating, accent: Color.appAccent)
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    Text(title)
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.appPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 8)

                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(5)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 12)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 14)
                .appSectionDepth(cornerRadius: 22, elevation: .card)

                illustration()
                    .frame(maxWidth: .infinity)
                    .padding(18)
                    .appSectionDepth(cornerRadius: 28, elevation: .floating)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }
}

// MARK: - Steps

private struct OnboardingIllustrationIncome: View {
    let isActive: Bool
    @State private var progress: CGFloat = 0

    var body: some View {
        OnboardingStepFrame(
            title: "Clarity starts with structure",
            subtitle: "See how steady inputs grow into bars you can read at a glance — that mindset powers your dashboard.",
            systemImage: "chart.bar.fill"
        ) {
            Canvas { context, size in
                guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return }
                let barWidth: CGFloat = 36
                let spacing: CGFloat = 18
                let heights: [CGFloat] = [0.35, 0.55, 0.75, 0.5].map { $0 * size.height * progress }
                for (index, height) in heights.enumerated() {
                    let x = 24 + CGFloat(index) * (barWidth + spacing)
                    let rect = CGRect(x: x, y: size.height - height - 24, width: barWidth, height: height)
                    let path = RoundedRectangle(cornerRadius: 10, style: .continuous).path(in: rect)
                    let color = index.isMultiple(of: 2) ? Color.appPrimary : Color.appAccent
                    context.fill(path, with: .color(color.opacity(0.88)))
                    context.stroke(path, with: .color(Color.primary.opacity(0.08)), lineWidth: 1)
                }
            }
            .frame(height: 240)
        }
        .onAppear { runAnimationIfActive() }
        .onChange(of: isActive) { _ in runAnimationIfActive() }
    }

    private func runAnimationIfActive() {
        guard isActive else { return }
        progress = 0
        withAnimation(.easeInOut(duration: 1.05)) {
            progress = 1
        }
    }
}

private struct OnboardingIllustrationBalance: View {
    let isActive: Bool
    @State private var sweep: CGFloat = 0

    var body: some View {
        OnboardingStepFrame(
            title: "Balance signals confidence",
            subtitle: "A calm ring mirrors how close you are to an even split — the same logic guides budget sessions in the app.",
            systemImage: "circle.circle"
        ) {
            Canvas { context, size in
                guard size.width.isFinite, size.height.isFinite else { return }
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 28
                var base = Path()
                base.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                context.stroke(base, with: .color(Color.appTextSecondary.opacity(0.22)), lineWidth: 14)

                var arc = Path()
                let endDegrees = -90.0 + 360.0 * Double(sweep)
                arc.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(endDegrees), clockwise: false)
                context.stroke(arc, with: .color(Color.appAccent), style: StrokeStyle(lineWidth: 14, lineCap: .round))
            }
            .frame(height: 240)
        }
        .onAppear { runAnimationIfActive() }
        .onChange(of: isActive) { _ in runAnimationIfActive() }
    }

    private func runAnimationIfActive() {
        guard isActive else { return }
        sweep = 0
        withAnimation(.easeInOut(duration: 1.15)) {
            sweep = 0.82
        }
    }
}

private struct OnboardingIllustrationPathway: View {
    let isActive: Bool
    @State private var trim: CGFloat = 0

    var body: some View {
        OnboardingStepFrame(
            title: "Momentum follows a path",
            subtitle: "Trace progress along a curve, then act with intent — timelines and goals in the app are built around that rhythm.",
            systemImage: "chart.line.uptrend.xyaxis"
        ) {
            Canvas { context, size in
                guard size.width.isFinite, size.height.isFinite else { return }
                var path = Path()
                path.move(to: CGPoint(x: 20, y: size.height * 0.72))
                path.addCurve(
                    to: CGPoint(x: size.width - 20, y: size.height * 0.32),
                    control1: CGPoint(x: size.width * 0.33, y: size.height * 0.2),
                    control2: CGPoint(x: size.width * 0.66, y: size.height * 0.85)
                )
                let trimmed = path.trimmedPath(from: 0, to: trim)
                context.stroke(trimmed, with: .color(Color.appPrimary), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))

                if trim > 0.65 {
                    let focus = CGPoint(x: size.width * 0.78, y: size.height * 0.34)
                    let glow = Path(ellipseIn: CGRect(x: focus.x - 12, y: focus.y - 12, width: 24, height: 24))
                    context.fill(glow, with: .color(Color.appAccent.opacity(0.55)))
                    context.stroke(glow, with: .color(Color.appAccent.opacity(0.9)), lineWidth: 2)
                }
            }
            .frame(height: 240)
        }
        .onAppear { runAnimationIfActive() }
        .onChange(of: isActive) { _ in runAnimationIfActive() }
    }

    private func runAnimationIfActive() {
        guard isActive else { return }
        trim = 0
        withAnimation(.easeInOut(duration: 1.35)) {
            trim = 1
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(FinanceDataManager())
        .appChromeBackground()
}
