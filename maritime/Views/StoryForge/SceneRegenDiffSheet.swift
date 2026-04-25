import SwiftUI

/// Shows the per-scene diff between the user's existing scenes and Claude's proposed
/// revisions after a structure-template change. The user accepts/rejects per scene
/// (or Accept All) and the result is applied via `vm.applySceneDiff(...)`.
struct SceneRegenDiffSheet: View {
    @ObservedObject var vm: StoryForgeViewModel
    @Environment(\.dismiss) private var dismiss

    let proposal: StoryForgeViewModel.SceneDiffProposal

    @State private var acceptedNumbers: Set<Int> = []
    @State private var showUnchanged: Bool = false

    enum RowKind {
        case unchanged(SceneBreakdown)
        case changed(old: SceneBreakdown, new: SceneBreakdown)
        case new(SceneBreakdown)
        case removed(SceneBreakdown)
    }

    struct Row: Identifiable {
        let id: Int
        let kind: RowKind
    }

    private var rows: [Row] {
        let oldByNumber = Dictionary(uniqueKeysWithValues: proposal.oldScenes.map { ($0.number, $0) })
        let newByNumber = Dictionary(uniqueKeysWithValues: proposal.proposedScenes.map { ($0.number, $0) })
        let allNumbers = Set(oldByNumber.keys).union(newByNumber.keys)

        return allNumbers.sorted().map { n -> Row in
            switch (oldByNumber[n], newByNumber[n]) {
            case let (old?, new?):
                if scenesEquivalent(old, new) {
                    return Row(id: n, kind: .unchanged(old))
                } else {
                    return Row(id: n, kind: .changed(old: old, new: new))
                }
            case let (.none, new?):
                return Row(id: n, kind: .new(new))
            case let (old?, .none):
                return Row(id: n, kind: .removed(old))
            case (.none, .none):
                return Row(id: n, kind: .new(SceneBreakdown(number: n, title: "—", location: "—", isInterior: true, timeOfDay: .day)))
            }
        }
    }

    private func scenesEquivalent(_ a: SceneBreakdown, _ b: SceneBreakdown) -> Bool {
        a.title == b.title
            && a.location == b.location
            && a.isInterior == b.isInterior
            && a.timeOfDay == b.timeOfDay
            && a.sceneGoal == b.sceneGoal
            && a.conflict == b.conflict
            && a.emotionalBeat == b.emotionalBeat
            && a.visualMetaphor == b.visualMetaphor
            && a.transitionNote == b.transitionNote
    }

    private var nonUnchangedRows: [Row] {
        rows.filter {
            if case .unchanged = $0.kind { return false }
            return true
        }
    }

    private var unchangedRows: [Row] {
        rows.filter {
            if case .unchanged = $0.kind { return true }
            return false
        }
    }

    private var acceptedCount: Int { acceptedNumbers.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
                    .padding(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Review Scene Revisions")
            .toolbar { toolbar }
        }
        .frame(minWidth: 820, minHeight: 640)
        .onAppear { preselectAll() }
    }

