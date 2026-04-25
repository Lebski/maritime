import AppKit
import AVFoundation
import SwiftUI

struct LoadingVideoView: NSViewRepresentable {
    let onFinished: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onFinished: onFinished) }

    func makeNSView(context: Context) -> NSView {
        let view = PlayerContainerView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor

        guard let url = Bundle.main.url(forResource: "loading", withExtension: "mp4") else {
            return view
        }

        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .pause

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.playerLayer = layer
        view.layer?.addSublayer(layer)

        context.coordinator.player = player
        context.coordinator.observe(item: player.currentItem)

        player.play()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.invalidate()
    }

    final class Coordinator {
        var player: AVPlayer?
        private let onFinished: () -> Void
        private var endObserver: NSObjectProtocol?

        init(onFinished: @escaping () -> Void) {
            self.onFinished = onFinished
        }

        func observe(item: AVPlayerItem?) {
            guard let item else { return }
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [onFinished] _ in
                onFinished()
            }
        }

        func invalidate() {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
            endObserver = nil
        }
    }
}

private final class PlayerContainerView: NSView {
    var playerLayer: AVPlayerLayer?

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
}
