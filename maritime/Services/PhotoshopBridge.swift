import Foundation
import AppKit
import Combine
import OSLog

private let bridgeLog = Logger(subsystem: "com.movieblaze", category: "photoshop-bridge")

// MARK: - PhotoshopBridge
//
// Round-trip editor for asset images. Stages a per-asset PNG into our app's
// temp directory, opens it in Photoshop (or the user's default image editor
// when Photoshop is not installed), and watches the file for saves. When
// Photoshop overwrites the file the bytes are read back and pushed into the
// project document, which bumps the asset's version count and triggers an
// autosave that persists the new PNG inside the .mblaze package.

@MainActor
final class PhotoshopBridge: ObservableObject {

    @Published private(set) var editingAssetIDs: Set<UUID> = []

    private weak var project: MovieBlazeProject?
    private var sessions: [UUID: Session] = [:]

    private static let photoshopBundleID = "com.adobe.Photoshop"
    private static let debounceInterval: DispatchTimeInterval = .milliseconds(400)
    private static let placeholderSize = NSSize(width: 1024, height: 1024)

    init(project: MovieBlazeProject) {
        self.project = project
    }

    // MARK: Public API

    func isEditing(_ assetID: UUID) -> Bool { editingAssetIDs.contains(assetID) }

    func tempFileURL(for assetID: UUID) -> URL? { sessions[assetID]?.url }

    func beginEditing(_ asset: Asset) {
        if let existing = sessions[asset.id] {
            // Already staged — bring Photoshop forward on the same file.
            openInPhotoshop(url: existing.url)
            return
        }
        guard let project else { return }

        let url: URL
        do {
            url = try writeTempFile(for: asset, project: project)
        } catch {
            bridgeLog.error("Failed to stage temp file for \(asset.id): \(error.localizedDescription)")
            return
        }

        let session = Session(assetID: asset.id, url: url)
        sessions[asset.id] = session
        editingAssetIDs.insert(asset.id)

        startWatching(session: session)
        openInPhotoshop(url: url)
    }

    func endEditing(_ assetID: UUID) {
        guard let session = sessions[assetID] else { return }
        session.cancel()
        sessions[assetID] = nil
        editingAssetIDs.remove(assetID)
        try? FileManager.default.removeItem(at: session.url)
    }

    // MARK: Staging

    private func writeTempFile(for asset: Asset, project: MovieBlazeProject) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("maritime-edit", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("\(asset.id.uuidString).png")

        let data = project.assetImageData(for: asset.id) ?? Self.transparentPlaceholderData()
        try data.write(to: url, options: Data.WritingOptions.atomic)
        return url
    }

    private static func transparentPlaceholderData() -> Data {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(placeholderSize.width),
            pixelsHigh: Int(placeholderSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 32
        ) else { return Data() }
        return rep.representation(using: .png, properties: [:]) ?? Data()
    }

    // MARK: Launching Photoshop

    private func openInPhotoshop(url: URL) {
        let config = NSWorkspace.OpenConfiguration()
        if let psURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.photoshopBundleID) {
            NSWorkspace.shared.open([url], withApplicationAt: psURL, configuration: config) { _, error in
                guard let error else { return }
                bridgeLog.error("Open in Photoshop failed (\(error.localizedDescription)) — falling back to default app")
                DispatchQueue.main.async { NSWorkspace.shared.open(url) }
            }
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: File watching

    private func startWatching(session: Session) {
        let fd = open(session.url.path, O_EVTONLY)
        guard fd >= 0 else {
            bridgeLog.error("open(O_EVTONLY) failed for \(session.url.path)")
            return
        }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .rename, .delete],
            queue: .main
        )
        session.bind(source: source, fd: fd)

        source.setEventHandler { [weak self, weak session] in
            guard let self, let session else { return }
            let event = source.data
            session.scheduleDebounce(interval: Self.debounceInterval) { [weak self, weak session] in
                guard let self, let session else { return }
                self.handleSavedFile(session: session)
            }
            if event.contains(.delete) || event.contains(.rename) {
                self.rearmWatcher(for: session)
            }
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
    }

    private func rearmWatcher(for session: Session) {
        session.cancelSourceOnly()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(150)) { [weak self, weak session] in
            guard let self,
                  let session,
                  self.sessions[session.assetID] != nil,
                  FileManager.default.fileExists(atPath: session.url.path)
            else { return }
            self.startWatching(session: session)
        }
    }

    private func handleSavedFile(session: Session) {
        guard let project else { return }
        do {
            let data = try Data(contentsOf: session.url)
            project.setAssetImageData(data, for: session.assetID)
            bridgeLog.info("Re-imported asset \(session.assetID) from Photoshop (\(data.count) bytes)")
        } catch {
            bridgeLog.error("Failed to re-read \(session.url.path): \(error.localizedDescription)")
        }
    }
}

// MARK: - Session

@MainActor
private final class Session {
    let assetID: UUID
    let url: URL
    private var source: DispatchSourceFileSystemObject?
    private var fd: Int32 = -1
    private var debounceWorkItem: DispatchWorkItem?

    init(assetID: UUID, url: URL) {
        self.assetID = assetID
        self.url = url
    }

    func bind(source: DispatchSourceFileSystemObject, fd: Int32) {
        self.source = source
        self.fd = fd
    }

    func scheduleDebounce(interval: DispatchTimeInterval, _ block: @escaping () -> Void) {
        debounceWorkItem?.cancel()
        let item = DispatchWorkItem(block: block)
        debounceWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: item)
    }

    /// Cancels just the dispatch source (used when re-arming on atomic save).
    func cancelSourceOnly() {
        source?.cancel()
        source = nil
        fd = -1
    }

    /// Cancels source AND debounce work — used on full session teardown.
    func cancel() {
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        cancelSourceOnly()
    }
}
