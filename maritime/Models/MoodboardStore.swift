import SwiftUI

// MARK: - Moodboard mutators
//
// Extensions on MovieBlazeProject for the single per-project moodboard. All
// mutations touch `moodboard.lastUpdated` so the document dirties.

@MainActor
extension MovieBlazeProject {

    func mutateMoodboard(_ block: (inout ProjectMoodboard) -> Void) {
        block(&moodboard)
        moodboard.lastUpdated = Date()
    }

    func addMoodboardItem(_ item: MoodboardItem) {
        mutateMoodboard { board in
            var copy = item
            copy.zOrder = (board.items.map { $0.zOrder }.max() ?? 0) + 1
            board.items.append(copy)
        }
    }

    func updateMoodboardItem(_ item: MoodboardItem) {
        mutateMoodboard { board in
            if let i = board.items.firstIndex(where: { $0.id == item.id }) {
                board.items[i] = item
            }
        }
    }

    func mutateMoodboardItem(id: UUID, _ block: (inout MoodboardItem) -> Void) {
        mutateMoodboard { board in
            if let i = board.items.firstIndex(where: { $0.id == id }) {
                block(&board.items[i])
            }
        }
    }

    func removeMoodboardItem(id: UUID) {
        mutateMoodboard { board in
            board.items.removeAll(where: { $0.id == id })
        }
    }

    func bringMoodboardItemToFront(id: UUID) {
        mutateMoodboard { board in
            let top = (board.items.map { $0.zOrder }.max() ?? 0) + 1
            if let i = board.items.firstIndex(where: { $0.id == id }) {
                board.items[i].zOrder = top
            }
        }
    }

    func setMoodboardSnap(_ snap: Bool) {
        mutateMoodboard { $0.snapToGrid = snap }
    }

    func updateMoodboardTitle(_ title: String) {
        mutateMoodboard { $0.title = title }
    }

    func setMoodboardPalette(_ colors: [Color]) {
        mutateMoodboard { $0.colorPalette = colors }
    }
}
