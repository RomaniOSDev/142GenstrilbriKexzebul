import SwiftUI

struct FinancePrimaryButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.horizontal, 16)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appPrimary,
                                        Color.appPrimary.opacity(0.78)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                    }
                    .shadow(color: Color.appPrimary.opacity(0.45), radius: 14, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
}
