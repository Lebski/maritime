import CoreGraphics

// MARK: - Premiere export settings
//
// Surfaced in the Exports UI as a small strip when the Premiere Pro XML
// format is selected. The XML serializer and PNG renderer both read these
// to size the sequence's frame format and the placeholder stills.

enum PremiereFrameRate: Int, CaseIterable, Identifiable {
    case fps24 = 24
    case fps25 = 25
    case fps30 = 30
    case fps60 = 60

    var id: Int { rawValue }
    var label: String { "\(rawValue) fps" }
}

enum PremiereResolution: String, CaseIterable, Identifiable {
    case hd1080
    case uhd4k
    case vertical1080

    var id: String { rawValue }

    var width: Int {
        switch self {
        case .hd1080: return 1920
        case .uhd4k: return 3840
        case .vertical1080: return 1080
        }
    }

    var height: Int {
        switch self {
        case .hd1080: return 1080
        case .uhd4k: return 2160
        case .vertical1080: return 1920
        }
    }

    var size: CGSize { CGSize(width: width, height: height) }

    var label: String {
        switch self {
        case .hd1080: return "1080p (16:9)"
        case .uhd4k: return "4K UHD (16:9)"
        case .vertical1080: return "1080×1920 (9:16)"
        }
    }
}

struct PremiereExportSettings: Equatable {
    var frameRate: PremiereFrameRate = .fps24
    var resolution: PremiereResolution = .hd1080
}
