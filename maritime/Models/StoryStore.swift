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
// to exactly one window and one instance of this class. One project = one
// bible, one flat list of storyboard panels, one scene set, one cast.

private let projectLog = Logger(subsystem: "com.movieblaze", category: "project")

@MainActor
final class MovieBlazeProject: ReferenceFileDocument {

    // MARK: State

    @Published var bible: StoryBible

    @Published var storyboardPanels: [StoryboardPanel]

    @Published var scenes: [FilmScene]
    @Published var characters: [LabCharacter]
    @Published var setPieces: [SetPiece]
    @Published var moodboard: ProjectMoodboard

    @Published var cutSuggestions: [CutSuggestion]
    @Published var favoritedAssetIDs: Set<UUID>

    /// Number of times each asset has been re-imported from a Photoshop edit.
    /// Persisted in `project.json`; the bytes themselves live in `assets/`.
    @Published var assetEditCounts: [UUID: Int]

    /// In-memory cache of per-asset PNG bytes loaded from `assets/<uuid>.png`.
    /// Read with ``assetImageData(for:)`` and updated with ``setAssetImageData(_:for:)``.
    var assetImageBytes: [UUID: Data] = [:]

    // MARK: Document type

    nonisolated static var readableContentTypes: [UTType] { [.movieBlazeProject] }
    nonisolated static var writableContentTypes: [UTType] { [.movieBlazeProject] }

    // MARK: Snapshot

    struct Snapshot: Codable {
        var schemaVersion: Int
        var bible: StoryBible
        var storyboardPanels: [StoryboardPanel]
        var scenes: [FilmScene]
        var characters: [LabCharacter]
        var setPieces: [SetPiece]?
        var moodboard: ProjectMoodboard?
        var cutSuggestions: [CutSuggestion]?
        var favoritedAssetIDs: [UUID]?
        var assetEditCounts: [UUID: Int]?
    }

    struct Manifest: Codable {
        var schemaVersion: Int
        var createdAt: Date
        var lastModified: Date
    }

    private static let currentSchemaVersion = 2
    private static let manifestFilename = "manifest.json"
    private static let projectFilename  = "project.json"
    static let assetsDirname            = "assets"

    // MARK: Init (new document)

    init() {
        let seed = MovieBlazeProject.seedSnapshot()
        self.bible             = seed.bible
        self.storyboardPanels  = seed.storyboardPanels
        self.scenes            = seed.scenes
        self.characters        = seed.characters
        self.setPieces         = seed.setPieces ?? []
        self.moodboard         = seed.moodboard ?? ProjectMoodboard()
        self.cutSuggestions    = seed.cutSuggestions ?? []
        self.favoritedAssetIDs = Set(seed.favoritedAssetIDs ?? [])
        self.assetEditCounts   = seed.assetEditCounts ?? [:]
    }

