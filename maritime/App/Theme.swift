import SwiftUI

enum Theme {
    // Maritime palette: near-black surfaces + saturated cobalt accent
    static let bg = Color(red: 0.031, green: 0.035, blue: 0.047)         // #08090C
    static let bgElevated = Color(red: 0.055, green: 0.063, blue: 0.082) // #0E1015
    static let card = Color(red: 0.086, green: 0.098, blue: 0.133)       // #161922
    static let cardHover = Color(red: 0.106, green: 0.122, blue: 0.165)  // #1B1F2A
    static let stroke = Color.white.opacity(0.08)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.45)

    // Single primary accent — saturated cobalt
    static let accent = Color(red: 0.204, green: 0.471, blue: 0.965)     // #3478F6

    // Legacy color names retained as aliases of `accent` so existing call
    // sites continue to compile after the maritime-blue refresh. New UI
    // should reference `accent` directly.
    static let accentSoft = accent
    static let magenta = accent
    static let teal = accent
    static let violet = accent
    static let lime = accent
    static let coral = accent

    // Hero "gradient" is now a flat card surface — kept as a LinearGradient
    // so existing `.fill(Theme.heroGradient)` call sites compile unchanged.
    static let heroGradient = LinearGradient(
        colors: [card, card],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white.opacity(0.02), Color.clear],
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

struct MaritimePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.accent.opacity(configuration.isPressed ? 0.85 : 1.0))
            .clipShape(Capsule())
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == MaritimePrimaryButtonStyle {
    static var maritimePrimary: MaritimePrimaryButtonStyle { MaritimePrimaryButtonStyle() }
}
