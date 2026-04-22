import SwiftUI
import Combine

@MainActor
final class ExportsViewModel: ObservableObject {
    @Published var projects: [MovieProject] = SampleData.projects
    @Published var selectedProjectID: UUID?
    @Published var selectedFormats: Set<ExportFormat> = [.premiereXML, .cutCSV]
    @Published var history: [ExportJob] = ExportSamples.history
    @Published var activeJobs: [UUID: Double] = [:]
    @Published var historyCollapsed: Bool = false

    init() {
        selectedProjectID = projects.first?.id
    }

    var selectedProject: MovieProject? {
        projects.first(where: { $0.id == selectedProjectID })
    }

    func setActive(_ project: MovieProject) {
        selectedProjectID = project.id
    }

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
        guard let project = selectedProject else { return }
        for format in selectedFormats {
            let job = ExportJob(format: format, projectTitle: project.title, status: .running(progress: 0))
            history.insert(job, at: 0)
            animateJob(jobID: job.id)
        }
    }

    private func animateJob(jobID: UUID) {
        Task {
            for i in 1...20 {
                try? await Task.sleep(nanoseconds: 70_000_000)
                await MainActor.run {
                    if let idx = history.firstIndex(where: { $0.id == jobID }) {
                        history[idx].status = .running(progress: Double(i) / 20.0)
                    }
                }
            }
            await MainActor.run {
                if let idx = history.firstIndex(where: { $0.id == jobID }) {
                    history[idx].status = .done(timestamp: "Just now")
                }
            }
        }
    }

    func deleteJob(_ job: ExportJob) {
        history.removeAll { $0.id == job.id }
    }
}
