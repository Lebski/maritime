import SwiftUI

struct ShotLibraryPanel: View {
    @ObservedObject var vm: StoryboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(ShotSize.allCases) { shot in
                        ShotLibraryRow(shot: shot) {
                            vm.addPanel(for: shot)
                        }
                    }
                }
                .padding(12)
            }
        }
        .background(Theme.bgElevated)
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppModule.storyboard.tint.opacity(0.18))
                        .frame(width: 38, height: 38)
                    Image(systemName: AppModule.storyboard.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppModule.storyboard.tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shot Library")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(ShotSize.allCases.count) shot types")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            Divider().background(Theme.stroke)
        }
    }
}

private struct ShotLibraryRow: View {
    let shot: ShotSize
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppModule.storyboard.tint.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: shot.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppModule.storyboard.tint)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(shot.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(shot.shortLabel)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(AppModule.storyboard.tint)
                        .padding(.horizontal, 4).padding(.vertical, 1)
                        .background(AppModule.storyboard.tint.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                Text(shot.description)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(AppModule.storyboard.tint)
                    .frame(width: 24, height: 24)
                    .background(AppModule.storyboard.tint.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Add to sequence")
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
