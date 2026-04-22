import SwiftUI
import Combine

@MainActor
final class CharacterLabViewModel: ObservableObject {
    @Published var characters: [LabCharacter] = []
    @Published var activeCharacter: LabCharacter? = nil
    @Published var showNewCharacter = false
    @Published var showReferenceSheet = false
    @Published var isGenerating = false
    @Published var generationProgress: Double = 0

    func setActive(_ character: LabCharacter) {
        // Check both personal and library chars
        if let idx = characters.firstIndex(where: { $0.id == character.id }) {
            activeCharacter = characters[idx]
        } else {
            activeCharacter = character
        }
    }

    func createCharacter(name: String, description: String, role: String) {
        let char = LabCharacter(name: name, description: description, role: role)
        characters.append(char)
        activeCharacter = characters.last
        showNewCharacter = false
    }

    func toggleVariation(characterID: UUID, variation: CharacterVariation) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        let round = characters[idx].currentRound
        let maxSel = round.maxSelections

        if let selIdx = characters[idx].selectedVariations.firstIndex(of: variation) {
            characters[idx].selectedVariations.remove(at: selIdx)
        } else {
            if characters[idx].selectedVariations.count < maxSel {
                characters[idx].selectedVariations.append(variation)
            }
        }
        syncActive(characterID)
    }

    func advanceRound(characterID: UUID) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        let current = characters[idx].currentRound
        guard let next = RefinementRound(rawValue: current.rawValue + 1) else { return }
        isGenerating = true
        generationProgress = 0

        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                generationProgress = Double(i) / 10.0
            }
            characters[idx].currentRound = next
            characters[idx].selectedVariations = []
            isGenerating = false
            syncActive(characterID)
        }
    }

    func finalizeCharacter(characterID: UUID, variation: CharacterVariation) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        isGenerating = true
        generationProgress = 0

        Task {
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 80_000_000)
                generationProgress = Double(i) / 10.0
            }
            characters[idx].finalVariation = variation
            characters[idx].isFinalized = true
            isGenerating = false
            syncActive(characterID)
        }
    }

    func generateSheet(characterID: UUID, sheet: ReferenceSheetType) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        isGenerating = true
        generationProgress = 0

        Task {
            for i in 1...8 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                generationProgress = Double(i) / 8.0
            }
            characters[idx].generatedSheets.insert(sheet)
            isGenerating = false
            syncActive(characterID)
        }
    }

    func requestMoreRounds(characterID: UUID) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        characters[idx].currentRound = .broad
        characters[idx].selectedVariations = []
        characters[idx].isFinalized = false
        characters[idx].finalVariation = nil
        syncActive(characterID)
    }

    private func syncActive(_ id: UUID) {
        if let idx = characters.firstIndex(where: { $0.id == id }) {
            activeCharacter = characters[idx]
        }
    }
}