    private static func seedSnapshot() -> Snapshot {
        // New projects open empty. Opening a saved .mblaze replaces this with
        // the saved state.
        return Snapshot(
            schemaVersion: currentSchemaVersion,
            bible: StoryBible(
                projectTitle: "",
                logline: "",
                structure: StoryStructureDraft(template: .threeAct)
            ),
            storyboardPanels: [],
            scenes: [],
            characters: [],
            setPieces: [],
            moodboard: ProjectMoodboard(),
            cutSuggestions: [],
            favoritedAssetIDs: nil
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
        self.bible             = snapshot.bible
        self.storyboardPanels  = snapshot.storyboardPanels
        self.scenes            = snapshot.scenes
        self.characters        = snapshot.characters
        self.setPieces         = snapshot.setPieces ?? []
        self.moodboard         = snapshot.moodboard ?? ProjectMoodboard()
        self.cutSuggestions    = snapshot.cutSuggestions ?? []
        self.favoritedAssetIDs = Set(snapshot.favoritedAssetIDs ?? [])
        self.assetEditCounts   = snapshot.assetEditCounts ?? [:]

        if let assetsDir = children[Self.assetsDirname],
           assetsDir.isDirectory,
           let entries = assetsDir.fileWrappers {
            for (filename, wrapper) in entries {
                let stem = (filename as NSString).deletingPathExtension
                guard let id = UUID(uuidString: stem),
                      let data = wrapper.regularFileContents else { continue }
                self.assetImageBytes[id] = data
            }
        }
    }

    // MARK: Snapshot + Write

    func snapshot(contentType: UTType) throws -> Snapshot {
        Snapshot(
            schemaVersion: Self.currentSchemaVersion,
            bible: bible,
            storyboardPanels: storyboardPanels,
            scenes: scenes,
            characters: characters,
            setPieces: setPieces,
            moodboard: moodboard,
            cutSuggestions: cutSuggestions,
            favoritedAssetIDs: Array(favoritedAssetIDs),
            assetEditCounts: assetEditCounts.isEmpty ? nil : assetEditCounts
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

        writeAssetWrappers(into: root)

        return root
    }

    private func writeAssetWrappers(into root: FileWrapper) {
        if assetImageBytes.isEmpty {
            if let old = root.fileWrappers?[Self.assetsDirname] {
                root.removeFileWrapper(old)
            }
            return
        }

        let assetsWrapper: FileWrapper
        if let existing = root.fileWrappers?[Self.assetsDirname], existing.isDirectory {
            assetsWrapper = existing
        } else {
            if let old = root.fileWrappers?[Self.assetsDirname] {
                root.removeFileWrapper(old)
            }
            assetsWrapper = FileWrapper(directoryWithFileWrappers: [:])
            assetsWrapper.preferredFilename = Self.assetsDirname
            root.addFileWrapper(assetsWrapper)
        }

        let liveFilenames = Set(assetImageBytes.keys.map { "\($0.uuidString).png" })
        for (filename, child) in assetsWrapper.fileWrappers ?? [:] where !liveFilenames.contains(filename) {
            assetsWrapper.removeFileWrapper(child)
        }

        for (id, data) in assetImageBytes {
            let filename = "\(id.uuidString).png"
            if let existing = assetsWrapper.fileWrappers?[filename],
               existing.regularFileContents == data {
                continue
            }
            if let stale = assetsWrapper.fileWrappers?[filename] {
                assetsWrapper.removeFileWrapper(stale)
            }
            let file = FileWrapper(regularFileWithContents: data)
            file.preferredFilename = filename
            assetsWrapper.addFileWrapper(file)
        }
    }

    // MARK: Mutators — Story Bible

    func mutateBible(_ block: (inout StoryBible) -> Void) {
        block(&bible)
        bible.lastUpdated = Date()
    }

    func updateDraft(_ draft: StoryCharacterDraft) {
        mutateBible { bible in
            if let i = bible.characterDrafts.firstIndex(where: { $0.id == draft.id }) {
                bible.characterDrafts[i] = draft
            }
        }
    }

    func addDraft(_ draft: StoryCharacterDraft) {
        mutateBible { $0.characterDrafts.append(draft) }
    }

    func removeDraft(id: UUID) {
        mutateBible { $0.characterDrafts.removeAll(where: { $0.id == id }) }
    }

    func markDraftPromoted(draftID: UUID, labCharacterID: UUID) {
        mutateBible { bible in
            if let i = bible.characterDrafts.firstIndex(where: { $0.id == draftID }) {
                bible.characterDrafts[i].promotedLabCharacterID = labCharacterID
            }
        }
    }

    func chooseTemplate(_ template: StoryStructureTemplate) {
        mutateBible { $0.structure = StoryStructureDraft(template: template) }
    }

    func updateBeatNotes(beatID: UUID, notes: String) {
        mutateBible { bible in
            if let i = bible.structure.beats.firstIndex(where: { $0.id == beatID }) {
                bible.structure.beats[i].userNotes = notes
            }
        }
    }

    func addScene(_ scene: SceneBreakdown) {
        mutateBible { $0.sceneBreakdowns.append(scene) }
    }

    func updateScene(_ scene: SceneBreakdown) {
        mutateBible { bible in
            if let i = bible.sceneBreakdowns.firstIndex(where: { $0.id == scene.id }) {
                bible.sceneBreakdowns[i] = scene
            }
        }
    }

    func removeScene(id: UUID) {
        mutateBible { $0.sceneBreakdowns.removeAll(where: { $0.id == id }) }
    }

    func markScenePromoted(sceneID: UUID, filmSceneID: UUID) {
        mutateBible { bible in
            if let i = bible.sceneBreakdowns.firstIndex(where: { $0.id == sceneID }) {
                bible.sceneBreakdowns[i].promotedFilmSceneID = filmSceneID
            }
        }
    }

    func updateTheme(_ theme: ThemeTracker) {
        mutateBible { $0.theme = theme }
    }

    // MARK: Asset image bytes

    func assetImageData(for id: UUID) -> Data? {
        assetImageBytes[id]
    }

    /// Replaces the PNG bytes stored for `id`, bumps its Photoshop edit counter,
    /// and marks the document dirty so autosave persists the bytes into the
    /// `.mblaze` package on the next pass.
    func setAssetImageData(_ data: Data, for id: UUID) {
        objectWillChange.send()
        assetImageBytes[id] = data
        assetEditCounts[id, default: 0] += 1
    }
}
