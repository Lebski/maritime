import SwiftUI
import AppKit
import UniformTypeIdentifiers
import OSLog

// MARK: - Color + Codable
//
// Round-trip through sRGB RGBA so every SwiftUI Color in the document can be
// encoded/decoded. Colors saved as Theme.xxx constants come back as their
// resolved RGBA — visually identical, but no longer == to the original symbol.

extension Color: Codable {
    private enum CodingKeys: String, CodingKey { case r, g, b, a }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let r = try c.decode(Double.self, forKey: .r)
        let g = try c.decode(Double.self, forKey: .g)
        let b = try c.decode(Double.self, forKey: .b)
        let a = try c.decodeIfPresent(Double.self, forKey: .a) ?? 1.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor.black
        try c.encode(Double(ns.redComponent),   forKey: .r)
        try c.encode(Double(ns.greenComponent), forKey: .g)
        try c.encode(Double(ns.blueComponent),  forKey: .b)
        try c.encode(Double(ns.alphaComponent), forKey: .a)
    }
}

// MARK: - UTType

extension UTType {
    static let movieBlazeProject = UTType(exportedAs: "com.movieblaze.project")
}

// MARK: - MovieBlazeProject
//
// ReferenceFileDocument backing the whole app. Every open .mblaze file maps
// to exactly one window and one instance of this class. All four singleton
// stores that used to exist (StoryStore / StoryboardStore / SceneStore /
// CharacterStore) collapse into @Published properties here.

private let projectLog = Logger(subsystem: "com.movieblaze", category: "project")

@MainActor
final class MovieBlazeProject: ReferenceFileDocument {

    // MARK: State

    @Published var bibles: [StoryBible]
    @Published var activeBibleID: UUID?

    @Published var sequences: [StoryboardSequence]
    @Published var activeSequenceID: UUID?

    @Published var scenes: [FilmScene]
    @Published var characters: [LabCharacter]

    // MARK: Document type

    nonisolated static var readableContentTypes: [UTType] { [.movieBlazeProject] }
    nonisolated static var writableContentTypes: [UTType] { [.movieBlazeProject] }

    // MARK: Snapshot

    struct Snapshot: Codable {
        var schemaVersion: Int
        var bibles: [StoryBible]
        var activeBibleID: UUID?
        var sequences: [StoryboardSequence]
        var activeSequenceID: UUID?
        var scenes: [FilmScene]
        var characters: [LabCharacter]
    }

    struct Manifest: Codable {
        var schemaVersion: Int
        var createdAt: Date
        var lastModified: Date
    }

    private static let currentSchemaVersion = 1
    private static let manifestFilename = "manifest.json"
    private static let projectFilename  = "project.json"

    // MARK: Init (new document)

    init() {
        let seed = MovieBlazeProject.seedSnapshot()
        self.bibles             = seed.bibles
        self.activeBibleID      = seed.activeBibleID
        self.sequences          = seed.sequences
        self.activeSequenceID   = seed.activeSequenceID
        self.scenes             = seed.scenes
        self.characters         = seed.characters
    }

    private static func seedSnapshot() -> Snapshot {
        // New projects start with the full showcase catalogue so the app
        // looks populated the first time a user launches it. Opening a saved
        // .mblaze replaces all of this with the saved state.
        let bibles    = StoryForgeSamples.bibles
        let sequences = StoryboardSamples.sequences
        let scenes    = SceneBuilderSamples.scenes
        let chars     = CharacterLabSamples.libraryCharacters
        let activeBible = bibles.first(where: { $0.projectTitle == "The Lantern Keeper" }) ?? bibles.first
        let activeSeq   = sequences.first(where: { $0.projectTitle == "The Lantern Keeper" }) ?? sequences.first
        return Snapshot(
            schemaVersion: currentSchemaVersion,
            bibles: bibles,
            activeBibleID: activeBible?.id,
            sequences: sequences,
            activeSequenceID: activeSeq?.id,
            scenes: scenes,
            characters: chars
        )
    }

    // MARK: Read

    required init(configuration: ReadConfiguration) throws {
        let root = configuration.file
        guard root.isDirectory,
              let children = root.fileWrappers else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let manifestWrapper = children[Self.manifestFilename],
           let manifestData = manifestWrapper.regularFileContents {
            let manifest = try decoder.decode(Manifest.self, from: manifestData)
            if manifest.schemaVersion > Self.currentSchemaVersion {
                projectLog.error("Refusing to open project with newer schemaVersion=\(manifest.schemaVersion)")
                throw CocoaError(.fileReadUnknown)
            }
        }

        guard let projectWrapper = children[Self.projectFilename],
              let projectData = projectWrapper.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let snapshot = try decoder.decode(Snapshot.self, from: projectData)
        self.bibles             = snapshot.bibles
        self.activeBibleID      = snapshot.activeBibleID
        self.sequences          = snapshot.sequences
        self.activeSequenceID   = snapshot.activeSequenceID
        self.scenes             = snapshot.scenes
        self.characters         = snapshot.characters
    }