    private func preselectAll() {
        let proposable = nonUnchangedRows.compactMap { row -> Int? in
            switch row.kind {
            case .unchanged: return nil
            case .changed, .new, .removed: return row.id
            }
        }
        acceptedNumbers = Set(proposable)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(nonUnchangedRows) { row in
                        diffRow(row)
                    }
                    if !unchangedRows.isEmpty {
                        Button(action: { showUnchanged.toggle() }) {
                            Text(showUnchanged
                                 ? "Hide \(unchangedRows.count) unchanged scenes"
                                 : "Show \(unchangedRows.count) unchanged scenes")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .buttonStyle(.plainSolid)
                        .padding(.top, 4)
                        if showUnchanged {
                            ForEach(unchangedRows) { row in
                                diffRow(row)
                            }
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(Theme.magenta)
                Text("Structure changed: \(proposal.oldTemplate.rawValue) → \(proposal.newTemplate.rawValue)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button("Reject All") { acceptedNumbers.removeAll() }
                    .buttonStyle(.plainSolid)
                    .foregroundStyle(Theme.textSecondary)
                    .font(.system(size: 11, weight: .semibold))
                Button("Accept All") {
                    acceptedNumbers = Set(nonUnchangedRows.map { $0.id })
                }
                .buttonStyle(.plainSolid)
                .foregroundStyle(Theme.magenta)
                .font(.system(size: 11, weight: .semibold))
            }
            Text("Tick the scenes you want to apply. Unchanged scenes stay as they are.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(14)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.stroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func diffRow(_ row: Row) -> some View {
        switch row.kind {
        case .unchanged(let scene):
            unchangedCard(scene)
        case .changed(let old, let new):
            changedCard(number: row.id, old: old, new: new)
        case .new(let scene):
            newCard(scene)
        case .removed(let scene):
            removedCard(scene)
        }
    }

    private func unchangedCard(_ scene: SceneBreakdown) -> some View {
        HStack(spacing: 10) {
            badge("UNCHANGED", color: Theme.textTertiary)
            Text("#\(scene.number) · \(scene.title)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.02))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Theme.stroke.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func changedCard(number: Int, old: SceneBreakdown, new: SceneBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                badge("CHANGED", color: Theme.accent)
                Text("Scene #\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                acceptToggle(number: number)
            }
            HStack(alignment: .top, spacing: 10) {
                sideColumn(label: "BEFORE", scene: old, isProposed: false, comparedTo: new)
                Divider().background(Theme.stroke)
                sideColumn(label: "AFTER", scene: new, isProposed: true, comparedTo: old)
            }
        }
        .padding(12)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.accent.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func newCard(_ scene: SceneBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                badge("NEW", color: Theme.lime)
                Text("Scene #\(scene.number) · \(scene.title)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                acceptToggle(number: scene.number)
            }
            sideColumn(label: nil, scene: scene, isProposed: true, comparedTo: nil)
        }
        .padding(12)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.lime.opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func removedCard(_ scene: SceneBreakdown) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                badge("REMOVED", color: Theme.coral)
                Text("Scene #\(scene.number) · \(scene.title)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                acceptToggle(number: scene.number)
            }
            sideColumn(label: nil, scene: scene, isProposed: false, comparedTo: nil)
        }
        .padding(12)
        .background(Theme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.coral.opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func acceptToggle(number: Int) -> some View {
        let accepted = acceptedNumbers.contains(number)
        return Button(action: {
            if accepted { acceptedNumbers.remove(number) } else { acceptedNumbers.insert(number) }
        }) {
            HStack(spacing: 6) {
                Image(systemName: accepted ? "checkmark.square.fill" : "square")
                    .foregroundStyle(accepted ? Theme.magenta : Theme.textTertiary)
                Text(accepted ? "Accepted" : "Accept")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accepted ? Theme.magenta : Theme.textSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(accepted ? Theme.magenta.opacity(0.10) : Color.white.opacity(0.04))
            .clipShape(Capsule())
        }
        .buttonStyle(.plainSolid)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }

    private func sideColumn(label: String?, scene: SceneBreakdown, isProposed: Bool, comparedTo: SceneBreakdown?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(Theme.textTertiary)
            }
            diffField("Title", scene.title, comparedTo?.title, isProposed: isProposed)
            diffField("Location",
                     "\(scene.isInterior ? "INT." : "EXT.") \(scene.location) — \(scene.timeOfDay.rawValue)",
                     comparedTo.map { "\($0.isInterior ? "INT." : "EXT.") \($0.location) — \($0.timeOfDay.rawValue)" },
                     isProposed: isProposed)
            diffField("Goal", scene.sceneGoal, comparedTo?.sceneGoal, isProposed: isProposed)
            diffField("Conflict", scene.conflict, comparedTo?.conflict, isProposed: isProposed)
            diffField("Beat", scene.emotionalBeat, comparedTo?.emotionalBeat, isProposed: isProposed)
            diffField("Metaphor", scene.visualMetaphor, comparedTo?.visualMetaphor, isProposed: isProposed)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func diffField(_ label: String, _ value: String, _ other: String?, isProposed: Bool) -> some View {
        let changed = (other != nil) && other != value
        return VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 8, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(Theme.textTertiary)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 11))
                .foregroundStyle(changed ? Theme.textPrimary : Theme.textSecondary)
                .strikethrough(changed && !isProposed, color: Theme.coral)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(changed ? (isProposed ? Theme.lime.opacity(0.10) : Theme.coral.opacity(0.08)) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Discard Proposal") {
                vm.discardSceneDiff()
                dismiss()
            }
            .foregroundStyle(Theme.textSecondary)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Apply (\(acceptedCount))") { applyDiff() }
                .foregroundStyle(acceptedCount > 0 ? Theme.magenta : Theme.textTertiary)
                .disabled(acceptedCount == 0)
        }
    }

    private func applyDiff() {
        var replacements: [Int: SceneBreakdown] = [:]
        var additions: [SceneBreakdown] = []
        var removals: Set<Int> = []

        for row in nonUnchangedRows where acceptedNumbers.contains(row.id) {
            switch row.kind {
            case .changed(_, let new): replacements[row.id] = new
            case .new(let scene):      additions.append(scene)
            case .removed:             removals.insert(row.id)
            case .unchanged: break
            }
        }

        vm.applySceneDiff(replacements: replacements, removals: removals, additions: additions)
        dismiss()
    }
}
