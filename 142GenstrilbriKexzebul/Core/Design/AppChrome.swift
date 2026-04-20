import SwiftUI

// MARK: - Screen mesh

/// Layered mesh behind scrollable content (replaces flat `Color.appBackground`).
struct AppChromeBackground: View {
    var body: some View {
        ZStack {
            Color.appBackground
            LinearGradient(
                colors: [
                    Color.appAccent.opacity(0.14),
                    Color.appBackground.opacity(0.98),
                    Color.appPrimary.opacity(0.10),
                    Color.appBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color.appAccent.opacity(0.22), Color.clear],
                center: UnitPoint(x: 0.88, y: 0.06),
                startRadius: 8,
                endRadius: 380
            )
            RadialGradient(
                colors: [Color.appPrimary.opacity(0.16), Color.clear],
                center: UnitPoint(x: 0.1, y: 0.9),
                startRadius: 20,
                endRadius: 320
            )
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Elevation

enum AppChromeElevation {
    /// Sections, list-style rows.
    case card
    /// Home widgets, featured blocks.
    case floating
    /// Hero metrics, primary callouts.
    case hero
}

private struct AppDepthPlate: View {
    var cornerRadius: CGFloat
    var elevation: AppChromeElevation
    var accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.appSurface)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.055),
                            Color.clear,
                            Color.primary.opacity(0.025)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .shadow(color: shadowPrimary.color, radius: shadowPrimary.radius, x: 0, y: shadowPrimary.y)
        .shadow(color: shadowSecondary.color, radius: shadowSecondary.radius, x: 0, y: shadowSecondary.y)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [accent.opacity(0.48), Color.appPrimary.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var shadowPrimary: (color: Color, radius: CGFloat, y: CGFloat) {
        switch elevation {
        case .card:
            return (Color.black.opacity(0.10), 16, 9)
        case .floating:
            return (Color.black.opacity(0.12), 22, 12)
        case .hero:
            return (Color.black.opacity(0.14), 28, 16)
        }
    }

    private var shadowSecondary: (color: Color, radius: CGFloat, y: CGFloat) {
        switch elevation {
        case .card:
            return (Color.appAccent.opacity(0.08), 14, 8)
        case .floating:
            return (Color.appPrimary.opacity(0.10), 18, 10)
        case .hero:
            return (Color.appAccent.opacity(0.12), 22, 12)
        }
    }
}

private struct AppInsetWellPlate: View {
    var cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.appSurface,
                        Color.appSurface.opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.appAccent.opacity(0.32), Color.appPrimary.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
            .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
    }
}

// MARK: - View extensions

extension View {
    func appChromeBackground() -> some View {
        background(AppChromeBackground().ignoresSafeArea())
    }

    func appSectionDepth(
        cornerRadius: CGFloat = 18,
        elevation: AppChromeElevation = .card,
        accent: Color = Color.appAccent
    ) -> some View {
        background(AppDepthPlate(cornerRadius: cornerRadius, elevation: elevation, accent: accent))
    }

    /// Text fields and compact inputs.
    func appInsetWell(cornerRadius: CGFloat = 12) -> some View {
        background(AppInsetWellPlate(cornerRadius: cornerRadius))
    }
}
