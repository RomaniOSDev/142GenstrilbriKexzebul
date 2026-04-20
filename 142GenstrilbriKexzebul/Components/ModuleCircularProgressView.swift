import SwiftUI

/// Determinate ring (avoids indeterminate `ProgressView` spinner with circular style in lists).
struct ModuleCircularProgressView: View {
    var progress: Double

    private var clamped: CGFloat {
        CGFloat(min(1, max(0, progress)))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appTextSecondary.opacity(0.28), lineWidth: 6)
            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Color.appAccent,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 48, height: 48)
        .shadow(color: Color.appAccent.opacity(0.28), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clamped * 100)) percent")
    }
}
