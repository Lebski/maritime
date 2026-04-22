import SwiftUI

// MARK: - Export Format

enum ExportFormat: String, CaseIterable, Identifiable {
    case premiereXML = "Premiere Pro XML"
    case psdExchange = "Photoshop PSD"
    case rawFootage = "Raw Footage Bundle"
    case cutCSV = "Cut Suggestions (CSV)"
    case resolveEDL = "DaVinci Resolve EDL"
    case proToolsAAF = "Pro Tools AAF"

    var id: String { rawValue }

    var shortCode: String {
        switch self {
        case .premiereXML: return "XML"
        case .psdExchange: return "PSD"
        case .rawFootage: return "ZIP"
        case .cutCSV: return "CSV"
        case .resolveEDL: return "EDL"
        case .proToolsAAF: return "AAF"
        }
    }

    var icon: String {
        switch self {
        case .premiereXML: return "film.stack"
        case .psdExchange: return "paintbrush.pointed.fill"
        case .rawFootage: return "shippingbox.fill"
        case .cutCSV: return "doc.text.fill"
        case .resolveEDL: return "rectangle.stack.fill"
        case .proToolsAAF: return "waveform.path.ecg"
        }
    }

    var tint: Color {
        switch self {
        case .premiereXML: return Theme.violet
        case .psdExchange: return Theme.teal
        case .rawFootage: return Theme.accent
        case .cutCSV: return Theme.lime
        case .resolveEDL: return Theme.magenta
        case .proToolsAAF: return Color(red: 0.9, green: 0.6, blue: 0.1)
        }
    }

    var descriptor: String {
        switch self {
        case .premiereXML: return "Timeline, cuts, and markers ready for Premiere Pro."
        case .psdExchange: return "Layered frames for Photoshop round-trip painting."
        case .rawFootage: return "All approved clips bundled with a manifest."
        case .cutCSV: return "Murch-weighted suggestions as a spreadsheet."
        case .resolveEDL: return "Industry-standard edit decision list."
        case .proToolsAAF: return "Audio sessions for Pro Tools finishing."
        }
    }
}

// MARK: - Export Job

enum ExportJobStatus: Equatable {
    case idle
    case running(progress: Double)
    case done(timestamp: String)
    case failed(reason: String)
}

struct ExportJob: Identifiable {
    let id = UUID()
    var format: ExportFormat
    var projectTitle: String
    var status: ExportJobStatus
}

