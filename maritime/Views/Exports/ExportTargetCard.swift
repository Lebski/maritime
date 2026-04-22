import SwiftUI

struct ExportTargetCard: View {
    let format: ExportFormat
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(format.tint.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: format.icon)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(format.tint)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(format.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Text(format.shortCode)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(format.tint)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(format.tint.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .stroke(isSelected ? format.tint : Theme.stroke, lineWidth: 1.5)
                            .frame(width: 20, height: 20)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(format.tint)
                        }
                    }
                }
                Text(format.descriptor)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(Theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? format.tint : Theme.stroke,
                            lineWidth: isSelected ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
