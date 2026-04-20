import Combine
import CoreGraphics
import Foundation
import SwiftUI

@MainActor
final class GoalTimeframeViewModel: ObservableObject {
    @Published var markers: [CGFloat]
    @Published var pinchScale: CGFloat

    private var difficulty: FinanceDifficulty
    private let ideal: [CGFloat] = [0.33, 0.66, 0.94]

    init(difficulty: FinanceDifficulty, seed: GoalTimelinePayload) {
        self.difficulty = difficulty
        pinchScale = CGFloat(seed.pinchScale)
        markers = seed.markers.map { CGFloat($0) }
        if markers.count < 3 {
            markers = [0.25, 0.55, 0.82]
        }
    }

    func reload(difficulty: FinanceDifficulty, seed: GoalTimelinePayload) {
        self.difficulty = difficulty
        pinchScale = CGFloat(seed.pinchScale)
        markers = seed.markers.map { CGFloat($0) }
        if markers.count < 3 {
            markers = [0.25, 0.55, 0.82]
        }
    }

    func updateMarker(index: Int, normalizedX: CGFloat) {
        let clamped = min(0.98, max(0.02, normalizedX))
        markers[index] = clamped
    }

    func adjustPinchScale(by delta: CGFloat) {
        let next = min(1.6, max(0.7, pinchScale + delta))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            pinchScale = next
        }
    }

    func finalizeSession() -> GoalSessionOutcome {
        let tolerance = CGFloat(difficulty.goalMarkerTolerance)
        var met = 0
        for (user, target) in zip(markers, ideal) {
            if abs(user - target) <= tolerance {
                met += 1
            }
        }
        let averageGap = zip(markers, ideal).map { abs($0 - $1) }.reduce(0, +) / CGFloat(ideal.count)
        let stars: Int
        if met == 3 {
            stars = 3
        } else if met == 2 || averageGap <= tolerance * 2 {
            stars = 2
        } else if met == 1 {
            stars = 1
        } else {
            stars = 0
        }
        let payload = GoalTimelinePayload(
            markers: markers.map { Double($0) },
            pinchScale: Double(pinchScale)
        )
        return GoalSessionOutcome(stars: stars, payload: payload, metTargets: met)
    }
}

struct GoalSessionOutcome {
    let stars: Int
    let payload: GoalTimelinePayload
    let metTargets: Int
}