    // MARK: Snapshot + Write

    func snapshot(contentType: UTType) throws -> Snapshot {
        Snapshot(
            schemaVersion: Self.currentSchemaVersion,
            bibles: bibles,
            activeBibleID: activeBibleID,
            sequences: sequences,
            activeSequenceID: activeSequenceID,
            scenes: scenes,
            characters: characters
        )
    }

    func fileWrapper(snapshot: Snapshot, configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let projectData = try encoder.encode(snapshot)
        let manifest = Manifest(
            schemaVersion: Self.currentSchemaVersion,
            createdAt: Date(),
            lastModified: Date()
        )
        let manifestData = try encoder.encode(manifest)

        // Start from existing wrapper so unchanged asset sub-wrappers are
        // preserved verbatim (cheap incremental saves once we add images).
        let root: FileWrapper
        if let existing = configuration.existingFile,
           existing.isDirectory {
            root = existing
            if let old = root.fileWrappers?[Self.projectFilename] {
                root.removeFileWrapper(old)
            }
            if let old = root.fileWrappers?[Self.manifestFilename] {
                root.removeFileWrapper(old)
            }
        } else {
            root = FileWrapper(directoryWithFileWrappers: [:])
        }

        let projectFile = FileWrapper(regularFileWithContents: projectData)
        projectFile.preferredFilename = Self.projectFilename
        root.addFileWrapper(projectFile)

        let manifestFile = FileWrapper(regularFileWithContents: manifestData)
        manifestFile.preferredFilename = Self.manifestFilename
        root.addFileWrapper(manifestFile)

        return root
    }

    // MARK: Active helpers

    var activeBible: StoryBible? {
        guard let id = activeBibleID else { return nil }
        return bibles.first(where: { $0.id == id })
    }

    var activeSequence: StoryboardSequence? {
        guard let id = activeSequenceID else { return nil }
        return sequences.first(where: { $0.id == id })
    }

    func setActiveBible(_ id: UUID) {
        activeBibleID = id
    }

    func setActiveSequence(_ id: UUID) {
        activeSequenceID = id
    }

    // MARK: Mutators — Story Bible

    private func mutateActiveBible(_ block: (inout StoryBible) -> Void) {
        guard let id = activeBibleID,
              let idx = bibles.firstIndex(where: { $0.id == id }) else { return }
        block(&bibles[idx])
        bibles[idx].lastUpdated = Date()
    }

    func updateDraft(_ draft: StoryCharacterDraft) {
        mutateActiveBible { bible in
            if let i = bible.characterDrafts.firstIndex(where: { $0.id == draft.id }) {
                bible.characterDrafts[i] = draft
            }
        }
    }

    func addDraft(_ draft: StoryCharacterDraft) {
        mutateActiveBible { $0.characterDrafts.append(draft) }
    }

    func removeDraft(id: UUID) {
        mutateActiveBible { $0.characterDrafts.removeAll(where: { $0.id == id }) }
    }

    func markDraftPromoted(draftID: UUID, labCharacterID: UUID) {
        mutateActiveBible { bible in
            if let i = bible.characterDrafts.firstIndex(where: { $0.id == draftID }) {
                bible.characterDrafts[i].promotedLabCharacterID = labCharacterID
            }
        }
    }

    func chooseTemplate(_ template: StoryStructureTemplate) {
        mutateActiveBible { $0.structure = StoryStructureDraft(template: template) }
    }

    func updateBeatNotes(beatID: UUID, notes: String) {
        mutateActiveBible { bible in
            if let i = bible.structure.beats.firstIndex(where: { $0.id == beatID }) {
                bible.structure.beats[i].userNotes = notes
            }
        }
    }

    func addScene(_ scene: SceneBreakdown) {
        mutateActiveBible { $0.sceneBreakdowns.append(scene) }
    }

    func updateScene(_ scene: SceneBreakdown) {
        mutateActiveBible { bible in
            if let i = bible.sceneBreakdowns.firstIndex(where: { $0.id == scene.id }) {
                bible.sceneBreakdowns[i] = scene
            }
        }
    }

    func removeScene(id: UUID) {
        mutateActiveBible { $0.sceneBreakdowns.removeAll(where: { $0.id == id }) }
    }

    func markScenePromoted(sceneID: UUID, filmSceneID: UUID) {
        mutateActiveBible { bible in
            if let i = bible.sceneBreakdowns.firstIndex(where: { $0.id == sceneID }) {
                bible.sceneBreakdowns[i].promotedFilmSceneID = filmSceneID
            }
        }
    }

    func updateTheme(_ theme: ThemeTracker) {
        mutateActiveBible { $0.theme = theme }
    }

    @discardableResult
    func createBible(title: String) -> StoryBible {
        let bible = StoryBible(
            projectTitle: title.isEmpty ? "Untitled Story" : title,
            logline: "",
            structure: StoryStructureDraft(template: .threeAct),
            posterColors: [Theme.violet, Theme.magenta]
        )
        bibles.append(bible)
        activeBibleID = bible.id
        return bible
    }
}
