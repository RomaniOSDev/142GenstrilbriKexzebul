import SwiftUI

/// View modifiers used by guided activities (e.g. timeline lane sizing).
enum ActivityModifiers {
    struct TimelineCanvasLength: ViewModifier {
        var baseWidth: CGFloat
        var scale: CGFloat

        func body(content: Content) -> some View {
            content
                .frame(width: max(260, baseWidth * scale))
        }
    }
}

extension View {
    func timelineCanvasLength(baseWidth: CGFloat, scale: CGFloat) -> some View {
        modifier(ActivityModifiers.TimelineCanvasLength(baseWidth: baseWidth, scale: scale))
    }
}
