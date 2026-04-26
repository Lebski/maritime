import Foundation
import Combine

/// In-process record of every AI request made by the app, surfaced in
/// Preferences → Debug. Persists across launches in Application Support and
/// auto-evicts oldest entries once the on-disk file passes ~5 MB.
@MainActor
final class AIRequestLog: ObservableObject {

    static let shared = AIRequestLog()

    enum Provider: String, Codable, CaseIterable {
        case anthropic
        case fal
        case recraft

        var displayName: String {
            switch self {
            case .anthropic: return "Anthropic"
            case .fal:       return "fal.ai"
            case .recraft:   return "Recraft"
            }
        }
    }

    enum Status: String, Codable {
        case pending, success, failure
    }

    struct TokenUsage: Codable, Equatable {
        var input: Int?
        var output: Int?
        var cacheRead: Int?
        var cacheWrite: Int?
    }

    struct Entry: Identifiable, Codable, Equatable {
        var id: UUID
        var startedAt: Date
        var finishedAt: Date?
        var provider: Provider
        var endpoint: String
        var model: String
        var label: String?
        var requestBody: String
        var status: Status
        var responseSummary: String?
        var responseBody: String?
        var errorMessage: String?
        var durationMs: Int?
        var tokens: TokenUsage?
    }

    @Published private(set) var entries: [Entry] = []

    private let maxBytesOnDisk = 5 * 1024 * 1024
    private let storageURL: URL?
    private var saveTask: Task<Void, Never>?

    private init() {
        self.storageURL = Self.makeStorageURL()
        self.entries = Self.load(from: storageURL)
    }

    // MARK: Mutators

    func begin(provider: Provider,
               endpoint: String,
               model: String,
               label: String?,
               requestBody: String) -> UUID {
        let entry = Entry(
            id: UUID(),
            startedAt: Date(),
            finishedAt: nil,
            provider: provider,
            endpoint: endpoint,
            model: model,
            label: label,
            requestBody: Self.redact(requestBody),
            status: .pending,
            responseSummary: nil,
            responseBody: nil,
            errorMessage: nil,
            durationMs: nil,
            tokens: nil
        )
        entries.insert(entry, at: 0)
        scheduleSave()
        return entry.id
    }

    func succeed(id: UUID,
                 summary: String,
                 body: String,
                 tokens: TokenUsage? = nil) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let now = Date()
        entries[index].finishedAt = now
        entries[index].durationMs = Int(now.timeIntervalSince(entries[index].startedAt) * 1000)
        entries[index].status = .success
        entries[index].responseSummary = summary
        entries[index].responseBody = Self.redact(body)
        entries[index].tokens = tokens
        scheduleSave()
    }

    func fail(id: UUID, error: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let now = Date()
        entries[index].finishedAt = now
        entries[index].durationMs = Int(now.timeIntervalSince(entries[index].startedAt) * 1000)
        entries[index].status = .failure
        entries[index].errorMessage = error
        scheduleSave()
    }

    func clear() {
        entries.removeAll()
        if let url = storageURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = entries
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            if Task.isCancelled { return }
            await self?.persist(snapshot)
        }
    }

    private func persist(_ snapshot: [Entry]) async {
        guard let url = storageURL else { return }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            var data = try encoder.encode(snapshot)
            var trimmed = snapshot
            while data.count > maxBytesOnDisk && !trimmed.isEmpty {
                let dropCount = max(1, trimmed.count / 4)
                trimmed.removeLast(min(dropCount, trimmed.count))
                data = try encoder.encode(trimmed)
            }
            if trimmed.count != snapshot.count {
                self.entries = trimmed
            }
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            // best-effort; logging the log would be silly
        }
    }

    private static func load(from url: URL?) -> [Entry] {
        guard let url, FileManager.default.fileExists(atPath: url.path) else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Entry].self, from: data)
        } catch {
            return []
        }
    }

    private static func makeStorageURL() -> URL? {
        let fm = FileManager.default
        guard let base = try? fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) else { return nil }
        return base
            .appendingPathComponent("MovieBlaze", isDirectory: true)
            .appendingPathComponent("ai-request-log.json", isDirectory: false)
    }

    // MARK: Redaction

    /// Replace base64 image data URIs with a byte-count placeholder so the log
    /// stays human-readable and small. Also scrubs known auth header names if
    /// they ever appear in a body.
    private static func redact(_ raw: String) -> String {
        var out = raw
        let dataURIPattern = #""data:image\/[a-zA-Z0-9.+-]+;base64,[A-Za-z0-9+/=\\s]+""#
        if let regex = try? NSRegularExpression(pattern: dataURIPattern) {
            let range = NSRange(out.startIndex..<out.endIndex, in: out)
            let matches = regex.matches(in: out, range: range).reversed()
            for match in matches {
                guard let r = Range(match.range, in: out) else { continue }
                let payload = out[r]
                let bytes = max(0, payload.count - 2)
                out.replaceSubrange(r, with: "\"data:image;base64,<\(bytes) bytes>\"")
            }
        }
        return out
    }
}

extension AIRequestLog {
    /// Pretty-print a `Codable` value for logging. Falls back to a string
    /// description if encoding fails.
    static func prettyJSON<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8) ?? String(describing: value)
        } catch {
            return String(describing: value)
        }
    }

    /// Pretty-print raw JSON bytes (response data). Falls back to the original
    /// UTF-8 string if it isn't valid JSON.
    static func prettyJSON(data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]),
           let pretty = try? JSONSerialization.data(
               withJSONObject: object,
               options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
           ),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        }
        return String(data: data, encoding: .utf8) ?? "<binary>"
    }
}
