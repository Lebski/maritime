import SwiftUI

struct WantVsNeedPanel: View {
    @ObservedObject var vm: StoryForgeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Want vs. Need")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Mamet")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(AppModule.storyForge.tint)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(AppModule.storyForge.tint.opacity(0.18))
                    .clipShape(Capsule())
                Spacer()
                Button(action: { vm.addWantNeed() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 11))
                        Text("Character")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(AppModule.storyForge.tint)
                }
                .buttonStyle(.plain)
            }
            VStack(spacing: 8) {
                ForEach(vm.wantNeed) { entry in
                    WantNeedRow(entry: entry, vm: vm)
                }
            }
        }
        .padding(14)
        .cardStyle()
    }
}

private struct WantNeedRow: View {
    let entry: WantNeedEntry
    @ObservedObject var vm: StoryForgeViewModel
    @State private var want: String
    @State private var need: String

    init(entry: WantNeedEntry, vm: StoryForgeViewModel) {
        self.entry = entry
        self.vm = vm
        _want = State(initialValue: entry.want)
        _need = State(initialValue: entry.need)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.character)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            HStack(alignment: .top, spacing: 10) {
                column(title: "WANT", tint: AppModule.storyForge.tint, binding: $want) { vm.updateWantNeed(entry, want: $0) }
                column(title: "NEED", tint: Theme.teal, binding: $need) { vm.updateWantNeed(entry, need: $0) }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func column(title: String, tint: Color, binding: Binding<String>, onCommit: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(tint)
            TextField("", text: binding, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1...4)
                .onChange(of: binding.wrappedValue) { _, newValue in
                    onCommit(newValue)
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
