import SwiftUI

enum Theme {
    // Cinematic palette: deep indigo backdrops + warm amber accent
    static let bg = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let bgElevated = Color(red: 0.09, green: 0.10, blue: 0.14)
    static let card = Color(red: 0.12, green: 0.13, blue: 0.18)
    static let cardHover = Color(red: 0.16, green: 0.17, blue: 0.22)
    static let stroke = Color.white.opacity(0.08)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.4)

    static let accent = Color(red: 1.0, green: 0.72, blue: 0.29)       // amber
    static let accentSoft = Color(red: 1.0, green: 0.85, blue: 0.55)
    static let magenta = Color(red: 0.92, green: 0.35, blue: 0.62)
    static let teal = Color(red: 0.28, green: 0.78, blue: 0.82)
    static let violet = Color(red: 0.56, green: 0.43, blue: 0.95)
    static let lime = Color(red: 0.62, green: 0.88, blue: 0.42)
    static let coral = Color(red: 1.00, green: 0.54, blue: 0.46)

    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.25, green: 0.12, blue: 0.40),
            Color(red: 0.55, green: 0.18, blue: 0.35),
            Color(red: 0.95, green: 0.45, blue: 0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct FullHitPlainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}

extension ButtonStyle where Self == FullHitPlainButtonStyle {
    static var plainSolid: FullHitPlainButtonStyle { FullHitPlainButtonStyle() }
}
