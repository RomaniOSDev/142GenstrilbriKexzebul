import SwiftUI

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        let points = 5
        let angleAdjustment = CGFloat.pi / 2
        for index in 0..<(points * 2) {
            let angle = CGFloat(index) * .pi / CGFloat(points) - angleAdjustment
            let r = index.isMultiple(of: 2) ? radius : radius * 0.45
            let point = CGPoint(
                x: center.x + cos(angle) * r,
                y: center.y + sin(angle) * r
            )
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

struct StarRatingDisplay: View {
    let filled: Int
    let total: Int
    var glow: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                StarShape()
                    .fill(index < filled ? Color.appAccent : Color.appTextSecondary.opacity(0.35))
                    .frame(width: 28, height: 28)
                    .shadow(color: glow && index < filled ? Color.appAccent.opacity(0.65) : .clear, radius: 10)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(filled) of \(total) stars")
    }
}
