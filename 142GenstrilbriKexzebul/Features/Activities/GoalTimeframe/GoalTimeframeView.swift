import SwiftUI

struct GoalTimeframeView: View {
    @EnvironmentObject private var data: FinanceDataManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GoalTimeframeViewModel(difficulty: .medium, seed: GoalTimelinePayload(markers: [0.25, 0.55, 0.82], pinchScale: 1))
    @State private var completionRoute: SessionCompletionRoute?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Financial Milestones")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Pinch to scale the lane, drag each marker toward the guided checkpoints.")
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                timelineLane
                    .timelineCanvasLength(baseWidth: 320, scale: viewModel.pinchScale)
                    .frame(height: 220)
                    .padding(12)
                    .appSectionDepth(cornerRadius: 22, elevation: .floating)
                    .padding(.vertical, 8)
                    .gesture(
                        MagnificationGesture()
                            .onEnded { value in
                                let delta = (value - 1) * 0.08
                                viewModel.adjustPinchScale(by: delta)
                            }
                    )

                Text("Markers respond while you drag; aim for the dashed guide ticks.")
                    .font(.footnote)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)

                FinancePrimaryButton(title: "Evaluate timeline") {
                    let outcome = viewModel.finalizeSession()
                    data.registerGoalSession(stars: outcome.stars, payload: outcome.payload, metTargets: outcome.metTargets)
                    completionRoute = SessionCompletionRoute(
                        stars: outcome.stars,
                        headline: "Timeline reviewed",
                        detail: "Markers were compared with the recommended pacing curve.",
                        totalSavings: data.totalSavingsTracked,
                        goalCompletions: data.goalCompletionsTracked,
                        habitStreak: data.habitStreakRecord,
                        showAchievementBanner: data.achievementUnlocked
                    )
                }
            }
            .padding(16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.reload(difficulty: data.difficulty, seed: data.goalTimeline)
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

    private var timelineLane: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            ZStack {
                Canvas { context, size in
                    let baseline = size.height * 0.65
                    var path = Path()
                    path.move(to: CGPoint(x: 12, y: baseline))
                    path.addQuadCurve(
                        to: CGPoint(x: size.width - 12, y: baseline - 26),
                        control: CGPoint(x: size.width * 0.5, y: baseline + 40)
                    )
                    context.stroke(path, with: .color(Color.appAccent.opacity(0.55)), lineWidth: 4)

                    let guides: [CGFloat] = [0.33, 0.66, 0.94]
                    for gx in guides {
                        let x = gx * size.width
                        var tick = Path()
                        tick.move(to: CGPoint(x: x, y: baseline - 70))
                        tick.addLine(to: CGPoint(x: x, y: baseline + 10))
                        context.stroke(tick, with: .color(Color.appTextSecondary.opacity(0.35)), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                    }
                }

                ForEach(viewModel.markers.indices, id: \.self) { index in
                    GoalMarkerHandle(
                        index: index,
                        laneWidth: width,
                        laneHeight: height,
                        viewModel: viewModel
                    )
                }
            }
        }
    }
}

private struct GoalMarkerHandle: View {
    let index: Int
    let laneWidth: CGFloat
    let laneHeight: CGFloat
    @ObservedObject var viewModel: GoalTimeframeViewModel
    @State private var dragBaseline: CGFloat?

    var body: some View {
        let x = viewModel.markers[index] * laneWidth
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.appPrimary.opacity(0.95), Color.appPrimary.opacity(0.65)],
                    center: .topLeading,
                    startRadius: 2,
                    endRadius: 22
                )
            )
            .frame(width: 32, height: 32)
            .shadow(color: Color.appPrimary.opacity(0.45), radius: 6, x: 0, y: 3)
            .position(x: x, y: laneHeight * 0.58)
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragBaseline == nil {
                            dragBaseline = viewModel.markers[index]
                        }
                        let origin = (dragBaseline ?? viewModel.markers[index]) * laneWidth
                        let proposed = origin + value.translation.width
                        viewModel.updateMarker(index: index, normalizedX: proposed / laneWidth)
                    }
                    .onEnded { _ in
                        dragBaseline = nil
                    }
            )
    }
}
