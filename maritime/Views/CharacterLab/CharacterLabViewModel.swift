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
    @Published var generationError: String? = nil
    @Published var sidebarCollapsed = false

    private let project: MovieBlazeProject
    private let portraitService: PortraitGenerationService
    private let sheetService: CharacterSheetService

    init(project: MovieBlazeProject,
         portraitService: PortraitGenerationService = FalaiPortraitService(),
         sheetService: CharacterSheetService = CharacterSheetService()) {
        self.project = project
        self.portraitService = portraitService
        self.sheetService = sheetService
        self.characters = project.characters
    }

    func setActive(_ character: LabCharacter) {
        if let idx = characters.firstIndex(where: { $0.id == character.id }) {
            activeCharacter = characters[idx]
        } else {
            activeCharacter = character
        }
    }

    /// Called by NewCharacterSheet step 3. Creates the LabCharacter, kicks
    /// off recraft-v4 portrait generation, and routes to the active workspace.
    func createAndGenerate(name: String,
                           description: String,
                           role: String,
                           answers: CharacterSetupAnswers,
                           portraitCount: Int) {
        var char = LabCharacter(name: name,
                                description: description,
                                role: role,
                                setupAnswers: answers,
                                phase: .generating,
                                portraitCount: max(1, min(20, portraitCount)))
        char.finalVariation = CharacterTint.variation(for: char.id, name: char.name,
                                                      role: char.role,
                                                      style: description)
        characters.append(char)
        activeCharacter = char
        showNewCharacter = false
        startGeneration(characterID: char.id)
    }

    /// Trigger (or re-trigger) portrait generation for an existing character.
    func startGeneration(characterID: UUID) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        var char = characters[idx]
        char.phase = .generating
        characters[idx] = char
        syncActive(characterID)

        let request = PortraitGenerationRequest(
            name: char.name,
            role: char.role,
            description: char.description,
            answers: char.setupAnswers,
            count: char.portraitCount
        )

        isGenerating = true
        generationProgress = 0
        generationError = nil

        let progressTask = Task { @MainActor [weak self] in
            // Fake-tick the bar up to 95% while the network call resolves.
            for i in 1...19 {
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard let self else { return }
                if !self.isGenerating { return }
                self.generationProgress = min(0.95, Double(i) / 20.0)
            }
        }

        Task { @MainActor [weak self, portraitService] in
            defer { progressTask.cancel() }
            do {
                let portraits = try await portraitService.generate(request: request)
                guard let self else { return }
                self.applyGeneratedPortraits(characterID: characterID, portraits: portraits)
            } catch {
                guard let self else { return }
                self.generationError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                if let i = self.characters.firstIndex(where: { $0.id == characterID }) {
                    self.characters[i].phase = .setup
                    self.syncActive(characterID)
                }
                self.isGenerating = false
                self.generationProgress = 0
            }
        }
    }

    private func applyGeneratedPortraits(characterID: UUID, portraits: [PortraitVariation]) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        characters[idx].portraitVariations = portraits
        characters[idx].selectedPortraitID = nil
        characters[idx].phase = .selecting
        generationProgress = 1.0
        isGenerating = false
        syncActive(characterID)
        project.upsertCharacter(characters[idx])
    }

    func regeneratePortraits(characterID: UUID) {
        startGeneration(characterID: characterID)
    }

    func selectPortrait(characterID: UUID, portraitID: UUID) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        characters[idx].selectedPortraitID = portraitID
        characters[idx].phase = .finalized
        characters[idx].isFinalized = true
        syncActive(characterID)
        project.upsertCharacter(characters[idx])
    }

    func clearSelection(characterID: UUID) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        characters[idx].selectedPortraitID = nil
        characters[idx].phase = .selecting
        characters[idx].isFinalized = false
        syncActive(characterID)
        project.upsertCharacter(characters[idx])
    }

    /// Return to the setup form (e.g. user wants to tweak the description).
    func returnToSetup(characterID: UUID) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }) else { return }
        characters[idx].phase = .setup
        syncActive(characterID)
    }

    /// Generate a single reference sheet (turnaround / fullbody / expressions /
    /// action poses / portrait re-render) using the chosen portrait as seed.
    func generateSheet(characterID: UUID, sheet: ReferenceSheetType) {
        guard let idx = characters.firstIndex(where: { $0.id == characterID }),
              let portrait = characters[idx].selectedPortrait else { return }
        let char = characters[idx]

        isGenerating = true
        generationProgress = 0
        generationError = nil

        let progressTask = Task { @MainActor [weak self] in
            for i in 1...15 {
                try? await Task.sleep(nanoseconds: 800_000_000)
                guard let self else { return }
                if !self.isGenerating { return }
                self.generationProgress = min(0.95, Double(i) / 16.0)
            }
        }

        Task { @MainActor [weak self, sheetService] in
            defer { progressTask.cancel() }
            do {
                let bytes = try await sheetService.generate(sheet: sheet, portrait: portrait, character: char)
                guard let self else { return }
                if let i = self.characters.firstIndex(where: { $0.id == characterID }) {
                    self.characters[i].sheetImages[sheet] = bytes
                    self.syncActive(characterID)
                    self.project.upsertCharacter(self.characters[i])
                }
                self.generationProgress = 1.0
                self.isGenerating = false
            } catch {
                guard let self else { return }
                self.generationError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                self.isGenerating = false
                self.generationProgress = 0
            }
        }
    }

    private func syncActive(_ id: UUID) {
        if let idx = characters.firstIndex(where: { $0.id == id }) {
            activeCharacter = characters[idx]
        }
    }
}
