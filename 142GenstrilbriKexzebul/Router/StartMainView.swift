//
//  StartMainView.swift
//  142GenstrilbriKexzebul
//

import SwiftUI

struct DualAnnulusSpinner: View {
    var progress: Double
    @State private var rotationAngle: Double = 0.0
    var width: CGFloat = 72
    var height: CGFloat = 72

    private let segmentLength: Double = 0.35

    var body: some View {
        let lineW = width / 15
        let tailGradient = AngularGradient(
            colors: [.clear, .white.opacity(0.4), .white],
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(segmentLength * 360)
        )

        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.2), lineWidth: lineW)
                .frame(width: width, height: height)
                .offset(y: 3)
                .blur(radius: 2)

            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.gray.opacity(0.4),
                            Color.gray.opacity(0.25),
                            Color.white.opacity(0.3)
                        ],
                        center: .center
                    ),
                    lineWidth: lineW
                )
                .frame(width: width, height: height)
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            segmentArc(gradient: tailGradient, lineW: lineW, angle: rotationAngle)
            segmentArc(gradient: tailGradient, lineW: lineW, angle: rotationAngle + 180)

            if progress > 0.5 {
                TerminalCheckmarkGlyph()
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
        .onChange(of: progress) { newProgress in
            if newProgress >= 100 {
                rotationAngle = 0
            }
        }
    }

    private func segmentArc(gradient: AngularGradient, lineW: CGFloat, angle: Double) -> some View {
        Circle()
            .trim(from: 0.0, to: segmentLength)
            .stroke(
                gradient,
                style: StrokeStyle(lineWidth: lineW, lineCap: .round)
            )
            .frame(width: width, height: height)
            .rotationEffect(.degrees(angle))
            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
            .shadow(color: .white.opacity(0.6), radius: 1)
    }
}

struct TerminalCheckmarkGlyph: View {
    private let greenColor = Color.green

    var body: some View {
        ZStack {
            Circle()
                .foregroundStyle(greenColor)
                .frame(width: 72, height: 72)
                .opacity(0.3)
                .shadow(color: greenColor.opacity(0.4), radius: 8)
            Circle()
                .foregroundStyle(greenColor)
                .frame(width: 60, height: 60)
                .opacity(0.6)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            Circle()
                .foregroundStyle(greenColor)
                .frame(width: 48, height: 48)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                .shadow(color: greenColor.opacity(0.5), radius: 4)
            Image(systemName: "checkmark")
                .resizable()
                .frame(width: 18, height: 13)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
        }
    }
}

struct BootstrapSplashSurface: View {
    var body: some View {
        ZStack {
            Image(.lader)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.35),
                    Color.black.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                DualAnnulusSpinner(progress: 0)

                Text("Loading...")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                Spacer()
                    .frame(height: 80)
            }
        }
    }
}

#Preview {
    BootstrapSplashSurface()
}
