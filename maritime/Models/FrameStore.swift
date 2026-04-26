import SwiftUI

// MARK: - Frame mutators
//
// Extensions on MovieBlazeProject that mutate the frame catalogue.

@MainActor
extension MovieBlazeProject {

    func addFrame(_ frame: Frame) {
        frames.append(frame)
    }

    func updateFrame(_ frame: Frame) {
        if let i = frames.firstIndex(where: { $0.id == frame.id }) {
            frames[i] = frame
        }
    }

    func removeFrame(id: UUID) {
        frames.removeAll(where: { $0.id == id })
    }

    func mutateFrame(id: UUID, _ block: (inout Frame) -> Void) {
        guard let i = frames.firstIndex(where: { $0.id == id }) else { return }
        block(&frames[i])
    }

    func frames(forPanel panelID: UUID) -> [Frame] {
        frames.filter { $0.panelID == panelID }.sorted { $0.ordinal < $1.ordinal }
    }
}
