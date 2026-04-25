import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

// MARK: - Exports view model
//
// Bound to the single open MovieBlazeProject (one document per window means
// the "project picker" collapses into a single derived chip — no more
// hardcoded "Neon Requiem"). Export history lives on the view model for now;
// persisting jobs across launches can come later when more real exporters
// land. The Premiere Pro XML format is a real exporter (NSSavePanel + XML +
// placeholder PNGs); other formats are still mock animations.

@MainActor
final class ExportsViewModel: ObservableObject {
    @Published var selectedFormats: Set<ExportFormat> = [.premiereXML, .cutCSV]
    @Published var history: [ExportJob] = []
    @Published var historyCollapsed: Bool = false
    @Published var premiereSettings = PremiereExportSettings()

    private let project: MovieBlazeProject
    private var cancellables: Set<AnyCancellable> = []

    init(project: MovieBlazeProject) {
        self.project = project
        project.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    // MARK: Derived state

    /// Synthesize a MovieProject summary from the open document so the existing
    /// chip + summary UI keeps working without a hardcoded sample list.
    var currentProject: MovieProject {
        let bible = project.bible
        let totalSeconds = project.scenes.reduce(0) { $0 + $1.clipDuration }
        let approved = project.scenes.filter(\.frameApproved).count
        let progress = project.scenes.isEmpty
            ? 0
            : Double(approved) / Double(project.scenes.count)
        return MovieProject(
            title: bible.projectTitle,
            genre: bible.theme.themeStatement.isEmpty ? "Untitled" : bible.theme.themeStatement,
            logline: bible.logline,
            progress: progress,
            scenes: project.scenes.count,
            characters: project.characters.count,
            durationMinutes: max(1, Int((totalSeconds / 60).rounded(.up))),
            updatedLabel: bibleUpdatedLabel(bible.lastUpdated),
            posterColors: bible.posterColors.isEmpty
                ? [Theme.violet, Theme.magenta]
                : bible.posterColors,
            status: .shooting
        )
    }

    var projects: [MovieProject] { [currentProject] }

    var selectedProject: MovieProject { currentProject }

    // MARK: Mutations

    func toggle(_ format: ExportFormat) {
        if selectedFormats.contains(format) {
            selectedFormats.remove(format)
        } else {
            selectedFormats.insert(format)
        }
    }

    func isSelected(_ format: ExportFormat) -> Bool {
        selectedFormats.contains(format)
    }

    func generate() {
        let summary = currentProject
        for format in selectedFormats {
            let job = ExportJob(format: format, projectTitle: summary.title, status: .running(progress: 0))
            history.insert(job, at: 0)
            switch format {
            case .premiereXML:
                Task { await runPremiereExport(jobID: job.id) }
            default:
                animateJob(jobID: job.id)
            }
        }
    }

    func deleteJob(_ job: ExportJob) {
        history.removeAll { $0.id == job.id }
    }

    // MARK: Premiere export

    private func runPremiereExport(jobID: UUID) async {
        let approved = project.videoClips.filter(\.isApproved)
        guard !approved.isEmpty else {
            updateJob(jobID, status: .failed(reason: "No approved clips to export."))
            return
        }

        // The sandbox grants write access to the *folder* the user picks,
        // so we ask for a directory and write both the XML and the media
        // folder inside it. Picking a single file via NSSavePanel only
        // grants access to that exact path, which blocks the sibling
        // _media folder.
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Export Here"
        panel.title = "Export to Premiere Pro"
        panel.message = "Choose a folder. The XML and a placeholder stills folder will be written inside it."

        guard panel.runModal() == .OK, let folderURL = panel.url else {
            updateJob(jobID, status: .failed(reason: "Cancelled"))
            return
        }

        let needsScope = folderURL.startAccessingSecurityScopedResource()
        defer { if needsScope { folderURL.stopAccessingSecurityScopedResource() } }

        let baseName = sanitizeFilename(currentProject.title)
        let xmlURL = folderURL.appendingPathComponent("\(baseName).xml")
        let mediaFolder = folderURL.appendingPathComponent("\(baseName)_media", isDirectory: true)

        do {
            updateJob(jobID, status: .running(progress: 0.3))

            let mediaURLs = try PremiereStillRenderer.renderClips(
                approved,
                size: premiereSettings.resolution.size,
                into: mediaFolder
            )

            updateJob(jobID, status: .running(progress: 0.7))

            let xml = PremiereXMLExporter.xml(
                for: project,
                settings: premiereSettings,
                clips: approved,
                mediaURLs: mediaURLs
            )

            guard let data = xml.data(using: .utf8) else {
                throw NSError(
                    domain: "ExportsViewModel",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to encode XML as UTF-8."]
                )
            }
            try data.write(to: xmlURL, options: .atomic)

            updateJob(jobID, status: .done(timestamp: "Just now"))
        } catch {
            updateJob(jobID, status: .failed(reason: error.localizedDescription))
        }
    }

    private func sanitizeFilename(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.isEmpty ? "Untitled" : trimmed
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return base
            .components(separatedBy: invalid)
            .joined(separator: "-")
    }

    private func updateJob(_ jobID: UUID, status: ExportJobStatus) {
        if let idx = history.firstIndex(where: { $0.id == jobID }) {
            history[idx].status = status
        }
    }

    // MARK: Mock animation (non-Premiere formats)

    private func animateJob(jobID: UUID) {
        Task {
            for i in 1...20 {
                try? await Task.sleep(nanoseconds: 70_000_000)
                if let idx = history.firstIndex(where: { $0.id == jobID }) {
                    history[idx].status = .running(progress: Double(i) / 20.0)
                }
            }
            if let idx = history.firstIndex(where: { $0.id == jobID }) {
                history[idx].status = .done(timestamp: "Just now")
            }
        }
    }

    private func bibleUpdatedLabel(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86_400 { return "\(Int(interval / 3600))h ago" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
