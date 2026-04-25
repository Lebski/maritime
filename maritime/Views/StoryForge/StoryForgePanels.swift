import SwiftUI

// MARK: - Shared Story Forge Components

struct CompletionRing: View {
    let value: Double        // 0...1
    var size: CGFloat = 28
    var color: Color = Theme.magenta
    var showLabel: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 3)
            Circle()
                .trim(from: 0, to: max(0, min(1, value)))
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.25), value: value)
            if showLabel {
                Text("\(Int(value * 100))")
                    .font(.system(size: size * 0.32, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SectionTabButton: View {
    let section: StoryForgeSection
    let isActive: Bool
    let completion: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isActive ? Color.black : Theme.textSecondary)
                Text(section.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isActive ? Color.black : Theme.textSecondary)
                CompletionRing(
                    value: completion,
                    size: 16,
                    color: isActive ? Color.black.opacity(0.6) : Theme.magenta
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isActive ? Theme.magenta : Color.white.opacity(0.05))
            .overlay(
                Capsule().stroke(isActive ? Color.clear : Theme.stroke, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plainSolid)
    }
}

// MARK: - Character Field Card

struct FieldCard: View {
    let field: StoryCharacterField
    @Binding var text: String
    let isFocused: Bool
    let onFocus: () -> Void
    var onRegenerate: (() -> Void)? = nil
    var isRegenerating: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(field.tint.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Image(systemName: field.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(field.tint)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(field.label.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(field.tint)
                    Text(field.subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
                Spacer()
                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                if let onRegenerate {
                    Button(action: onRegenerate) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 22, height: 22)
                            if isRegenerating {
                                ProgressView().scaleEffect(0.5)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(field.tint)
                            }
                        }
                    }
                    .buttonStyle(.plainSolid)
                    .disabled(isRegenerating)
                    .help(text.trimmingCharacters(in: .whitespaces).isEmpty
                          ? "Generate this field with AI"
                          : "Regenerate with AI (keeps other fields as context)")
                }
            }

            StyledTextField(
                placeholder: field.subtitle,
                text: $text,
                isMultiLine: true
            )
            .onTapGesture { onFocus() }
        }
        .padding(14)
        .background(isFocused ? field.tint.opacity(0.08) : Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isFocused ? field.tint.opacity(0.55) : Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.easeInOut(duration: 0.18), value: isFocused)
    }
}

// MARK: - Template Choice Card

struct TemplateChoiceCard: View {
    let template: StoryStructureTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(template.rawValue)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.magenta)
                    }
                }
                Text(template.tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                arcSparkline
                HStack(spacing: 4) {
                    Text("\(template.beatCount) beats")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                    Circle().fill(Theme.textTertiary).frame(width: 2, height: 2)
                    Text(template.filmExamples.first ?? "")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(isSelected ? Theme.magenta.opacity(0.10) : Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Theme.magenta.opacity(0.55) : Theme.stroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plainSolid)
    }

    private var arcSparkline: some View {
        GeometryReader { geo in
            let beats = template.defaultBeats
            let w = geo.size.width
            let h = geo.size.height
            Path { path in
                guard beats.count > 1 else { return }
                for (i, beat) in beats.enumerated() {
                    let x = w * CGFloat(beat.timingPercent)
                    let y = h * CGFloat((1.0 - (beat.emotionalValence + 1.0) / 2.0))
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(
                isSelected ? Theme.magenta : Theme.teal.opacity(0.6),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(height: 22)
    }
}

// MARK: - Beat Pill

struct BeatPill: View {
    let beat: StoryBeat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(beat.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(isSelected ? .black : Theme.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isSelected ? beat.actTint : Theme.card)
                    .overlay(
                        Capsule().stroke(isSelected ? Color.clear : beat.actTint.opacity(0.6), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                Text(beat.actLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(beat.actTint.opacity(0.85))
            }
        }
        .buttonStyle(.plainSolid)
    }
}

// MARK: - Palette Swatch

struct PaletteSwatchView: View {
    let swatch: ColorPaletteSwatch
    var onRemove: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(swatch.color)
                    .frame(height: 58)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                if let onRemove {
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .padding(4)
                    }
                    .buttonStyle(.plainSolid)
                }
            }
            Text(swatch.role.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textSecondary)
            Text(swatch.hex)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(width: 108)
    }
}

// MARK: - Motif Chip

struct MotifChip: View {
    let motif: VisualMotif
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: motif.symbol)
                .font(.system(size: 11))
                .foregroundStyle(motif.tint)
            Text(motif.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text("\(motif.frequency)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(motif.tint)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(motif.tint.opacity(0.15))
                .clipShape(Capsule())
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .buttonStyle(.plainSolid)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(motif.tint.opacity(0.08))
        .overlay(Capsule().stroke(motif.tint.opacity(0.3), lineWidth: 1))
        .clipShape(Capsule())
    }
}

// MARK: - Why It Matters

struct WhyItMattersTip: View {
    let title: String
    let message: String
    var tint: Color = Theme.magenta

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(tint)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(tint)
            }
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Arc Curve

struct EmotionalArcCurve: View {
    let beats: [StoryBeat]
    let highlight: UUID?
    var tint: Color = Theme.magenta

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Baseline
                Path { path in
                    path.move(to: CGPoint(x: 0, y: h / 2))
                    path.addLine(to: CGPoint(x: w, y: h / 2))
                }
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

                // Filled area under curve
                Path { path in
                    guard beats.count > 1 else { return }
                    path.move(to: CGPoint(x: 0, y: h))
                    for beat in beats {
                        let x = w * CGFloat(beat.timingPercent)
                        let y = h * CGFloat((1.0 - (beat.emotionalValence + 1.0) / 2.0))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.30), tint.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

                // Curve line
                Path { path in
                    guard beats.count > 1 else { return }
                    for (i, beat) in beats.enumerated() {
                        let x = w * CGFloat(beat.timingPercent)
                        let y = h * CGFloat((1.0 - (beat.emotionalValence + 1.0) / 2.0))
                        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                // Highlight dot for selected beat
                if let id = highlight, let beat = beats.first(where: { $0.id == id }) {
                    let x = w * CGFloat(beat.timingPercent)
                    let y = h * CGFloat((1.0 - (beat.emotionalValence + 1.0) / 2.0))
                    Circle()
                        .fill(Theme.bg)
                        .overlay(Circle().stroke(tint, lineWidth: 2))
                        .frame(width: 10, height: 10)
                        .position(x: x, y: y)
                }
            }
        }
    }
}

// MARK: - Section Header (reused across sections)

struct StoryForgeSectionHeader: View {
    let title: String
    let subtitle: String
    let tint: Color
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            if let trailing { trailing }
        }
    }
}
